import '../entities/subscription.dart';

abstract class SubscriptionRepository {
  Future<List<Subscription>> getActiveSubscriptions();
  Future<List<Subscription>> getAll();
  Future<List<Subscription>> getAllSubscriptions();
  Future<Subscription?> getById(String id);
  Future<void> add(Subscription subscription);
  Future<void> update(Subscription subscription);
  Future<void> delete(String id);
  Future<void> deleteAll();
  Future<double> getTotalSaved();
}
