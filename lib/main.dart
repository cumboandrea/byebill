import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'core/background/background_worker.dart';
import 'core/constants/app_strings.dart';
import 'core/navigation/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';

import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/subscriptions/domain/enums/subscription_status.dart';
import 'features/subscriptions/presentation/providers/subscription_list_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Inicializar WorkManager para Xiaomi/Android optimizaciones
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false, // True solo si quieres ver notificaciones de "tarea iniciada" en debug
  );
  
  // Registrar la tarea recurrente cada 15 minutos (mínimo permitido por Android)
  Workmanager().registerPeriodicTask(
    "byebill_periodic_task_1",
    "check_subscriptions_task",
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.not_required,
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresDeviceIdle: false,
      requiresStorageNotLow: false,
    ),
  );

  final NotificationService notificationService = NotificationService();
  await initServices(notificationService);
  runApp(
    ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const ByeBillApp(),
    ),
  );
}

Future<void> initServices(NotificationService notificationService) async {
  await SharedPreferences.getInstance();
  try {
    await notificationService.ensureInitialized();
  } catch (e) {
    // ignore: avoid_print
    print('[NOTIF] ❌ initServices(): ensureInitialized FALLÓ => $e');
  }
}

class ByeBillApp extends ConsumerStatefulWidget {
  const ByeBillApp({super.key});

  @override
  ConsumerState<ByeBillApp> createState() => _ByeBillAppState();
}

class _ByeBillAppState extends ConsumerState<ByeBillApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifService = ref.read(notificationServiceProvider);
      
      // Intentar pedir el permiso de forma nativa primero
      bool hasPermission = await notifService.requestPermissionsIfNeeded(inContext: true);
      
      // Si el sistema lo ha denegado previamente (Android 13+ o usuario lo bloqueó)
      // Mostramos un Popup amable explicando por qué lo necesitamos y abriendo los Ajustes.
      if (!hasPermission && mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Notificaciones necesarias'),
            content: const Text('Para poder avisarte antes de que te cobren una suscripción, necesitamos que nos des permiso para enviarte alertas. Por favor, actívalas en los ajustes de tu teléfono.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Más tarde'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  notifService.openAppNativeSettings();
                },
                child: const Text('Ir a Ajustes', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
      
      // Como mecanismo de seguridad adicional ("Fallback"), reprogramamos las alarmas activas 
      // cada vez que el usuario abre la aplicación para evitar que se pierdan por el ahorro de batería.
      try {
        final subs = await ref.read(subscriptionListProvider.future);
        for (var sub in subs) {
          if (sub.status == SubscriptionStatus.active) {
            await notifService.scheduleAlertsForSubscription(sub);
          }
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final String currentLang = settingsAsync.valueOrNull?.language ?? 'es';
    AppStrings.setLanguage(currentLang);

    final GoRouter router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      routerConfig: router,
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: Locale(currentLang),
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
        Locale('it'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
