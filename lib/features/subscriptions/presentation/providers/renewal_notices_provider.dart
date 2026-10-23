import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Aviso de que una suscripción se ha renovado automáticamente (rolling por
/// no haber abierto la app el día del cobro). Se muestra en el Centro de
/// Alertas durante unos días y expira solo.
class RenewalNotice {
  const RenewalNotice({
    required this.subscriptionId,
    required this.name,
    required this.logoPath,
    required this.renewedAt,
    required this.createdAt,
  });

  final String subscriptionId;
  final String name;
  final String? logoPath;

  /// Fecha en la que se produjo la renovación (la antigua fecha de cobro).
  final DateTime renewedAt;

  /// Momento en que se detectó la renovación; se usa para expirar el aviso.
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'subscriptionId': subscriptionId,
        'name': name,
        'logoPath': logoPath,
        'renewedAt': renewedAt.millisecondsSinceEpoch,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory RenewalNotice.fromJson(Map<String, dynamic> json) => RenewalNotice(
        subscriptionId: json['subscriptionId'] as String,
        name: json['name'] as String,
        logoPath: json['logoPath'] as String?,
        renewedAt:
            DateTime.fromMillisecondsSinceEpoch(json['renewedAt'] as int),
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      );
}

class RenewalNoticesNotifier extends AsyncNotifier<List<RenewalNotice>> {
  static const _key = 'renewal_notices';

  /// Días que el aviso permanece visible en el Centro de Alertas.
  static const Duration visibility = Duration(days: 5);

  @override
  Future<List<RenewalNotice>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    final now = DateTime.now();
    final notices = (jsonDecode(raw) as List)
        .map((e) => RenewalNotice.fromJson(e as Map<String, dynamic>))
        // Excluimos los avisos caducados (borrado perezoso).
        .where((n) => now.difference(n.createdAt) < visibility)
        .toList();
    return notices;
  }

  /// Registra la renovación automática de una suscripción. Si ya existía un
  /// aviso para la misma suscripción (renovaciones sucesivas), lo reemplaza.
  Future<void> recordRenewal({
    required String subscriptionId,
    required String name,
    String? logoPath,
    required DateTime renewedAt,
  }) async {
    final now = DateTime.now();
    final current = state.valueOrNull ?? await build();

    final updated = [
      RenewalNotice(
        subscriptionId: subscriptionId,
        name: name,
        logoPath: logoPath,
        renewedAt: renewedAt,
        createdAt: now,
      ),
      ...current.where((n) => n.subscriptionId != subscriptionId),
    ];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(updated.map((n) => n.toJson()).toList()),
    );
    state = AsyncData(updated);
  }

  /// Elimina todos los avisos (usado al restablecer los datos de la app).
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    state = const AsyncData([]);
  }
}

final renewalNoticesProvider =
    AsyncNotifierProvider<RenewalNoticesNotifier, List<RenewalNotice>>(
  RenewalNoticesNotifier.new,
);