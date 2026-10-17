import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static const _dbName = 'byebill.db';
  static const _dbVersion = 4;

  static const tableSubscriptions = 'subscriptions';
  static const tableSubscriptionsIdCol = 'id';
  static const tableSubscriptionsNameCol = 'name';
  static const tableSubscriptionsAmountCol = 'amount';
  static const tableSubscriptionsCurrencyCol = 'currency';
  static const tableSubscriptionsChargeDateCol = 'chargeDate';
  static const tableSubscriptionsTypeCol = 'type';
  static const tableSubscriptionsStatusCol = 'status';
  static const tableSubscriptionsCycleCol = 'cycle';
  static const tableSubscriptionsCreatedAtCol = 'createdAt';
  static const tableSubscriptionsCancelledAtCol = 'cancelledAt';
  static const tableSubscriptionsCancellationUrlCol = 'cancellationUrl';
  static const tableSubscriptionsLogoPathCol = 'logoPath';
  static const tableSubscriptionsStartDateCol = 'startDate';

  Database? _db;

  Future<Database> get database async => _db ??= await _initDb();

  Future<Database> _initDb() async {
    final databasesPath = await getDatabasesPath();
    final dbPath = path.join(databasesPath, _dbName);
    return openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableSubscriptions (
        $tableSubscriptionsIdCol TEXT PRIMARY KEY,
        $tableSubscriptionsNameCol TEXT,
        $tableSubscriptionsAmountCol REAL,
        $tableSubscriptionsCurrencyCol TEXT,
        $tableSubscriptionsChargeDateCol INTEGER,
        $tableSubscriptionsTypeCol TEXT,
        $tableSubscriptionsStatusCol TEXT,
        $tableSubscriptionsCycleCol TEXT,
        $tableSubscriptionsCreatedAtCol INTEGER,
        $tableSubscriptionsCancelledAtCol INTEGER,
        $tableSubscriptionsCancellationUrlCol TEXT,
        $tableSubscriptionsLogoPathCol TEXT,
        $tableSubscriptionsStartDateCol INTEGER
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE $tableSubscriptions ADD COLUMN $tableSubscriptionsCycleCol TEXT DEFAULT "monthly"');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE $tableSubscriptions ADD COLUMN $tableSubscriptionsCancellationUrlCol TEXT');
      await db.execute('ALTER TABLE $tableSubscriptions ADD COLUMN $tableSubscriptionsLogoPathCol TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE $tableSubscriptions ADD COLUMN $tableSubscriptionsStartDateCol INTEGER');
    }
  }
}

final databaseServiceProvider = Provider<DatabaseService>((ref) => DatabaseService());

final databaseProvider = FutureProvider<Database>((ref) async {
  final service = ref.watch(databaseServiceProvider);
  return service.database;
});
