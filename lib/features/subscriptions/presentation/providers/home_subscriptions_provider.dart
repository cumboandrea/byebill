import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/enums/subscription_status.dart';
import 'subscription_list_provider.dart';
import '../../../../core/utils/date_utils.dart' as du;

final homeSubscriptionsProvider = Provider.autoDispose<Map<String, List<Subscription>>>((ref) {
  final subsAsync = ref.watch(subscriptionListProvider);
  final subs = subsAsync.valueOrNull ?? [];

  final expiring = <Subscription>[];
  final active = <Subscription>[];

  for (final s in subs) {
    if (s.status == SubscriptionStatus.cancelled) continue;

    if (s.status == SubscriptionStatus.expired) {
      expiring.add(s);
      continue;
    }

    if (s.status == SubscriptionStatus.active) {
      final days = du.daysUntil(s.chargeDate);
      if (days <= 7) {
        expiring.add(s);
      } else {
        active.add(s);
      }
    }
  }

  // Sort by chargeDate ascending
  expiring.sort((a, b) => a.chargeDate.compareTo(b.chargeDate));
  active.sort((a, b) => a.chargeDate.compareTo(b.chargeDate));

  return {
    'expiring': expiring,
    'active': active,
  };
});
