import 'package:sqflite/sqflite.dart';

import '../../domain/entities/subscription.dart';
import '../../domain/enums/billing_cycle.dart';
import '../../domain/enums/subscription_status.dart';
import '../../domain/enums/subscription_type.dart';
import 'subscription_local_data_source.dart';
import '../database_service.dart';

class SqfliteSubscriptionDataSource implements SubscriptionLocalDataSource {
  SqfliteSubscriptionDataSource({required this.db});

  final Database db;

  Map<String, Object?> _toMap(Subscription s) {
    return {
      DatabaseService.tableSubscriptionsIdCol: s.id,
      DatabaseService.tableSubscriptionsNameCol: s.name,
      DatabaseService.tableSubscriptionsAmountCol: s.amount,
      DatabaseService.tableSubscriptionsCurrencyCol: s.currency,
      DatabaseService.tableSubscriptionsChargeDateCol:
          s.chargeDate.millisecondsSinceEpoch,
      DatabaseService.tableSubscriptionsTypeCol: s.type.rawValue,
      DatabaseService.tableSubscriptionsStatusCol: s.status.rawValue,
      DatabaseService.tableSubscriptionsCycleCol: s.cycle.rawValue,
      DatabaseService.tableSubscriptionsCreatedAtCol:
          s.createdAt.millisecondsSinceEpoch,
      DatabaseService.tableSubscriptionsCancelledAtCol:
          s.cancelledAt?.millisecondsSinceEpoch,
      DatabaseService.tableSubscriptionsCancellationUrlCol: s.cancellationUrl,
      DatabaseService.tableSubscriptionsLogoPathCol: s.logoPath,
      DatabaseService.tableSubscriptionsStartDateCol:
          s.startDate?.millisecondsSinceEpoch,
      DatabaseService.tableSubscriptionsCategoryCol: s.category,
      DatabaseService.tableSubscriptionsDescriptionCol: s.description,
    };
  }

  Subscription _fromMap(Map<String, Object?> m) {
    final cancelledAtMs =
        m[DatabaseService.tableSubscriptionsCancelledAtCol] as int?;
    final startDateMs =
        m[DatabaseService.tableSubscriptionsStartDateCol] as int?;
    return Subscription(
      id: m[DatabaseService.tableSubscriptionsIdCol] as String,
      name: m[DatabaseService.tableSubscriptionsNameCol] as String,
      amount: m[DatabaseService.tableSubscriptionsAmountCol] as double,
      currency: m[DatabaseService.tableSubscriptionsCurrencyCol] as String,
      chargeDate: DateTime.fromMillisecondsSinceEpoch(
        m[DatabaseService.tableSubscriptionsChargeDateCol] as int,
      ),
      type: SubscriptionType.fromRawValue(
        m[DatabaseService.tableSubscriptionsTypeCol] as String,
      ),
      status: SubscriptionStatus.fromRawValue(
        m[DatabaseService.tableSubscriptionsStatusCol] as String,
      ),
      cycle: BillingCycle.fromRawValue(
        m[DatabaseService.tableSubscriptionsCycleCol] as String? ?? 'monthly',
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        m[DatabaseService.tableSubscriptionsCreatedAtCol] as int,
      ),
      cancelledAt: cancelledAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(cancelledAtMs)
          : null,
      cancellationUrl: m[DatabaseService.tableSubscriptionsCancellationUrlCol] as String?,
      logoPath: m[DatabaseService.tableSubscriptionsLogoPathCol] as String?,
      startDate: startDateMs != null
          ? DateTime.fromMillisecondsSinceEpoch(startDateMs)
          : null,
      category:
          m[DatabaseService.tableSubscriptionsCategoryCol] as String?,
      description:
          m[DatabaseService.tableSubscriptionsDescriptionCol] as String?,
    );
  }

  @override
  Future<List<Subscription>> getActiveSortedByChargeDate() async {
    final rows = await db.query(
      DatabaseService.tableSubscriptions,
      where: '${DatabaseService.tableSubscriptionsStatusCol} IN (?, ?)',
      whereArgs: [SubscriptionStatus.active.rawValue, SubscriptionStatus.expired.rawValue],
      orderBy: '${DatabaseService.tableSubscriptionsChargeDateCol} ASC',
    );
    return rows.map(_fromMap).toList();
  }

  @override
  Future<List<Subscription>> getAll() async {
    final rows = await db.query(DatabaseService.tableSubscriptions);
    return rows.map(_fromMap).toList();
  }

  @override
  Future<Subscription?> getById(String id) async {
    final rows = await db.query(
      DatabaseService.tableSubscriptions,
      where: '${DatabaseService.tableSubscriptionsIdCol} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromMap(rows.first);
  }

  @override
  Future<void> insert(Subscription s) async {
    await db.insert(
      DatabaseService.tableSubscriptions,
      _toMap(s),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> update(Subscription s) async {
    await db.update(
      DatabaseService.tableSubscriptions,
      _toMap(s),
      where: '${DatabaseService.tableSubscriptionsIdCol} = ?',
      whereArgs: [s.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    await db.delete(
      DatabaseService.tableSubscriptions,
      where: '${DatabaseService.tableSubscriptionsIdCol} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteAll() async {
    await db.delete(DatabaseService.tableSubscriptions);
  }

  @override
  Future<double> sumCancelledAmount() async {
    final result = await db.rawQuery(
      'SELECT SUM(${DatabaseService.tableSubscriptionsAmountCol}) AS total '
      'FROM ${DatabaseService.tableSubscriptions} '
      'WHERE ${DatabaseService.tableSubscriptionsStatusCol} = ?',
      [SubscriptionStatus.cancelled.rawValue],
    );
    final total = result.first['total'];
    if (total == null) return 0.0;
    if (total is int) return total.toDouble();
    return total as double;
  }
}
