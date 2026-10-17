import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/subscription_repository.dart';
import 'datasources/sqflite_subscription_data_source.dart';
import 'datasources/subscription_local_data_source.dart';
import 'database_service.dart';
import 'repositories/subscription_repository_impl.dart';

final subscriptionLocalDataSourceProvider =
    FutureProvider<SubscriptionLocalDataSource>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return SqfliteSubscriptionDataSource(db: db);
});

final subscriptionRepositoryProvider =
    FutureProvider<SubscriptionRepository>((ref) async {
  final ds = await ref.watch(subscriptionLocalDataSourceProvider.future);
  return SubscriptionRepositoryImpl(dataSource: ds);
});
