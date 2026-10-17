import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/enums/subscription_status.dart';
import '../../domain/enums/subscription_type.dart';
import '../providers/subscription_list_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;

enum HistoryFilter { all, trials, cancelled }

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  HistoryFilter _currentFilter = HistoryFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subsAsync = ref.watch(subscriptionListProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final currencySymbol = settingsAsync.valueOrNull?.currency ?? '€';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.historyTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: subsAsync.when(
        data: (subs) {
          // Filter out active subscriptions
          final historySubs = subs.where((s) => s.status != SubscriptionStatus.active).toList();
          
          // Apply category filter
          var filteredSubs = historySubs.where((s) {
            if (_currentFilter == HistoryFilter.trials) {
              return s.type == SubscriptionType.freeTrial;
            } else if (_currentFilter == HistoryFilter.cancelled) {
              return s.status == SubscriptionStatus.cancelled;
            }
            return true;
          }).toList();

          // Apply search filter
          if (_searchQuery.trim().isNotEmpty) {
            final query = _searchQuery.trim().toLowerCase();
            filteredSubs = filteredSubs.where((s) => s.name.toLowerCase().contains(query)).toList();
          }

          // Sort by chargeDate descending (most recent first)
          filteredSubs.sort((a, b) => b.chargeDate.compareTo(a.chargeDate));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: AppStrings.historySearchHint,
                    hintStyle: TextStyle(color: AppColors.onSurface.withValues(alpha: 0.5)),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    _buildChip(AppStrings.historyFilterAll, HistoryFilter.all),
                    const SizedBox(width: 8),
                    _buildChip(AppStrings.historyFilterTrials, HistoryFilter.trials),
                    const SizedBox(width: 8),
                    _buildChip(AppStrings.historyFilterCancelled, HistoryFilter.cancelled),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // List
              Expanded(
                child: filteredSubs.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: filteredSubs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _HistoryTile(
                            subscription: filteredSubs[index],
                            currencySymbol: currencySymbol,
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildChip(String label, HistoryFilter filter) {
    final isSelected = _currentFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surface,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 64, color: AppColors.surface),
          const SizedBox(height: 16),
          Text(
            AppStrings.historyEmptyTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.historyEmptySubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.onSurface.withValues(alpha: 0.6),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Subscription subscription;
  final String currencySymbol;

  const _HistoryTile({required this.subscription, required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    final isTrial = subscription.type == SubscriptionType.freeTrial;
    final isExpired = subscription.status == SubscriptionStatus.expired;
    
    final badgeColor = isTrial ? AppColors.warning : AppColors.danger;
    final badgeText = isTrial ? AppStrings.historyFilterTrials : AppStrings.historyFilterCancelled;
    
    // Formatting date
    final dateStr = subscription.cancelledAt != null 
        ? app_date_utils.formatDateShort(subscription.cancelledAt!)
        : app_date_utils.formatDateShort(subscription.chargeDate);

    return GestureDetector(
      onTap: () {
        context.push('/detail/${subscription.id}');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Logo or Initial
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: subscription.logoPath != null && subscription.logoPath!.isNotEmpty
                  ? (subscription.logoPath!.toLowerCase().endsWith('.svg')
                      ? SvgPicture.asset(subscription.logoPath!, fit: BoxFit.cover)
                      : Image.asset(subscription.logoPath!, fit: BoxFit.cover, errorBuilder: (ctx, err, stack) => _buildFallbackIcon()))
                  : _buildFallbackIcon(),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subscription.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badgeText.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: badgeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  app_date_utils.formatCurrency(subscription.amount, currencySymbol),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface.withValues(alpha: 0.4),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Center(
      child: Text(
        subscription.name.substring(0, 1).toUpperCase(),
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
