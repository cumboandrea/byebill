import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

import '../../features/subscriptions/domain/entities/subscription.dart';
import '../../features/subscriptions/domain/enums/subscription_status.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';

class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  /// Caché de logos resueltos (ruta -> bitmap) para no re-rasterizar en cada
  /// una de las 3 alertas de una misma suscripción durante la misma sesión.
  final Map<String, ByteArrayAndroidBitmap> _logoCache = {};

  Future<void> ensureInitialized() async {
    if (!_initialized) {
      await init();
      _initialized = true;
    }
  }

  Future<void> init() async {
    // ignore: avoid_print
    print('[NOTIF] init() empezando...');

    try {
      tzdata.initializeTimeZones();
    } catch (e) {
      // ignore: avoid_print
      print('[NOTIF] ERROR inicializando timezones: $e');
    }

    String name = 'UTC';
    try {
      final TimezoneInfo tzInfo = await FlutterTimezone.getLocalTimezone();
      name = tzInfo.identifier;
      // ignore: avoid_print
      print('[NOTIF] Zona horaria detectada: $name');
    } catch (e) {
      // ignore: avoid_print
      print('[NOTIF] ERROR obteniendo zona horaria: $e');
    }

    try {
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      // ignore: avoid_print
      print('[NOTIF] ERROR seteando timezone ($name), usando UTC: $e');
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }

    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@drawable/ic_stat_byebill');

    const DarwinInitializationSettings ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      requestCriticalPermission: false,
    );

    const InitializationSettings settings = InitializationSettings(
      android: android,
      iOS: ios,
    );

    try {
      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final String? payload = response.payload;
          if (payload != null) {
            // ignore: avoid_print
            print('Notification tapped with payload: $payload');
          }
        },
      );
      // ignore: avoid_print
      print('[NOTIF] plugin.initialize() OK');
    } catch (e) {
      // ignore: avoid_print
      print('[NOTIF] ERROR en plugin.initialize(): $e');
      rethrow;
    }

    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: AppConstants.notificationChannelDescription,
      importance: Importance.max,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    // ignore: avoid_print
    print('[NOTIF] Canal creado: ${AppConstants.notificationChannelId}');
  }

  Future<bool> requestPermissionsIfNeeded({bool inContext = false}) async {
    bool granted = true;

    final AndroidFlutterLocalNotificationsPlugin? androidImpl =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final IOSFlutterLocalNotificationsPlugin? iosImpl =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (androidImpl != null) {
      final bool? enabled = await androidImpl.areNotificationsEnabled();
      if (enabled != true) {
        granted = false;
      }
    }

    if (iosImpl != null) {
      try {
        final bool alertGranted =
            await iosImpl.requestPermissions(alert: true) ?? false;
        final bool badgeGranted =
            await iosImpl.requestPermissions(badge: true) ?? false;
        final bool soundGranted =
            await iosImpl.requestPermissions(sound: true) ?? false;
        if (!alertGranted || !badgeGranted || !soundGranted) {
          granted = false;
        }
      } catch (_) {
        granted = false;
      }
    }

    if (granted) {
      return true;
    }

    if (!inContext) {
      return false;
    }

    if (androidImpl != null) {
      final bool? result =
          await androidImpl.requestNotificationsPermission();
      granted = result ?? false;
    }

    if (iosImpl != null) {
      final bool? result = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      granted = result ?? false;
    }

    return granted;
  }

  /// Verifica de forma estricta si tenemos permisos de notificación (usado por Ajustes)
  Future<bool> checkExactPermissionStatus() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Abre los ajustes nativos de la aplicación en el sistema operativo
  Future<void> openAppNativeSettings() async {
    await openAppSettings();
  }

  /// Solicita explícitamente ignorar las optimizaciones de batería y permisos de alarma
  Future<void> requestIgnoreBatteryOptimizations() async {
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (!status.isGranted) {
      await Permission.ignoreBatteryOptimizations.request();
    }
    
    // Android 13+ requiere pedir permiso explícito para alarmas exactas si el sistema lo denegó
    final scheduleStatus = await Permission.scheduleExactAlarm.status;
    if (!scheduleStatus.isGranted) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  static List<int> _alertIdsFor(String subscriptionId) {
    // Limit to 100,000,000 to prevent 32-bit integer overflow when multiplied by 10
    final int baseId = subscriptionId.hashCode.abs() % 100000000;
    return [
      baseId * 10 + 0,
      baseId * 10 + 1,
      baseId * 10 + 2,
    ];
  }

  Future<void> scheduleAlertsForSubscription(Subscription s) async {
    if (s.status != SubscriptionStatus.active) {
      return;
    }

    final List<int> ids = _alertIdsFor(s.id);
    final tz.Location tz0 = tz.local;

    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('settings_time_hour') ?? 9;
    final minute = prefs.getInt('settings_time_minute') ?? 0;
    // El aviso de 7 días solo existe en el plan PREMIUM.
    final bool isPremium = prefs.getBool('settings_is_premium') ?? false;

    final tz.TZDateTime dayOfCharge9am = tz.TZDateTime(
      tz0,
      s.chargeDate.year,
      s.chargeDate.month,
      s.chargeDate.day,
      hour,
      minute,
    );

    final tz.TZDateTime sevenDaysBefore =
        dayOfCharge9am.subtract(const Duration(days: 7));
    final tz.TZDateTime twoDaysBefore =
        dayOfCharge9am.subtract(const Duration(days: 2));

    final tz.TZDateTime now = tz.TZDateTime.now(tz0);

    if (isPremium && sevenDaysBefore.isAfter(now)) {
      await _zonedSchedule(
        ids[0],
        AppStrings.appName,
        '${AppStrings.badgeDays(7)} para el cobro de ${s.name}',
        sevenDaysBefore,
        payload: s.id,
        logoPath: s.logoPath,
      );
    }

    if (twoDaysBefore.isAfter(now)) {
      await _zonedSchedule(
        ids[1],
        AppStrings.appName,
        '${AppStrings.badgeDays(2)} para el cobro de ${s.name}',
        twoDaysBefore,
        payload: s.id,
        logoPath: s.logoPath,
      );
    }

    if (dayOfCharge9am.isAfter(now)) {
      await _zonedSchedule(
        ids[2],
        AppStrings.appName,
        'Hoy es el cobro de ${s.name}',
        dayOfCharge9am,
        payload: s.id,
        logoPath: s.logoPath,
      );
    }
  }

  Future<void> _zonedSchedule(
    int id,
    String title,
    String body,
    tz.TZDateTime scheduledDate, {
    required String payload,
    String? logoPath,
  }) async {
    final NotificationDetails details =
        await _buildDetails(title: title, body: body, logoPath: logoPath);

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      // Sin permiso de alarmas exactas (Android 12+ / MIUI) el sistema lanza
      // una excepción; caer a inexactAllowWhileIdle hace que Android entregue
      // la alerta "cuando quiera" (retrasos típicos de ~1 h). Se registra el
      // motivo para diagnóstico; la concesión del permiso se intenta en el
      // arranque de la app (requestIgnoreBatteryOptimizations).
      // ignore: avoid_print
      print('[NOTIF] ⚠️ exactAllowWhileIdle FALLÓ para id=$id en '
          '$scheduledDate => usando inexact. Error: $e');
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    }
  }

  /// Construye los detalles de la notificación incluyendo el logo del servicio
  /// como icono grande. No se usa BigPicture: el logo se compone sobre una
  /// "ficha" redondeada (ver `_logoOnChip`), de modo que se vea siempre y no
  /// deje un área de imagen en blanco en la notificación expandida.
  Future<NotificationDetails> _buildDetails({
    required String title,
    required String body,
    String? logoPath,
  }) async {
    // Si el servicio no tiene logo propio, se usa el logo de ByeBill sobre la
    // ficha blanca para que la notificación nunca salga sin icono grande.
    final String effectiveLogo =
        (logoPath == null || logoPath.isEmpty) ? 'assets/logo_512.png' : logoPath;
    final AndroidBitmap<Object>? logo =
        await _resolveLogoBitmap(effectiveLogo);

    return NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        channelDescription: AppConstants.notificationChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_stat_byebill',
        color: const ui.Color(0xFF146EF5),
        largeIcon: logo,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Resuelve el logo de la suscripción a un bitmap de Android lista para usar.
  /// Soporta PNG/JPG directamente y SVG rasterizándolo en memoria (el plugin
  /// no puede decodificar SVG por sí mismo). El logo se compone siempre sobre
  /// una ficha redondeada para que sea visible aunque el logo sea blanco o
  /// transparente.
  Future<AndroidBitmap<Object>?> _resolveLogoBitmap(String? logoPath) async {
    if (logoPath == null || logoPath.isEmpty) {
      return null;
    }
    final ByteArrayAndroidBitmap? cached = _logoCache[logoPath];
    if (cached != null) {
      return cached;
    }

    try {
      final String lower = logoPath.toLowerCase();
      final ui.Image? raw;
      if (lower.endsWith('.png') ||
          lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg')) {
        final ByteData data = await rootBundle.load(logoPath);
        raw = await _decodeImage(data);
      } else if (lower.endsWith('.svg')) {
        raw = await _svgToImage(logoPath);
      } else {
        return null;
      }
      if (raw == null) {
        return null;
      }
      try {
        final ByteArrayAndroidBitmap chip = await _logoOnChip(raw);
        _logoCache[logoPath] = chip;
        return chip;
      } finally {
        raw.dispose();
      }
    } catch (e) {
      // ignore: avoid_print
      print('[NOTIF] Logo no disponible ($logoPath): $e');
      return null;
    }
  }

  /// Decodifica bytes de imagen (PNG/JPG) a un [ui.Image].
  Future<ui.Image?> _decodeImage(ByteData data) async {
    try {
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      try {
        final ui.FrameInfo frame = await codec.getNextFrame();
        return frame.image;
      } finally {
        codec.dispose();
      }
    } catch (e) {
      // ignore: avoid_print
      print('[NOTIF] Error decodificando imagen: $e');
      return null;
    }
  }

  /// Rasteriza un SVG de assets a un [ui.Image] de 512x512 (se re-muestrea
  /// luego al componer la ficha, con mejor suavizado).
  ///
  /// Escala el dibujo COMPLETO (100% ancho/alto) al lienzo con ajuste
  /// "contain": centrado y sin recortar, usando el tamaño real del picture.
  /// Sin esta escala, un SVG cuyo tamaño/viewBox supera los 512px se cortaba
  /// (solo se veía la parte superior del logo).
  Future<ui.Image> _svgToImage(String path) async {
    const int size = 512;
    final svg.PictureInfo pic = await svg.vg.loadPicture(
      svg.SvgAssetLoader(path),
      null,
    );
    try {
      final double w = pic.size.width;
      final double h = pic.size.height;
      double scale = 1;
      double dx = 0;
      double dy = 0;
      if (w > 0 &&
          h > 0 &&
          w.isFinite &&
          h.isFinite) {
        scale = size / (w > h ? w : h);
        dx = (size - w * scale) / 2;
        dy = (size - h * scale) / 2;
      }
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder);
      canvas.translate(dx, dy);
      canvas.scale(scale);
      canvas.drawPicture(pic.picture);
      return await recorder.endRecording().toImage(size, size);
    } finally {
      pic.picture.dispose();
    }
  }

  /// Compone el logo sobre una ficha redondeada de 256x256 (fondo blanco y
  /// borde suave) para que se vea en cualquier fondo de notificación.
  Future<ByteArrayAndroidBitmap> _logoOnChip(ui.Image logo) async {
    const int size = 256;
    final double d = size.toDouble();
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);

    final ui.RRect chip = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(0, 0, d, d),
      ui.Radius.circular(d * 0.24),
    );
    canvas.drawRRect(chip, ui.Paint()..color = const ui.Color(0xFFFFFFFF));
    canvas.drawRRect(
      chip,
      ui.Paint()
        ..color = const ui.Color(0xFFD9E1EC)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = d * 0.018,
    );

    final double pad = d * 0.18;
    final double dstMax = d - pad * 2;
    final double srcW = logo.width.toDouble();
    final double srcH = logo.height.toDouble();
    final double aspect = srcW / srcH;
    final ui.Rect dst;
    if (aspect >= 1) {
      final double h = dstMax / aspect;
      dst = ui.Rect.fromLTWH(pad, pad + (dstMax - h) / 2, dstMax, h);
    } else {
      final double w = dstMax * aspect;
      dst = ui.Rect.fromLTWH(pad + (dstMax - w) / 2, pad, w, dstMax);
    }
    canvas.drawImageRect(
      logo,
      ui.Rect.fromLTWH(0, 0, srcW, srcH),
      dst,
      ui.Paint()..isAntiAlias = true,
    );

    final ui.Image out = await recorder.endRecording().toImage(size, size);
    try {
      final ByteData? pngBytes =
          await out.toByteData(format: ui.ImageByteFormat.png);
      if (pngBytes == null) {
        throw StateError('toByteData devolvió null al componer la ficha');
      }
      return ByteArrayAndroidBitmap(pngBytes.buffer.asUint8List(
        pngBytes.offsetInBytes,
        pngBytes.lengthInBytes,
      ));
    } finally {
      out.dispose();
    }
  }

  Future<void> cancelAlertsForSubscription(String subscriptionId) async {
    final List<int> ids = _alertIdsFor(subscriptionId);
    for (final int id in ids) {
      await _plugin.cancel(id);
    }
  }

  /// Cancela TODAS las notificaciones programadas (usado al restablecer la app).
  Future<void> cancelAllAlerts() async {
    await _plugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> pendingRequests() async {
    return _plugin.pendingNotificationRequests();
  }

  /// IDs de las alertas que el sistema debería tener programadas para una
  /// suscripción (usado por el trabajo de fondo para detectar alarmas
  /// perdidas tras reinicios o cierres forzados).
  Set<int> alertIdsFor(String subscriptionId) =>
      _alertIdsFor(subscriptionId).toSet();

  Future<int> countPendingFor(String subscriptionId) async {
    final List<PendingNotificationRequest> list = await pendingRequests();
    final Set<int> expected = _alertIdsFor(subscriptionId).toSet();
    return list
        .where((PendingNotificationRequest r) => expected.contains(r.id))
        .length;
  }
  Future<void> rescheduleAllActiveSubscriptions() async {
    // This method is called from MainActivity or Background Task when BOOT_COMPLETED happens
    // Note: To do this properly from a background isolate in Flutter requires flutter_workmanager
    // or similar, but for now we can expose this method to be called when the app launches
    // after a reboot.
    // The actual implementation would read from SQLite and call scheduleAlertsForSubscription
    print('Rescheduling all active subscriptions...');
  }

  /// Envía una notificación inmediata (con un pequeño retraso de 5 segundos) para depuración.
  Future<void> showTestNotification() async {
    // ignore: avoid_print
    print('[NOTIF] showTestNotification() llamado. Esperando 5 segundos...');

    // Asegurarnos de que el plugin está inicializado antes de mostrar
    try {
      await ensureInitialized();
      // ignore: avoid_print
      print('[NOTIF] ensureInitialized() completado (dentro de showTestNotification)');
    } catch (e) {
      // ignore: avoid_print
      print('[NOTIF] ERROR ensureInitialized dentro de showTestNotification: $e');
    }

    // 5 seconds delay so user can exit app and see the notification pop up
    await Future.delayed(const Duration(seconds: 5));

    // ignore: avoid_print
    print('[NOTIF] Pasados 5 segundos. Llamando a showImmediateNotification...');
    await showImmediateNotification(
      999999,
      '¡Notificación de Prueba!',
      'Si estás leyendo esto, las notificaciones funcionan correctamente.',
      'test_payload',
    );
    // ignore: avoid_print
    print('[NOTIF] showImmediateNotification() devolvió sin lanzar excepción');
  }

  /// Programa una notificación de prueba mediante el scheduler del SO
  /// (zonedSchedule): se entrega aunque MIUI cierre la app, ideal para validar
  /// la entrega en segundo plano en dispositivos Xiaomi.
  Future<void> scheduleTestNotificationSoon({int seconds = 3}) async {
    await ensureInitialized();
    final tz.TZDateTime fireAt =
        tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));
    // ignore: avoid_print
    print('[NOTIF] scheduleTestNotificationSoon(): programando prueba del SO en +$seconds s ($fireAt)');
    await _zonedSchedule(
      999998,
      'ByeBill (Scheduler OS)',
      'Prueba A/B: si ves esto, el scheduler del SO sí dispara notificaciones.',
      fireAt,
      payload: 'test_scheduler_ab',
    );
    // ignore: avoid_print
    print('[NOTIF] scheduleTestNotificationSoon(): zonedSchedule OK, id=999998');
  }

  /// Envía una notificación de forma instantánea sin programarla (ideal para WorkManager)
  Future<void> showImmediateNotification(
    int id,
    String title,
    String body,
    String payload, {
    String? logoPath,
  }) async {
    try {
      await ensureInitialized();
    } catch (e) {
      print('[NOTIF] ERROR ensureInitialized en showImmediateNotification: $e');
      return;
    }

    final NotificationDetails details =
        await _buildDetails(title: title, body: body, logoPath: logoPath);
    // ignore: avoid_print
    print('[NOTIF] Llamando _plugin.show(id=$id)...');
    try {
      await _plugin.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
      // ignore: avoid_print
      print('[NOTIF] _plugin.show() OK. Sin excepción.');
    } catch (e) {
      // ignore: avoid_print
      print('[NOTIF] ⚠️ _plugin.show() LANZÓ EXCEPCIÓN: $e');
      // Para saber si la excepción es de permisos o de otra cosa
      final status = await Permission.notification.status;
      // ignore: avoid_print
      print('[NOTIF] Estado permiso notificación: ${status.name} / granted=${status.isGranted}');
      // NOTA DEBUG: intencionadamente NO se hace rethrow para poder mostrar
      // el error real en pantalla (diálogo del botón de prueba) en lugar de
      // una excepción no capturada y silenciosa.
    }
  }
}

final Provider<NotificationService> notificationServiceProvider =
    Provider<NotificationService>((Ref ref) {
  final NotificationService service = NotificationService();
  return service;
});
