import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import 'subscription_list_provider.dart';

final totalSavedProvider = FutureProvider<double>((ref) async {
  ref.watch(subscriptionListProvider);
  final repo = await ref.watch(subscriptionRepositoryProvider.future);
  return repo.getTotalSaved();
});
