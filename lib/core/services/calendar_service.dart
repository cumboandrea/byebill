import 'dart:convert';

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../features/subscriptions/domain/entities/subscription.dart';
import '../../features/subscriptions/domain/enums/subscription_status.dart';
import '../constants/app_strings.dart';

/// Una opción de agenda para el selector: un calendario escribible por
/// cuenta (la propia del teléfono o cuentas sincronizadas, incluida Google).
typedef CalendarChoice = ({
  String id,
  String accountName,
  bool isGoogle,
  bool isDefault,
});

/// Gestiona los eventos de "cobro de suscripción" en el calendario del
/// dispositivo (Android e iOS). Solo actúa si el usuario ha activado el aviso
/// en Ajustes (`settings_calendar_enabled`).
///
/// Los recordatorios replican los de las notificaciones:
///   - FREE: día del cobro y 2 días antes.
///   - PREMIUM: día del cobro, 2 días antes y 7 días antes.
/// La hora del recordatorio usa la hora de aviso configurada en Ajustes.
class CalendarService {
  CalendarService();

  final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();

  /// subscriptionsId -> {calendarId, eventId}
  static const String _eventsKey = 'calendar_event_map';
  Map<String, Map<String, String>>? _events;

  Future<void> _ensureTimezone() async {
    tzdata.initializeTimeZones();
    if (tz.local != tz.UTC) {
      return;
    }
    try {
      final TimezoneInfo tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/Madrid'));
    }
  }

  Future<Map<String, Map<String, String>>> _loadEvents() async {
    if (_events != null) {
      return _events!;
    }
    final prefs = await SharedPreferences.getInstance();
    _events = {};
    final raw = prefs.getString(_eventsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _events = decoded.map((key, value) =>
            MapEntry(key, Map<String, String>.from(value as Map)));
      } catch (_) {
        _events = {};
      }
    }
    return _events!;
  }

  Future<void> _saveEvents(Map<String, Map<String, String>> events) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_eventsKey, jsonEncode(events));
  }

  static bool _isCalendarEnabled(SharedPreferences prefs) =>
      prefs.getBool('settings_calendar_enabled') ?? false;

  Future<bool> hasPermissions() async {
    final result = await _plugin.hasPermissions();
    return result.isSuccess && result.data == true;
  }

  Future<bool> requestPermissions() async {
    final result = await _plugin.requestPermissions();
    return result.isSuccess && result.data == true;
  }

  /// Devuelve las agendas disponibles en el dispositivo.
  Future<List<Calendar>> getCalendars() async {
    final result = await _plugin.retrieveCalendars();
    if (!result.isSuccess || result.data == null) {
      return [];
    }
    return result.data!.toList();
  }

  /// Un calendario escribible por cuenta para el selector de Ajustes.
  ///
  /// Agrupa todas las agendas del dispositivo por CUENTA y devuelve una opción
  /// por cada una (priorizando la agenda marcada por defecto de cada cuenta),
  /// para que el usuario elija su cuenta sin listados técnicos largos.
  Future<List<CalendarChoice>> getCalendarChoices() async {
    final calendars = await getCalendars();
    final Map<String, CalendarChoice> byAccount = {};
    for (final calendar in calendars) {
      final String? id = calendar.id;
      if (calendar.isReadOnly == true || id == null || id.isEmpty) {
        continue;
      }
      final bool isGoogle = _isGoogleCalendar(calendar);
      final String account = (calendar.accountName ?? '').trim();
      final String key = isGoogle
          ? 'google:$account'
          : (account.isEmpty ? 'phone' : 'phone:$account');
      final current = byAccount[key];
      if (current == null ||
          (calendar.isDefault == true && !current.isDefault)) {
        byAccount[key] = (
          id: id,
          accountName: account,
          isGoogle: isGoogle,
          isDefault: calendar.isDefault == true,
        );
      }
    }
    final choices = byAccount.values.toList();
    choices.sort((a, b) {
      if (a.isGoogle != b.isGoogle) {
        return a.isGoogle ? 1 : -1;
      }
      return a.accountName.compareTo(b.accountName);
    });
    return choices;
  }

  /// Una agenda pertenece a una cuenta Google si su tipo es `com.google`
  /// (Android) o si el nombre de la cuenta lo delata (gmail/googlemail en iOS,
  /// donde el plugin reporta las cuentas CalDAV de Google como "CalDAV").
  static bool _isGoogleCalendar(Calendar calendar) {
    if (calendar.accountType == 'com.google') {
      return true;
    }
    final String account = (calendar.accountName ?? '').toLowerCase();
    return account.contains('google') ||
        account.endsWith('@gmail.com') ||
        account.endsWith('@googlemail.com');
  }

  /// Sincroniza el evento de calendario de una suscripción: lo crea si está
  /// activa y el aviso está activado, o lo elimina en el resto de casos.
  Future<void> syncSubscription(Subscription s) async {
    final prefs = await SharedPreferences.getInstance();
    if (!_isCalendarEnabled(prefs)) {
      return;
    }
    if (s.status != SubscriptionStatus.active) {
      await removeEventForSubscription(s.id);
      return;
    }
    // Idempotente: se borra el evento previo (si existe) y se recrea, de modo
    // que un cambio de fecha/ciclo no deje eventos duplicados.
    await removeEventForSubscription(s.id);
    await _createEventFor(s, prefs);
  }

  /// Elimina el evento de calendario de una suscripción (si existe).
  Future<void> removeEventForSubscription(String subscriptionId) async {
    final events = await _loadEvents();
    final entry = events.remove(subscriptionId);
    if (entry == null) {
      return;
    }
    try {
      await _plugin.deleteEvent(entry['calendarId'], entry['eventId']);
    } catch (e) {
      // ignore: avoid_print
      print('[CAL] Error borrando evento de $subscriptionId: $e');
    }
    await _saveEvents(events);
  }

  /// Crea los eventos de todas las suscripciones activas (al activar el aviso).
  Future<void> backfillAll(List<Subscription> subs) async {
    for (final s in subs) {
      if (s.status != SubscriptionStatus.active) {
        continue;
      }
      try {
        await syncSubscription(s);
      } catch (e) {
        // ignore: avoid_print
        print('[CAL] backfillAll() fallo en ${s.name}: $e');
      }
    }
  }

  /// Elimina los eventos de las suscripciones activas (al desactivar el aviso).
  Future<void> removeAllFor(List<Subscription> subs) async {
    for (final s in subs) {
      if (s.status != SubscriptionStatus.active) {
        continue;
      }
      try {
        await removeEventForSubscription(s.id);
      } catch (e) {
        // ignore: avoid_print
        print('[CAL] removeAllFor() fallo en ${s.name}: $e');
      }
    }
  }

  /// Elimina TODOS los eventos de calendario registrados por la app (sea cual
  /// sea el estado de la suscripción) y vacía el mapa de seguimiento. Usado al
  /// restablecer la app a su estado inicial.
  Future<void> removeAllTrackedEvents() async {
    final events = await _loadEvents();
    for (final entry in events.values) {
      try {
        await _plugin.deleteEvent(entry['calendarId'], entry['eventId']);
      } catch (e) {
        // ignore: avoid_print
        print('[CAL] Error borrando evento al restablecer: $e');
      }
    }
    _events = {};
    await _saveEvents(const {});
  }

  /// Traslada los eventos de las suscripciones activas a otra agenda.
  Future<void> moveAllTo(
    List<Subscription> subs, {
    required String calendarId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    for (final s in subs) {
      if (s.status != SubscriptionStatus.active) {
        continue;
      }
      try {
        await removeEventForSubscription(s.id);
        await _createEventIn(calendarId, s, prefs);
      } catch (e) {
        // ignore: avoid_print
        print('[CAL] moveAllTo() fallo en ${s.name}: $e');
      }
    }
  }

  Future<void> _createEventFor(
    Subscription s,
    SharedPreferences prefs,
  ) async {
    final String? calendarId = await _resolveCalendarId();
    if (calendarId == null) {
      // ignore: avoid_print
      print('[CAL] Sin agenda disponible, no se crea el evento de ${s.name}');
      return;
    }
    await _createEventIn(calendarId, s, prefs);
  }

  /// Usa la agenda guardada en Ajustes o, si no hay una elegida, la primera
  /// agenda escribible del dispositivo (priorizando la marcada por defecto).
  Future<String?> _resolveCalendarId() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('settings_calendar_id');
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }
    final calendars = await getCalendars();
    Calendar? fallback;
    for (final c in calendars) {
      if (c.isReadOnly == true) {
        continue;
      }
      if (c.isDefault == true) {
        return c.id;
      }
      fallback ??= c;
    }
    return fallback?.id;
  }

  Future<void> _createEventIn(
    String calendarId,
    Subscription s,
    SharedPreferences prefs,
  ) async {
    await _ensureTimezone();
    final DateTime date = s.chargeDate;
    // Para eventos "todo el día", Android exige que DTSTART/DTEND sean a
    // medianoche UTC. Además, DTEND debe ser IGUAL a DTSTART para que Google
    // Calendar pinte UN solo día: la app trata DTEND como día final inclusivo,
    // así que con `start + 1 día` el evento ocupaba el día del cobro y el
    // siguiente (hoy y mañana).
    final tz.TZDateTime startContacts =
        tz.TZDateTime(tz.UTC, date.year, date.month, date.day);
    final tz.TZDateTime endContacts = startContacts;

    final String symbol = prefs.getString('settings_currency') ?? '€';
    final String amountText = symbol == '€'
        ? s.amount.toStringAsFixed(2).replaceAll('.', ',')
        : s.amount.toStringAsFixed(2);

    final Event event = Event(
      calendarId,
      title: AppStrings.t(
        'Cobro de ${s.name}',
        'Charge of ${s.name}',
        'Cobro di ${s.name}',
      ),
      description: '$amountText $symbol · ByeBill',
      start: startContacts,
      end: endContacts,
      allDay: true,
      reminders: _remindersFor(prefs),
    );

    final Result<String>? result = await _plugin.createOrUpdateEvent(event);
    final String? eventId = result?.data;
    final String? errorMessage = (result == null || result.errors.isEmpty)
        ? null
        : result.errors.first.errorMessage;
    if (result == null || !result.isSuccess || eventId == null ||
        eventId.isEmpty) {
      // ignore: avoid_print
      print('[CAL] No se pudo crear el evento de ${s.name}: '
          '${errorMessage ?? 'sin id devuelto'}');
      return;
    }

    final events = await _loadEvents();
    events[s.id] = {'calendarId': calendarId, 'eventId': eventId};
    await _saveEvents(events);
  }

  /// Recordatorios en minutos antes del inicio del evento (medianoche del día
  /// de cobro): FREE -> día (hora de aviso) y 2 días antes; PREMIUM añade 7.
  List<Reminder> _remindersFor(SharedPreferences prefs) {
    final bool isPremium = prefs.getBool('settings_is_premium') ?? false;
    final int hour = prefs.getInt('settings_time_hour') ?? 9;
    final int minute = prefs.getInt('settings_time_minute') ?? 0;
    final int base = hour * 60 + minute;
    final List<int> dayOffsets = [0, 2, if (isPremium) 7];
    return [
      for (final int days in dayOffsets)
        Reminder(minutes: days * 24 * 60 + base),
    ];
  }

  /// Resumen de diagnóstico del estado del calendario (para DEBUG).
  ///
  /// Muestra la configuración guardada y los eventos que ByeBill tiene
  /// registrados (suscripción -> agenda/evento), para verificar si una
  /// suscripción activa tiene o no evento creado.
  Future<String> debugSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final events = await _loadEvents();
    final String kind = prefs.getString('settings_calendar_kind') ?? 'no elegido';
    final String id = prefs.getString('settings_calendar_id') ?? 'ninguna';
    final String account =
        prefs.getString('settings_calendar_account') ?? '';

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('Aviso activado: ${_isCalendarEnabled(prefs)}');
    buffer.writeln('Tipo: $kind');
    buffer.writeln('Agenda: $id${account.isEmpty ? '' : ' ($account)'}');
    buffer.writeln('Eventos registrados: ${events.length}');
    for (final entry in events.entries) {
      buffer.writeln(
        '  ${entry.key} -> calendar ${entry.value['calendarId']}\n'
        '      event ${entry.value['eventId']}',
      );
    }
    return buffer.toString();
  }
}

final calendarServiceProvider =
    Provider<CalendarService>((Ref ref) => CalendarService());