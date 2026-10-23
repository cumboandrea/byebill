import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/billing_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart' as du;
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../subscriptions/presentation/providers/savings_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final savingsAsync = ref.watch(savingsProvider);
    final settings = settingsAsync.valueOrNull;
    final savings = savingsAsync.valueOrNull;
    final currency = settings?.currency ?? '€';

    final isPremium = settings?.isPremium ?? false;
    final plan = settings?.premiumPlan;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          AppStrings.profileTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _PlanStatusCard(isPremium: isPremium, plan: plan, settings: settings),
            const SizedBox(height: 28),
            Text(
              AppStrings.profileCuriousData,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _TopSpendsCard(
              topSpends: savings?.spendByServiceThisYear ?? const [],
              currency: currency,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _KpiCard(
                    label: AppStrings.savingsSpentThisYear,
                    value: du.formatCurrency(savings?.totalSpentThisYear ?? 0, currency),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KpiCard(
                    label: AppStrings.profileSavedThisYear,
                    value: du.formatCurrency(savings?.totalSavedThisYear ?? 0, currency),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _KpiCard(
                    label: AppStrings.savingsMonthlySpend,
                    value: du.formatCurrency(savings?.activeMonthlySpend ?? 0, currency),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KpiCard(
                    label: AppStrings.profileSavedAllTime,
                    value: du.formatCurrency(savings?.totalSavedAllTime ?? 0, currency),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta con el estado del plan Premium (activo con detalles, o CTA para
/// hacerse Premium si se está en el plan gratuito).
class _PlanStatusCard extends StatelessWidget {
  const _PlanStatusCard({required this.isPremium, required this.plan, required this.settings});

  final bool isPremium;
  final String? plan;
  final dynamic settings;

  String? _planName(BuildContext context) {
    switch (plan) {
      case PremiumProductIds.monthly:
        return AppStrings.premiumPlanMonthly;
      case PremiumProductIds.yearly:
        return AppStrings.premiumPlanAnnual;
      case PremiumProductIds.lifetime:
        return AppStrings.premiumPlanLifetime;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // CTA de upgrade si el usuario no tiene Premium activo.
    if (!isPremium) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium_outlined, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.profileFree,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.profileUpgradeSubtitle,
                        style: const TextStyle(fontSize: 13, color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => context.push('/premium'),
                child: Text(
                  AppStrings.profileUpgradeCta,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Tarjeta Premium activa: gradiente de marca con plan y caducidad.
    final String planName = _planName(context) ?? AppStrings.premiumPlanLifetime;
    final bool neverExpires = plan == PremiumProductIds.lifetime;
    final String expiryText = neverExpires
        ? AppStrings.profilePlanNeverExpires
        : AppStrings.profilePlanExpires(du.formatDate(
            DateTime.fromMillisecondsSinceEpoch((settings?.premiumUntilTs ?? 0) * 1000),
          ));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF146EF5), Color(0xFF0F3FA8)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Premium',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.workspace_premium, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            planName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            expiryText,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

/// Top 3 de suscripciones por gasto acumulado este año.
class _TopSpendsCard extends StatelessWidget {
  const _TopSpendsCard({required this.topSpends, required this.currency});

  final List<SavingsServiceEntry> topSpends;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final top3 = topSpends.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏆',
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.profileTopSpends,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 12),
          if (top3.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                AppStrings.profileNoData,
                style: const TextStyle(fontSize: 14, color: AppColors.secondary),
              ),
            )
          else
            for (int i = 0; i < top3.length; i++) ...[
              _TopSpendRow(rank: i + 1, entry: top3[i], currency: currency),
              if (i < top3.length - 1)
                Divider(height: 20, color: Colors.grey.withValues(alpha: 0.2)),
            ],
        ],
      ),
    );
  }
}

class _TopSpendRow extends StatelessWidget {
  const _TopSpendRow({required this.rank, required this.entry, required this.currency});

  final int rank;
  final SavingsServiceEntry entry;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$rank',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            entry.name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.onSurface),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          du.formatCurrency(entry.amount, currency),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onSurface),
        ),
      ],
    );
  }
}

/// Tarjeta KPI: etiqueta secundaria arriba y valor grande en azul debajo.
class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.secondary),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}