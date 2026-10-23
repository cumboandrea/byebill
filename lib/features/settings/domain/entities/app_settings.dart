import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({
    this.language = 'es',
    this.currency = '€',
    this.notificationTime = const TimeOfDay(hour: 9, minute: 0),
    this.isPremium = false,
    this.premiumPlan,
    this.premiumUntilTs = 0,
    this.calendarEnabled = false,
    this.calendarKind,
    this.calendarId,
    this.calendarAccount,
  });

  final String language;
  final String currency;
  final TimeOfDay notificationTime;
  final bool isPremium;

  /// Plan Premium comprado ('premium_mensual', 'premium_anual' o
  /// 'premium_vitalicio'). null si el usuario nunca ha pagado.
  final String? premiumPlan;

  /// Marca de tiempo UNIX (segundos) en la que expira el Premium
  /// (0 si no aplica / vitalicio = año 2100).
  final int premiumUntilTs;

  final bool calendarEnabled;

  /// Tipo genérico de agenda elegido: 'phone' (calendario del teléfono) o
  /// 'google' (Google Calendar). null si el usuario aún no ha elegido.
  final String? calendarKind;

  /// Id real de la agenda elegida en el dispositivo.
  final String? calendarId;

  /// Nombre de la cuenta a la que pertenece la agenda elegida (email o
  /// etiqueta de la cuenta), para mostrarlo en Ajustes.
  final String? calendarAccount;

  AppSettings copyWith({
    String? language,
    String? currency,
    TimeOfDay? notificationTime,
    bool? isPremium,
    String? premiumPlan,
    int? premiumUntilTs,
    bool? calendarEnabled,
    String? calendarKind,
    String? calendarId,
    String? calendarAccount,
  }) {
    return AppSettings(
      language: language ?? this.language,
      currency: currency ?? this.currency,
      notificationTime: notificationTime ?? this.notificationTime,
      isPremium: isPremium ?? this.isPremium,
      premiumPlan: premiumPlan ?? this.premiumPlan,
      premiumUntilTs: premiumUntilTs ?? this.premiumUntilTs,
      calendarEnabled: calendarEnabled ?? this.calendarEnabled,
      calendarKind: calendarKind ?? this.calendarKind,
      calendarId: calendarId ?? this.calendarId,
      calendarAccount: calendarAccount ?? this.calendarAccount,
    );
  }
}