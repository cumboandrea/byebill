import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/subscription.dart';
import '../../domain/enums/billing_cycle.dart';
import '../../domain/enums/subscription_status.dart';
import '../../domain/enums/subscription_type.dart';
import '../../data/providers.dart';
import 'subscription_detail_provider.dart';
import '../../../../core/services/calendar_service.dart';
import '../../../../core/services/notification_service.dart';

class SubscriptionListNotifier extends AsyncNotifier<List<Subscription>> {
  @override
  Future<List<Subscription>> build() async {
    final repo = await ref.watch(subscriptionRepositoryProvider.future);
    final subs = await repo.getAll();
    bool updated = false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final s in subs) {
      if (s.status == SubscriptionStatus.active && s.chargeDate.isBefore(today)) {
        if (s.type == SubscriptionType.subscription) {
          DateTime newDate = s.chargeDate;
          while (newDate.isBefore(today)) {
            if (s.cycle == BillingCycle.monthly) {
              newDate = DateTime(newDate.year, newDate.month + 1, newDate.day);
            } else {
              newDate = DateTime(newDate.year + 1, newDate.month, newDate.day);
            }
          }
          final updatedSub = s.copyWith(chargeDate: newDate);
          await repo.update(updatedSub);
          final ns = ref.read(notificationServiceProvider);
          await ns.cancelAlertsForSubscription(s.id);
          await ns.scheduleAlertsForSubscription(updatedSub);
          await ref.read(calendarServiceProvider).syncSubscription(updatedSub);
          updated = true;
        } else if (s.type == SubscriptionType.freeTrial) {
          final expiredSub = s.copyWith(status: SubscriptionStatus.expired);
          await repo.update(expiredSub);
          await ref.read(calendarServiceProvider).syncSubscription(expiredSub);
          updated = true;
        }
      }
    }

    if (updated) {
      return repo.getAll();
    }
    return subs;
  }

  Future<Subscription> addSubscription({
    required String name,
    required double amount,
    String currency = 'EUR',
    required DateTime chargeDate,
    SubscriptionType type = SubscriptionType.freeTrial,
    BillingCycle cycle = BillingCycle.monthly,
    String? cancellationUrl,
    String? logoPath,
    DateTime? startDate,
  }) async {
    final repo = await ref.read(subscriptionRepositoryProvider.future);
    final notificationService = ref.read(notificationServiceProvider);
    state = const AsyncValue.loading();
    final now = DateTime.now();
    final sub = Subscription(
      id: const Uuid().v4(),
      name: name,
      amount: amount,
      currency: currency,
      chargeDate: chargeDate,
      type: type,
      cycle: cycle,
      createdAt: now,
      cancellationUrl: cancellationUrl,
      logoPath: logoPath,
      startDate: startDate,
    );
    state = await AsyncValue.guard(() async {
      await repo.add(sub);
      try {
        await notificationService.scheduleAlertsForSubscription(sub);
      } catch (_) {}
      try {
        await ref.read(calendarServiceProvider).syncSubscription(sub);
      } catch (_) {}
      return repo.getAll();
    });
    return sub;
  }

  Future<void> markCancelled(String id) async {
    final repo = await ref.read(subscriptionRepositoryProvider.future);
    final ns = ref.read(notificationServiceProvider);
    final cs = ref.read(calendarServiceProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final s = await repo.getById(id);
      if (s == null) return state.valueOrNull ?? [];
      final cancelled = s.copyWith(
        status: SubscriptionStatus.cancelled,
        cancelledAt: DateTime.now(),
      );
      await repo.update(cancelled);
      await ns.cancelAlertsForSubscription(id);
      await cs.syncSubscription(cancelled);
      return repo.getAll();
    });
    ref.invalidate(subscriptionDetailProvider(id));
  }

  Future<void> transformToPaid(String id) async {
    final repo = await ref.read(subscriptionRepositoryProvider.future);
    final ns = ref.read(notificationServiceProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final s = await repo.getById(id);
      if (s == null) return state.valueOrNull ?? [];
      
      // Calculate new charge date starting from the next cycle
      DateTime newDate = s.chargeDate;
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      
      // If the expiration date is in the past, advance it to the next valid billing cycle
      while (newDate.isBefore(todayDate)) {
        if (s.cycle == BillingCycle.monthly) {
          newDate = DateTime(newDate.year, newDate.month + 1, newDate.day);
        } else {
          newDate = DateTime(newDate.year + 1, newDate.month, newDate.day);
        }
      }

      final transformed = s.copyWith(
        type: SubscriptionType.subscription,
        status: SubscriptionStatus.active,
        chargeDate: newDate,
      );
      
      await repo.update(transformed);
      try {
        await ns.cancelAlertsForSubscription(id);
        await ns.scheduleAlertsForSubscription(transformed);
      } catch (e) {
        print('Error updating alerts for transformed subscription: $e');
      }
      try {
        await ref.read(calendarServiceProvider).syncSubscription(transformed);
      } catch (_) {}
      return repo.getAll();
    });
    ref.invalidate(subscriptionDetailProvider(id));
  }

  Future<void> updateSubscription(Subscription edited) async {
    final repo = await ref.read(subscriptionRepositoryProvider.future);
    final ns = ref.read(notificationServiceProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.update(edited);
      await ns.cancelAlertsForSubscription(edited.id);
      if (edited.status == SubscriptionStatus.active) {
        await ns.scheduleAlertsForSubscription(edited);
      }
      try {
        await ref.read(calendarServiceProvider).syncSubscription(edited);
      } catch (_) {}
      return repo.getAll();
    });
    // La pantalla de detalle cachea la suscripción; invalidarla para que
    // re-lea de la BD y muestre los cambios (nombre, importe, fecha…).
    ref.invalidate(subscriptionDetailProvider(edited.id));
  }

  Future<void> deleteSubscription(String id) async {
    final repo = await ref.read(subscriptionRepositoryProvider.future);
    final ns = ref.read(notificationServiceProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // Intentamos cancelar las notificaciones, pero si falla no bloqueamos el borrado
      try {
        await ns.cancelAlertsForSubscription(id);
      } catch (e) {
        print('Error cancelling alerts: $e');
      }
      try {
        await ref.read(calendarServiceProvider).removeEventForSubscription(id);
      } catch (e) {
        print('Error removing calendar event: $e');
      }
      
      await repo.delete(id);
      return repo.getAll();
    });
    ref.invalidate(subscriptionDetailProvider(id));
  }

  /// Restablece la app a su estado inicial: borra todas las suscripciones de
  /// la BD, cancela todas las notificaciones programadas y elimina todos los
  /// eventos de calendario creados por la app. Las preferencias (idioma,
  /// moneda, hora de aviso, calendario elegido y plan) se conservan.
  Future<void> resetAllData() async {
    final repo = await ref.read(subscriptionRepositoryProvider.future);
    final ns = ref.read(notificationServiceProvider);
    final cs = ref.read(calendarServiceProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        await ns.cancelAllAlerts();
      } catch (e) {
        print('Error cancelando notificaciones: $e');
      }
      try {
        await cs.removeAllTrackedEvents();
      } catch (e) {
        print('Error eliminando eventos de calendario: $e');
      }
      await repo.deleteAll();
      return repo.getAll();
    });
  }
}

final subscriptionListProvider =
    AsyncNotifierProvider<SubscriptionListNotifier, List<Subscription>>(
  SubscriptionListNotifier.new,
);
