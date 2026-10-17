import '../../domain/entities/subscription.dart';

abstract class SubscriptionLocalDataSource {
  Future<List<Subscription>> getActiveSortedByChargeDate();
  Future<List<Subscription>> getAll();
  Future<Subscription?> getById(String id);
  Future<void> insert(Subscription s);
  Future<void> update(Subscription s);
  Future<void> delete(String id);
  Future<void> deleteAll();
  Future<double> sumCancelledAmount();
}
