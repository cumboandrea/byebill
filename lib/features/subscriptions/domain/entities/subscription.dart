import '../enums/subscription_status.dart';
import '../enums/subscription_type.dart';
import '../enums/billing_cycle.dart';

class Subscription {
  const Subscription({
    required this.id,
    required this.name,
    required this.amount,
    required this.chargeDate,
    required this.createdAt,
    this.currency = 'EUR',
    this.type = SubscriptionType.freeTrial,
    this.status = SubscriptionStatus.active,
    this.cycle = BillingCycle.monthly,
    this.cancelledAt,
    this.cancellationUrl,
    this.logoPath,
    this.startDate,
  });

  final String id;
  final String name;
  final double amount;
  final String currency;
  final DateTime chargeDate;
  final SubscriptionType type;
  final SubscriptionStatus status;
  final BillingCycle cycle;
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final String? cancellationUrl;
  final String? logoPath;
  final DateTime? startDate;

  DateTime get chargeDateAtNine => DateTime(
        chargeDate.year,
        chargeDate.month,
        chargeDate.day,
        9,
        0,
      );

  Subscription copyWith({
    String? id,
    String? name,
    double? amount,
    String? currency,
    DateTime? chargeDate,
    SubscriptionType? type,
    SubscriptionStatus? status,
    BillingCycle? cycle,
    DateTime? createdAt,
    DateTime? cancelledAt,
    String? cancellationUrl,
    String? logoPath,
    DateTime? startDate,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      chargeDate: chargeDate ?? this.chargeDate,
      type: type ?? this.type,
      status: status ?? this.status,
      cycle: cycle ?? this.cycle,
      createdAt: createdAt ?? this.createdAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationUrl: cancellationUrl ?? this.cancellationUrl,
      logoPath: logoPath ?? this.logoPath,
      startDate: startDate ?? this.startDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Subscription &&
        other.id == id &&
        other.name == name &&
        other.amount == amount &&
        other.currency == currency &&
        other.chargeDate == chargeDate &&
        other.type == type &&
        other.status == status &&
        other.cycle == cycle &&
        other.createdAt == createdAt &&
        other.cancelledAt == cancelledAt &&
        other.cancellationUrl == cancellationUrl &&
        other.logoPath == logoPath &&
        other.startDate == startDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      amount,
      currency,
      chargeDate,
      type,
      status,
      cycle,
      createdAt,
      cancelledAt,
      cancellationUrl,
      logoPath,
      startDate,
    );
  }
}
