import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({
    this.language = 'es',
    this.currency = '€',
    this.notificationTime = const TimeOfDay(hour: 9, minute: 0),
    this.isPremium = false,
    this.calendarEnabled = false,
    this.calendarKind,
    this.calendarId,
    this.calendarAccount,
  });

  final String language;
  final String currency;
  final TimeOfDay notificationTime;
  final bool isPremium;
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
      calendarEnabled: calendarEnabled ?? this.calendarEnabled,
      calendarKind: calendarKind ?? this.calendarKind,
      calendarId: calendarId ?? this.calendarId,
      calendarAccount: calendarAccount ?? this.calendarAccount,
    );
  }
}