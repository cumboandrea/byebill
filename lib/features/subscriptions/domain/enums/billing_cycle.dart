// import 'package:flutter/foundation.dart';

enum BillingCycle {
  monthly('Mensual', 'monthly'),
  yearly('Anual', 'yearly');

  const BillingCycle(this.label, this.rawValue);

  final String label;
  final String rawValue;

  static BillingCycle fromRawValue(String value) {
    return BillingCycle.values.firstWhere(
      (e) => e.rawValue == value,
      orElse: () => BillingCycle.monthly,
    );
  }
}
