import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/enums/subscription_status.dart';
import '../../domain/enums/subscription_type.dart';
import 'subscription_list_provider.dart';
import 'savings_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../../core/utils/date_utils.dart' as du;

enum AlertType { warning, info, success, promo }

class AppAlert {
  const AppAlert({
    required this.title,
    required this.message,
    required this.type,
    required this.icon,
    this.targetRoute,
    this.routeExtra,
  });

  final String title;
  final String message;
  final AlertType type;
  final IconData icon;
  final String? targetRoute;
  final Object? routeExtra;
}

final alertsProvider = Provider<List<AppAlert>>((ref) {
  final subsAsync = ref.watch(subscriptionListProvider);
  final savingsAsync = ref.watch(savingsProvider);
  final settingsAsync = ref.watch(settingsProvider);
  
  final isPremium = settingsAsync.valueOrNull?.isPremium ?? false;
  final currency = settingsAsync.valueOrNull?.currency ?? '€';
  
  List<AppAlert> alerts = [];

  // 1. Alertas de suscripciones
  subsAsync.whenData((subs) {
    for (final sub in subs) {
      if (sub.status == SubscriptionStatus.active) {
        final days = du.daysUntil(sub.chargeDate);
        if (days >= 0 && days <= 3) {
          if (sub.type == SubscriptionType.freeTrial) {
            alerts.add(AppAlert(
              title: AppStrings.alertsTrialTitle,
              message: AppStrings.alertsTrialExpiring(sub.name, days),
              type: AlertType.warning,
              icon: Icons.timer_outlined,
              targetRoute: '/detail/${sub.id}',
            ));
          } else {
            alerts.add(AppAlert(
              title: AppStrings.alertsChargeTitle,
              message: AppStrings.alertsChargeSoon(sub.name, days),
              type: AlertType.info,
              icon: Icons.payment,
              targetRoute: '/detail/${sub.id}',
            ));
          }
        }
      }
    }
  });

  // 2. Alertas de ahorro
  savingsAsync.whenData((savings) {
    if (savings.totalSavedThisMonth > 0) {
      alerts.add(AppAlert(
        title: AppStrings.alertsSavingsTitle,
        message: AppStrings.alertsSavings(du.formatCurrency(savings.totalSavedThisMonth, currency)),
        type: AlertType.success,
        icon: Icons.savings_outlined,
        targetRoute: '/savings',
      ));
    }
  });

  // 3. Alertas promocionales (Upsell)
  if (!isPremium) {
    alerts.add(AppAlert(
      title: AppStrings.alertsPremiumTitle,
      message: AppStrings.alertsPremiumUpsell,
      type: AlertType.promo,
      icon: Icons.workspace_premium,
      targetRoute: '/premium',
    ));
  }

  return alerts;
});
