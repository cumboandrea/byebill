import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_local_data_source.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl({required this.dataSource});

  final SubscriptionLocalDataSource dataSource;

  @override
  Future<List<Subscription>> getActiveSubscriptions() {
    return dataSource.getActiveSortedByChargeDate();
  }

  @override
  Future<List<Subscription>> getAll() {
    return dataSource.getAll();
  }

  @override
  Future<List<Subscription>> getAllSubscriptions() {
    return dataSource.getAll();
  }

  @override
  Future<Subscription?> getById(String id) {
    return dataSource.getById(id);
  }

  @override
  Future<void> add(Subscription subscription) {
    return dataSource.insert(subscription);
  }

  @override
  Future<void> update(Subscription subscription) {
    return dataSource.update(subscription);
  }

  @override
  Future<void> delete(String id) {
    return dataSource.delete(id);
  }

  @override
  Future<void> deleteAll() {
    return dataSource.deleteAll();
  }

  @override
  Future<double> getTotalSaved() {
    return dataSource.sumCancelledAmount();
  }
}
