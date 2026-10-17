import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import '../services/notification_service.dart';
import '../../features/subscriptions/data/database_service.dart';
import '../../features/subscriptions/data/datasources/sqflite_subscription_data_source.dart';
import '../../features/subscriptions/data/repositories/subscription_repository_impl.dart';
import '../../features/subscriptions/domain/entities/subscription.dart';
import '../../features/subscriptions/domain/enums/subscription_status.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();

      // 1. Inicializar Notificaciones
      final ns = NotificationService();
      await ns.init();

      // 2. Inicializar Base de datos y Repositorio
      final dbService = DatabaseService();
      final db = await dbService.database;
      final dataSource = SqfliteSubscriptionDataSource(db: db);
      final repo = SubscriptionRepositoryImpl(dataSource: dataSource);
      final subs = await repo.getAll();

      // 3. Watchdog de alarmas: el programador exacto del sistema (zonedSchedule)
      //    es el ÚNICO que muestra notificaciones. Este trabajo de fondo solo
      //    detecta suscripciones activas cuya alarma no está programada en el SO
      //    (tras un reinicio o un cierre forzado que borró las alarmas) y la
      //    reprograma. NO dispara notificaciones para evitar duplicados con las
      //    que el sistema entrega por sí mismo.
      final pending = await ns.pendingRequests();
      for (final s in subs) {
        if (s.status != SubscriptionStatus.active) continue;
        final Set<int> expected = ns.alertIdsFor(s.id);
        final bool hasAny = pending.any((r) => expected.contains(r.id));
        if (!hasAny) {
          try {
            await ns.scheduleAlertsForSubscription(s);
            // ignore: avoid_print
            print('[WM] Alarmas de ${s.name} ausentes; reprogramadas.');
          } catch (e) {
            // ignore: avoid_print
            print('[WM] Error reprogramando ${s.name}: $e');
          }
        }
      }

      return Future.value(true);
    } catch (e) {
      // ignore: avoid_print
      print('Error en Workmanager (Background Task): $e');
      return Future.value(false);
    }
  });
}