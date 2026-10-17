import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/enums/subscription_status.dart';
import '../../domain/enums/subscription_type.dart';
import '../../domain/enums/billing_cycle.dart';
import '../providers/subscription_list_provider.dart';

class SavingsData {
  const SavingsData({
    required this.totalSavedThisMonth,
    required this.totalSavedThisYear,
    required this.totalSavedAllTime,
    required this.topSavedServices,
    required this.monthlySavingsHistory,
    required this.monthlySpendHistory,
    required this.activeMonthlySpend,
  });

  final double totalSavedThisMonth;
  final double totalSavedThisYear;
  final double totalSavedAllTime;
  final List<MapEntry<String, double>> topSavedServices;
  final List<double> monthlySavingsHistory; // Last 6 months (0 = 5 months ago, 5 = current month)
  final List<double> monthlySpendHistory;
  final double activeMonthlySpend;
}

final savingsProvider = Provider<AsyncValue<SavingsData>>((ref) {
  final subsAsync = ref.watch(subscriptionListProvider);

  return subsAsync.whenData((subs) {
    final now = DateTime.now();
    
    double savedThisMonth = 0;
    double savedThisYear = 0;
    double savedAllTime = 0;
    double activeSpend = 0;
    
    // Track savings per service
    final Map<String, double> serviceSavings = {};
    
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
      if (cancellationDate.year == now.year) {
        // Simple approximation: add all savings from this year
        savedThisYear += sub.amount * ((now.month - cancellationDate.month) + 1).clamp(1, 12);
      } else {
        // Cancelled previous years, so we saved all 12 months this year
        savedThisYear += sub.amount * 12;
      }

      // Did we save this month? (If cancelled before or during this month)
      if (cancellationDate.isBefore(now) || 
         (cancellationDate.year == now.year && cancellationDate.month == now.month)) {
        savedThisMonth += sub.amount;
        monthlyHistory[5] += sub.amount; // Current month
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

    return SavingsData(
      totalSavedThisMonth: savedThisMonth,
      totalSavedThisYear: savedThisYear,
      totalSavedAllTime: savedAllTime,
      topSavedServices: topServices,
      monthlySavingsHistory: monthlyHistory,
      monthlySpendHistory: spendHistory,
      activeMonthlySpend: activeSpend,
    );
  });
});
