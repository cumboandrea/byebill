import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/entities/subscription.dart';
import '../../domain/enums/subscription_type.dart';
import '../../domain/enums/subscription_status.dart';
import '../../domain/enums/billing_cycle.dart';
import '../providers/home_subscriptions_provider.dart';
import '../providers/monthly_summary_provider.dart';
import '../providers/alerts_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final isPremium = settingsAsync.valueOrNull?.isPremium ?? false;

    return Scaffold(
      key: const ValueKey('home_page'),
      backgroundColor: AppColors.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: AppColors.primary,
        onPressed: () {
          final homeSubs = ref.read(homeSubscriptionsProvider);
          final activeSubs = homeSubs['active'] ?? [];
          if (!isPremium && activeSubs.length >= 3) {
            context.push('/premium');
          } else {
            context.push('/add');
          }
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 30,
              height: 30,
            ),
            const SizedBox(width: 10),
            const Text(
              'ByeBill',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showAlertsBottomSheet(context, alerts),
            icon: Stack(
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.onSurface,
                  size: 28,
                ),
                if (alerts.isNotEmpty)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.background, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: SafeArea(
        child: Consumer(
          builder: (context, ref, _) {
            final lists = ref.watch(homeSubscriptionsProvider);
            final expiring = lists['expiring']!;
            final active = lists['active']!;
            final summary = ref.watch(monthlySummaryProvider);
            final settingsAsync = ref.watch(settingsProvider);
            final currencySymbol = settingsAsync.valueOrNull?.currency ?? '€';

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20)
                  .copyWith(top: 8, bottom: 80),
              children: [
                Text(
                  AppStrings.homeGreeting,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => context.go('/savings'),
                  child: _HeroCard(savedAmount: summary['savings'] ?? 0.0, currencySymbol: currencySymbol),
                ),
                const SizedBox(height: 24),
                
                if (expiring.isNotEmpty) ...[
                  Text(
                    AppStrings.homeExpiringSubtitle,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.homeAttentionRequired,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        AppStrings.homeTrialsCount(expiring.length),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...expiring.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ExpiringTile(
                          subscription: s,
                          onTap: () => context.push('/detail/${s.id}'),
                          currencySymbol: currencySymbol,
                        ),
                      )),
                  const SizedBox(height: 24),
                ],

                if (active.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        AppStrings.homeActiveSubs,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${active.length}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._buildActiveSubsList(active, isPremium, context, currencySymbol),
                ],

                if (expiring.isEmpty && active.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: _EmptyState(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildActiveSubsList(List<Subscription> subs, bool isPremium, BuildContext context, String currencySymbol) {
    final displaySubs = isPremium ? subs : subs.take(3).toList();
    final hasHitLimit = !isPremium && subs.length >= 3;

    final List<Widget> widgets = displaySubs.map<Widget>((s) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _ActiveTile(
        subscription: s,
        onTap: () => context.push('/detail/${s.id}'),
        currencySymbol: currencySymbol,
      ),
    )).toList();

    if (hasHitLimit) {
      widgets.add(
        GestureDetector(
          onTap: () => context.push('/premium'),
          child: Container(
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium, color: Colors.amber, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.premiumLimitTitle,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.premiumLimitMsg,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.amber),
              ],
            ),
          ),
        ),
      );
    }

    return widgets;
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.savedAmount, required this.currencySymbol});
  final double savedAmount;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.homeSavedTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  app_date_utils.formatCurrency(savedAmount, currencySymbol),
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Opacity(
            opacity: 0.2,
            child: const Icon(
              Icons.savings_outlined,
              size: 70,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiringTile extends StatelessWidget {
  const _ExpiringTile({required this.subscription, required this.onTap, required this.currencySymbol});
  final Subscription subscription;
  final VoidCallback onTap;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final int days = app_date_utils.daysUntil(subscription.chargeDate);
    final String dateStr = app_date_utils.formatDateShort(subscription.chargeDate);
    final String priceStr = app_date_utils.formatCurrency(subscription.amount, currencySymbol);

    Color badgeColor;
    Color badgeText;
    String badgeLabel;

    if (days < 0 || subscription.status == SubscriptionStatus.expired) {
      badgeColor = AppColors.danger.withValues(alpha: 0.15);
      badgeText = AppColors.danger;
      badgeLabel = AppStrings.tileExpired;
    } else if (days <= 2) {
      badgeColor = AppColors.danger.withValues(alpha: 0.15);
      badgeText = AppColors.danger;
      badgeLabel = AppStrings.tileDaysLeft(days);
    } else {
      badgeColor = AppColors.primary.withValues(alpha: 0.15);
      badgeText = AppColors.primary;
      badgeLabel = AppStrings.tileDays(days);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (subscription.logoPath != null && subscription.logoPath!.isNotEmpty)
              ClipOval(
                child: subscription.logoPath!.toLowerCase().endsWith('.svg')
                    ? SvgPicture.asset(
                        subscription.logoPath!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        placeholderBuilder: (context) => Container(
                          width: 52,
                          height: 52,
                          color: AppColors.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.cloud_outlined, color: AppColors.primary, size: 26),
                        ),
                      )
                    : Image.asset(
                        subscription.logoPath!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 52,
                          height: 52,
                          color: AppColors.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.cloud_outlined, color: AppColors.primary, size: 26),
                        ),
                      ),
              )
            else
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_outlined, color: AppColors.primary, size: 26),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          subscription.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badgeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: badgeText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subscription.type == SubscriptionType.freeTrial
                        ? (subscription.status == SubscriptionStatus.expired
                            ? AppStrings.tileTrialEnded(dateStr, priceStr)
                            : AppStrings.tileTrialEnds(dateStr, priceStr))
                        : AppStrings.tileNextCharge(dateStr, priceStr),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.secondary),
          ],
        ),
      ),
    );
  }
}

void _showAlertsBottomSheet(BuildContext context, List<AppAlert> alerts) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.alertsTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: alerts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.alertsEmpty,
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: alerts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      Color iconColor;
                      Color bgColor;
                      switch (alert.type) {
                        case AlertType.warning:
                          iconColor = AppColors.danger;
                          bgColor = AppColors.danger.withValues(alpha: 0.1);
                          break;
                        case AlertType.info:
                          iconColor = AppColors.primary;
                          bgColor = AppColors.primary.withValues(alpha: 0.1);
                          break;
                        case AlertType.success:
                          iconColor = AppColors.success;
                          bgColor = AppColors.success.withValues(alpha: 0.1);
                          break;
                        case AlertType.promo:
                          iconColor = AppColors.warning;
                          bgColor = AppColors.warning.withValues(alpha: 0.1);
                          break;
                      }

                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          if (alert.targetRoute != null) {
                            context.push(alert.targetRoute!);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(alert.icon, color: iconColor, size: 28),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      alert.title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: iconColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      alert.message,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (alert.targetRoute != null)
                                Icon(Icons.chevron_right, color: iconColor.withValues(alpha: 0.5)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

class _ActiveTile extends StatelessWidget {
  const _ActiveTile({required this.subscription, required this.onTap, required this.currencySymbol});
  final Subscription subscription;
  final VoidCallback onTap;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final String dateStr = app_date_utils.formatDateShort(subscription.chargeDate);
    final String priceStr = app_date_utils.formatCurrency(subscription.amount, currencySymbol);
    
    // Extract first letter for the avatar
    final String initial = subscription.name.isNotEmpty ? subscription.name[0].toUpperCase() : 'S';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (subscription.logoPath != null && subscription.logoPath!.isNotEmpty)
              ClipOval(
                child: subscription.logoPath!.toLowerCase().endsWith('.svg')
                    ? SvgPicture.asset(
                        subscription.logoPath!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        placeholderBuilder: (context) => Container(
                          width: 52,
                          height: 52,
                          color: const Color(0xFFFFEAEA),
                          alignment: Alignment.center,
                          child: Text(initial, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFFD65C5C))),
                        ),
                      )
                    : Image.asset(
                        subscription.logoPath!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 52,
                          height: 52,
                          color: const Color(0xFFFFEAEA),
                          alignment: Alignment.center,
                          child: Text(initial, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFFD65C5C))),
                        ),
                      ),
              )
            else
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEAEA),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFD65C5C),
                  ),
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          subscription.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          subscription.cycle == BillingCycle.yearly 
                              ? AppStrings.cycleAnnual 
                              : AppStrings.cycleMonthly,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.tileNextCharge(dateStr, priceStr),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              priceStr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.secondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('empty_state'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.playlist_add_check,
              size: 56,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Todo bajo control',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'No tienes ninguna suscripción activa.\nAñade una para empezar a ahorrar.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.secondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
