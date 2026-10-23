import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/enums/subscription_status.dart';
import '../../domain/enums/subscription_type.dart';
import '../../domain/enums/billing_cycle.dart';
import '../providers/subscription_list_provider.dart';

class SavingsData {
  const SavingsData({
    required this.totalSavedThisMonth,
    required this.totalSavedThisYear,
    required this.totalSavedAllTime,
    required this.totalSpentThisYear,
    required this.topSavedServices,
    required this.savingsByServiceThisMonth,
    required this.savingsByServiceThisYear,
    required this.monthlySavingsHistory,
    required this.monthlySpendHistory,
    required this.activeMonthlySpend,
    required this.spendByServiceThisYear,
  });

  final double totalSavedThisMonth;
  final double totalSavedThisYear;
  final double totalSavedAllTime;
  // Gasto real acumulado este año, calculado a partir de "¿Desde cuándo pagas?".
  final double totalSpentThisYear;
  final List<MapEntry<String, double>> topSavedServices;
  final List<SavingsServiceEntry> savingsByServiceThisMonth;
  final List<SavingsServiceEntry> savingsByServiceThisYear;
  // Desglose del gasto de este año (incluye mensuales y anuales).
  final List<SavingsServiceEntry> spendByServiceThisYear;
  final List<double> monthlySavingsHistory; // Last 6 months (0 = 5 months ago, 5 = current month)
  final List<double> monthlySpendHistory;
  final double activeMonthlySpend;
}

/// Entrada de un desglose (ahorro o gasto) por servicio, con la fecha de
/// cancelación ("dejar de pagar") si la hubo, para el popup de detalle.
class SavingsServiceEntry {
  SavingsServiceEntry({
    required this.name,
    required this.amount,
    this.cancelledAt,
    this.periodAmount,
    this.cycle,
  });

  final String name;
  double amount;
  final DateTime? cancelledAt;
  // Importe de una cuota y cadencia (para mostrar "8,99 € / mes" en el gasto).
  final double? periodAmount;
  final BillingCycle? cycle;
}

final savingsProvider = Provider<AsyncValue<SavingsData>>((ref) {
  final subsAsync = ref.watch(subscriptionListProvider);

  return subsAsync.whenData((subs) {
    final now = DateTime.now();
    
    double savedThisMonth = 0;
    double savedThisYear = 0;
    double savedAllTime = 0;
    double activeSpend = 0;
    double spentThisYear = 0;
    
    // Track savings per service
    final Map<String, double> serviceSavings = {};
    // Desglose por servicio del mes y del año en curso (para el popup al
    // tocar las tarjetas KPI de "Este mes" / "Este año"), con la fecha de
    // cancelación de cada suscripción.
    final Map<String, SavingsServiceEntry> monthServiceSavings = {};
    final Map<String, SavingsServiceEntry> yearServiceSavings = {};
    // Desglose del gasto de este año (mensuales y anuales).
    final Map<String, SavingsServiceEntry> yearSpendEntries = {};
    
    // Track savings for the last 6 months (index 0 to 5)
    // 5 = current month, 4 = last month, etc.
    final List<double> monthlyHistory = List.filled(6, 0.0);
    final List<double> spendHistory = List.filled(6, 0.0);

    // Compute Spend History
    for (int i = 0; i < 6; i++) {
      final targetDate = DateTime(now.year, now.month - (5 - i));
      final startOfTarget = DateTime(targetDate.year, targetDate.month, 1);
      final endOfTarget = DateTime(targetDate.year, targetDate.month + 1, 0, 23, 59, 59);
      
      double spendThisMonth = 0;
      for (final sub in subs) {
        if (sub.type == SubscriptionType.freeTrial) continue; // Free trials don't cost money while active
        
        final created = sub.startDate ?? sub.createdAt;
        final cancelled = sub.cancelledAt;
        
        if (created.isBefore(endOfTarget) || created.isAtSameMomentAs(endOfTarget)) {
          if (cancelled == null || cancelled.isAfter(startOfTarget) || cancelled.isAtSameMomentAs(startOfTarget)) {
            if (sub.cycle == BillingCycle.yearly) {
              spendThisMonth += sub.amount / 12;
            } else {
              spendThisMonth += sub.amount;
            }
          }
        }
      }
      spendHistory[i] = spendThisMonth;
    }

    // Gasto real acumulado este año según "¿Desde cuándo pagas?" (startDate):
    // se simulan los cobros desde la fecha de inicio (una cuota por ciclo) y
    // se suman los que han caído dentro del año en curso y antes de hoy (o de
    // la cancelación). Las anuales cuentan su cuota completa una vez al año.
    for (final sub in subs) {
      if (sub.type == SubscriptionType.freeTrial) continue; // Las pruebas gratuitas no cuestan mientras están activas
      final DateTime start = sub.startDate ?? sub.createdAt;
      final DateTime end = sub.cancelledAt ?? now;
      final int stepMonths = sub.cycle == BillingCycle.yearly ? 12 : 1;

      double subSpent = 0;
      int month = start.month;
      int year = start.year;
      while (year < end.year || (year == end.year && month <= end.month)) {
        // Día de cobro del mes, recortado si el mes no tiene ese día (ej. 31).
        final int lastDay = DateTime(year, month + 1, 0).day;
        final DateTime chargeDate =
            DateTime(year, month, start.day <= lastDay ? start.day : lastDay);
        // El primer cobro aún no ha llegado: los siguientes ciclos tampoco.
        if (chargeDate.isAfter(end)) break;
        if (chargeDate.year == now.year) {
          spentThisYear += sub.amount;
          subSpent += sub.amount;
        }
        final int totalMonths = year * 12 + (month - 1) + stepMonths;
        year = totalMonths ~/ 12;
        month = totalMonths % 12 + 1;
      }
      if (subSpent > 0) {
        yearSpendEntries[sub.id] = SavingsServiceEntry(
          name: sub.name,
          amount: subSpent,
          cancelledAt: sub.cancelledAt,
          periodAmount: sub.amount,
          cycle: sub.cycle,
        );
      }
    }

    for (final sub in subs) {
      if (sub.status == SubscriptionStatus.active) {
        if (sub.cycle == BillingCycle.yearly) {
          activeSpend += sub.amount / 12;
        } else {
          activeSpend += sub.amount;
        }
        continue;
      }

      if (sub.status != SubscriptionStatus.cancelled && 
          !(sub.type == SubscriptionType.freeTrial && sub.status == SubscriptionStatus.expired)) {
        continue;
      }

      // Determine when the saving started
      final cancellationDate = sub.cancelledAt ?? sub.chargeDate;
      
      // Calculate how many months have passed since cancellation
      int monthsSaved = 0;
      if (sub.type == SubscriptionType.freeTrial) {
        // Free trial saved exactly 1 payment (assuming they were going to pay the first month)
        monthsSaved = 1;
      } else {
        // For regular subscriptions, calculate months between cancellation and now
        monthsSaved = ((now.year - cancellationDate.year) * 12 + now.month - cancellationDate.month).toInt();
        if (monthsSaved <= 0) monthsSaved = 1; // At least saved the current billing cycle
      }

      final totalSavedFromSub = sub.amount * monthsSaved;
      savedAllTime += totalSavedFromSub;
      
      // Add to service specific savings
      serviceSavings[sub.name] = (serviceSavings[sub.name] ?? 0) + totalSavedFromSub;

      // Did we save this year?
      final double yearSavedFromSub;
      if (cancellationDate.year == now.year) {
        // Simple approximation: add all savings from this year
        yearSavedFromSub = (sub.amount * ((now.month - cancellationDate.month) + 1).clamp(1, 12)).toDouble();
      } else {
        // Cancelled previous years, so we saved all 12 months this year
        yearSavedFromSub = sub.amount * 12;
      }
      savedThisYear += yearSavedFromSub;
      final SavingsServiceEntry yearEntry = yearServiceSavings.putIfAbsent(
        sub.id,
        () => SavingsServiceEntry(
          name: sub.name,
          amount: 0,
          cancelledAt: sub.cancelledAt,
        ),
      );
      yearEntry.amount += yearSavedFromSub;

      // Did we save this month? (If cancelled before or during this month)
      if (cancellationDate.isBefore(now) || 
         (cancellationDate.year == now.year && cancellationDate.month == now.month)) {
        savedThisMonth += sub.amount;
        monthlyHistory[5] += sub.amount; // Current month
        final SavingsServiceEntry monthEntry = monthServiceSavings.putIfAbsent(
          sub.id,
          () => SavingsServiceEntry(
            name: sub.name,
            amount: 0,
            cancelledAt: sub.cancelledAt,
          ),
        );
        monthEntry.amount += sub.amount;
      }

      // Populate history for the last 6 months
      for (int i = 0; i < 5; i++) {
        final targetMonth = DateTime(now.year, now.month - (5 - i));
        if (cancellationDate.isBefore(targetMonth) || 
           (cancellationDate.year == targetMonth.year && cancellationDate.month == targetMonth.month)) {
          monthlyHistory[i] += sub.amount;
        }
      }
    }

    // Sort top services
    final sortedServices = serviceSavings.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topServices = sortedServices.take(3).toList();

    final monthSorted = monthServiceSavings.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final yearSorted = yearServiceSavings.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final spentSorted = yearSpendEntries.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return SavingsData(
      totalSavedThisMonth: savedThisMonth,
      totalSavedThisYear: savedThisYear,
      totalSavedAllTime: savedAllTime,
      totalSpentThisYear: spentThisYear,
      topSavedServices: topServices,
      savingsByServiceThisMonth: monthSorted,
      savingsByServiceThisYear: yearSorted,
      spendByServiceThisYear: spentSorted,
      monthlySavingsHistory: monthlyHistory,
      monthlySpendHistory: spendHistory,
      activeMonthlySpend: activeSpend,
    );
  });
});
