import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/enums/billing_cycle.dart';
import '../../domain/enums/subscription_status.dart';
import 'subscription_list_provider.dart';

final monthlySummaryProvider = Provider.autoDispose<Map<String, double>>((ref) {
  final subsAsync = ref.watch(subscriptionListProvider);
  final subs = subsAsync.valueOrNull ?? [];

  double expenses = 0;
  double savings = 0;

  final now = DateTime.now();

  for (final s in subs) {
    // Solo consideramos de pago para el gasto/ahorro
    if (s.amount <= 0) continue;

    final monthlyCost = s.cycle == BillingCycle.yearly ? s.amount / 12 : s.amount;

    if (s.status == SubscriptionStatus.active) {
      expenses += monthlyCost;
    } else if (s.status == SubscriptionStatus.cancelled && s.cancelledAt != null) {
      final monthsSinceCancel = now.difference(s.cancelledAt!).inDays / 30;
      if (s.cycle == BillingCycle.yearly && monthsSinceCancel <= 12) {
        savings += monthlyCost;
      } else if (s.cycle == BillingCycle.monthly && monthsSinceCancel <= 1) {
        savings += monthlyCost;
      }
    }
  }

  return {
    'expenses': expenses,
    'savings': savings,
  };
});
