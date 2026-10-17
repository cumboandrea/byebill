import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/subscription.dart';
import '../../data/providers.dart';

class SubscriptionDetailNotifier
    extends FamilyAsyncNotifier<Subscription?, String> {
  @override
  Future<Subscription?> build(String arg) async {
    final id = arg;
    final repo = await ref.watch(subscriptionRepositoryProvider.future);
    return repo.getById(id);
  }
}

final subscriptionDetailProvider = AsyncNotifierProviderFamily<
    SubscriptionDetailNotifier, Subscription?, String>(
  SubscriptionDetailNotifier.new,
);
