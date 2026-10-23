import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/billing_service.dart';
import '../../../../core/services/calendar_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../subscriptions/domain/enums/subscription_status.dart';
import '../../../subscriptions/presentation/providers/subscription_list_provider.dart';
import '../../domain/entities/app_settings.dart';

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  static const _keyLang = 'settings_language';
  static const _keyCurrency = 'settings_currency';
  static const _keyTimeHour = 'settings_time_hour';
  static const _keyTimeMinute = 'settings_time_minute';
  static const _keyIsPremium = 'settings_is_premium';
  static const _keyPremiumPlan = 'settings_premium_plan';
  static const _keyPremiumUntil = 'settings_premium_until';
  static const _keyCalendarEnabled = 'settings_calendar_enabled';
  static const _keyCalendarKind = 'settings_calendar_kind';
  static const _keyCalendarId = 'settings_calendar_id';
  static const _keyCalendarAccount = 'settings_calendar_account';

  @override
  Future<AppSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    
    final lang = prefs.getString(_keyLang) ?? 'es';
    final currency = prefs.getString(_keyCurrency) ?? '€';
    final hour = prefs.getInt(_keyTimeHour) ?? 9;
    final minute = prefs.getInt(_keyTimeMinute) ?? 0;
    final isPremium = prefs.getBool(_keyIsPremium) ?? false;

    return AppSettings(
      language: lang,
      currency: currency,
      notificationTime: TimeOfDay(hour: hour, minute: minute),
      isPremium: isPremium,
      premiumPlan: prefs.getString(_keyPremiumPlan),
      premiumUntilTs: prefs.getInt(_keyPremiumUntil) ?? 0,
      calendarEnabled: prefs.getBool(_keyCalendarEnabled) ?? false,
      calendarKind: prefs.getString(_keyCalendarKind),
      calendarId: prefs.getString(_keyCalendarId),
      calendarAccount: prefs.getString(_keyCalendarAccount),
    );
  }

  Future<void> updateLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLang, lang);
    state = AsyncData(state.value!.copyWith(language: lang));
  }

  Future<void> updateCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrency, currency);
    state = AsyncData(state.value!.copyWith(currency: currency));
  }

  Future<void> updateNotificationTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTimeHour, time.hour);
    await prefs.setInt(_keyTimeMinute, time.minute);
    state = AsyncData(state.value!.copyWith(notificationTime: time));

    await _reprogramActiveSubscriptions();
  }

  Future<void> setPremium(bool isPremium) async {
    final prefs = await SharedPreferences.getInstance();
    final bool wasPremium = state.value?.isPremium ?? false;
    await prefs.setBool(_keyIsPremium, isPremium);
    state = AsyncData(state.value!.copyWith(isPremium: isPremium));

    // Al bajar de PREMIUM a FREE se restaura la hora de aviso al valor por
    // defecto (09:00): como el selector queda bloqueado en FREE, un usuario
    // que deja de pagar no debe conservar de por vida la hora personalizada
    // que eligió mientras era Premium. Además se reprograman las alertas para
    // que FREE solo reciba sus 2 avisos (sin el de 7 días) y los eventos de
    // calendario se recrean sin el recordatorio de 7 días.
    if (wasPremium && !isPremium) {
      const TimeOfDay defaultTime = TimeOfDay(hour: 9, minute: 0);
      await prefs.setInt(_keyTimeHour, defaultTime.hour);
      await prefs.setInt(_keyTimeMinute, defaultTime.minute);
      state = AsyncData(
        state.value!.copyWith(notificationTime: defaultTime),
      );
      await _reprogramActiveSubscriptions();
    }
  }

  /// Aplica un plan Premium comprado/restaurado desde el store: guarda el plan
  /// y su fecha de expiración y activa el modo Premium.
  Future<void> grantPremium(String plan, int untilTs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPremiumPlan, plan);
    await prefs.setInt(_keyPremiumUntil, untilTs);
    await setPremium(true);
  }

  /// Comprueba si el Premium ha expirado (suscripción que no se ha renovado)
  /// y, si es así, revierte automáticamente a la versión FREE con la misma
  /// lógica del downgrade (hora 09:00 por defecto + reprogramación de alertas
  /// y eventos de calendario sin el aviso de 7 días).
  Future<void> checkExpirationAndDowngradeIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_keyIsPremium) ?? false)) return;

    final plan = prefs.getString(_keyPremiumPlan);
    final untilTs = prefs.getInt(_keyPremiumUntil) ?? 0;
    if (plan == null || plan == PremiumProductIds.lifetime) return;
    if (untilTs <= 0) return; // sin fecha guardada: no forzar el downgrade
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (untilTs >= nowSec) return;

    await prefs.setInt(_keyPremiumUntil, 0);
    await setPremium(false);
  }

  /// Cancela y reprograma las alertas de las suscripciones activas con los
  /// ajustes actuales (hora y plan), y resincroniza sus eventos de calendario:
  /// las notificaciones ya encoladas en el SO no se actualizan solas y los
  /// recordatorios de calendario usan la misma hora de aviso.
  Future<void> _reprogramActiveSubscriptions() async {
    final ns = ref.read(notificationServiceProvider);
    final cs = ref.read(calendarServiceProvider);
    final subs = ref.read(subscriptionListProvider).valueOrNull ?? const [];
    for (final s in subs) {
      if (s.status != SubscriptionStatus.active) continue;
      try {
        await ns.cancelAlertsForSubscription(s.id);
        await ns.scheduleAlertsForSubscription(s);
      } catch (e) {
        // ignore: avoid_print
        print('Error reprogramando alertas de ${s.name}: $e');
      }
      // Los recordatorios del calendario usan la misma hora de aviso:
      // resincronizar (borrar + recrear) para que recojan la nueva hora.
      try {
        await cs.syncSubscription(s);
      } catch (e) {
        // ignore: avoid_print
        print('Error actualizando evento de calendario de ${s.name}: $e');
      }
    }
  }

  /// Activa/desactiva los avisos en calendario.
  ///
  /// Al activar pide el permiso de calendario y crea los eventos de las
  /// suscripciones activas (retroactividad). Devuelve `false` si el permiso
  /// fue denegado (el estado no cambia en ese caso). Al desactivar, elimina
  /// los eventos creados por la app.
  Future<bool> setCalendarEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final cs = ref.read(calendarServiceProvider);

    if (enabled) {
      final bool granted = await cs.requestPermissions();
      if (!granted) {
        return false;
      }
    }

    await prefs.setBool(_keyCalendarEnabled, enabled);
    state = AsyncData(state.value!.copyWith(calendarEnabled: enabled));

    final subs = ref.read(subscriptionListProvider).valueOrNull ?? const [];
    if (enabled) {
      try {
        await cs.backfillAll(subs);
      } catch (e) {
        // ignore: avoid_print
        print('Error creando eventos de calendario: $e');
      }
    } else {
      try {
        await cs.removeAllFor(subs);
      } catch (e) {
        // ignore: avoid_print
        print('Error borrando eventos de calendario: $e');
      }
    }
    return true;
  }

  /// Guarda la elección del usuario ('phone' o 'google') junto con el id real
  /// de esa agenda y su cuenta, y traslada los eventos existentes a la nueva.
  Future<void> setCalendarKind(
    String kind,
    String? id, {
    String? accountName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCalendarKind, kind);
    if (id != null && id.isNotEmpty) {
      await prefs.setString(_keyCalendarId, id);
    }
    if (accountName != null && accountName.isNotEmpty) {
      await prefs.setString(_keyCalendarAccount, accountName);
    }
    state = AsyncData(state.value!.copyWith(
      calendarKind: kind,
      calendarId: id,
      calendarAccount: accountName,
    ));
    if (id == null || id.isEmpty) {
      return;
    }

    final cs = ref.read(calendarServiceProvider);
    final subs = ref.read(subscriptionListProvider).valueOrNull ?? const [];
    try {
      await cs.moveAllTo(subs, calendarId: id);
    } catch (e) {
      // ignore: avoid_print
      print('Error trasladando eventos de calendario: $e');
    }
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);