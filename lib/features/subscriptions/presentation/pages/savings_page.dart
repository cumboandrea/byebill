import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/savings_provider.dart';
import '../../../../core/utils/date_utils.dart' as du;

class SavingsPage extends ConsumerWidget {
  const SavingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savingsAsync = ref.watch(savingsProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final currencySymbol = settingsAsync.valueOrNull?.currency ?? '€';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.savingsTitle,
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
      body: savingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text(AppStrings.generalError)),
        data: (data) {
          if (data.totalSavedAllTime <= 0) {
            return _buildEmptyState();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10).copyWith(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildKpiHeader(data, currencySymbol),
                _buildSpendEvolutionSection(data, currencySymbol),
                const SizedBox(height: 24),
                _buildChartSection(data, currencySymbol),
                const SizedBox(height: 24),
                _buildTopSavingsPodium(data.topSavedServices, currencySymbol),
                const SizedBox(height: 24),
                _buildEquivalenceSection(data.totalSavedAllTime),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.savings_outlined,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.savingsEmptyTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.savingsEmptySubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.secondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiHeader(SavingsData data, String currencySymbol) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.shade700,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.red.shade800,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.payment, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    AppStrings.savingsMonthlySpend,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                du.formatCurrency(data.activeMonthlySpend, currencySymbol),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                title: AppStrings.savingsThisMonth,
                amount: data.totalSavedThisMonth,
                currencySymbol: currencySymbol,
                icon: Icons.calendar_today,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _KpiCard(
                title: AppStrings.savingsThisYear,
                amount: data.totalSavedThisYear,
                currencySymbol: currencySymbol,
                icon: Icons.emoji_events_outlined,
                isHighlight: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpendEvolutionSection(SavingsData data, String currencySymbol) {
    // Calculamos si hay gasto en los últimos 5 meses (sin contar el mes actual)
    final double previousMonthsSpend = data.monthlySpendHistory.take(5).fold(0.0, (a, b) => a + b);
    
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.savingsSpendEvolutionTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          if (previousMonthsSpend == 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.bar_chart, color: Colors.red.shade300, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      AppStrings.savingsSpendEvolutionEmpty,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 180,
              child: _SpendBarChart(history: data.monthlySpendHistory),
            ),
        ],
      ),
    );
  }

  Widget _buildChartSection(SavingsData data, String currencySymbol) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Evolución (6 meses)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${du.formatCurrency(data.totalSavedAllTime, currencySymbol)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 180,
            child: _SavingsLineChart(history: data.monthlySavingsHistory),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSavingsPodium(List<MapEntry<String, double>> topServices, String currencySymbol) {
    if (topServices.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.savingsTopServices,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(8),
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
          child: Column(
            children: List.generate(topServices.length, (index) {
              final service = topServices[index];
              return ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: index == 0 
                        ? const Color(0xFFFFD700).withValues(alpha: 0.2) // Gold
                        : index == 1 
                            ? const Color(0xFFC0C0C0).withValues(alpha: 0.2) // Silver
                            : const Color(0xFFCD7F32).withValues(alpha: 0.2), // Bronze
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: index == 0 ? const Color(0xFFDAA520) : index == 1 ? const Color(0xFFA9A9A9) : const Color(0xFFB87333),
                      ),
                    ),
                  ),
                ),
                title: Text(
                  service.key,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: Text(
                  du.formatCurrency(service.value, currencySymbol),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                    fontSize: 16,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildEquivalenceSection(double totalSaved) {
    IconData icon = Icons.local_cafe;
    String text = AppStrings.savingsEqCoffee;
    Color color = Colors.brown;

    if (totalSaved >= 300) {
      icon = Icons.devices;
      text = AppStrings.savingsEqGadget;
      color = Colors.purple;
    } else if (totalSaved >= 100) {
      icon = Icons.flight_takeoff;
      text = AppStrings.savingsEqFlight;
      color = Colors.blue;
    } else if (totalSaved >= 40) {
      icon = Icons.restaurant;
      text = AppStrings.savingsEqDinner;
      color = Colors.orange;
    } else if (totalSaved >= 15) {
      icon = Icons.theaters;
      text = AppStrings.savingsEqCinema;
      color = Colors.red;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.savingsEquivalenceTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearBinding(
              colors: [
                color.withValues(alpha: 0.8),
                color.withValues(alpha: 0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: Colors.white),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tu ahorro equivale a:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.amount,
    required this.currencySymbol,
    required this.icon,
    this.isHighlight = false,
  });

  final String title;
  final double amount;
  final String currencySymbol;
  final IconData icon;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isHighlight ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isHighlight 
                ? AppColors.primary.withValues(alpha: 0.3) 
                : AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: isHighlight ? Colors.white70 : AppColors.secondary.withValues(alpha: 0.5),
            size: 24,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isHighlight ? Colors.white70 : AppColors.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '+${du.formatCurrency(amount, currencySymbol)}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isHighlight ? Colors.white : AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavingsLineChart extends StatelessWidget {
  const _SavingsLineChart({required this.history});

  final List<double> history; // 6 items, index 5 is current month

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    
    // Accumulate history for the step chart (it should always go up)
    List<double> accumulated = [];
    double currentSum = 0;
    for (var val in history) {
      currentSum += val;
      accumulated.add(currentSum);
    }

    final maxVal = accumulated.isEmpty ? 100.0 : accumulated.last;
    final maxY = maxVal == 0 ? 100.0 : maxVal * 1.2;

    List<FlSpot> spots = [];
    for (int i = 0; i < accumulated.length; i++) {
      spots.add(FlSpot(i.toDouble(), accumulated[i]));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4 == 0 ? 25 : maxY / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.secondary.withValues(alpha: 0.1),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < 0 || value.toInt() > 5) return const SizedBox.shrink();
                
                // Calculate which month name to show
                // value 5 is current month
                final monthIndex = (now.month - 1) - (5 - value.toInt());
                // Handle year wrap around
                final normalizedIndex = monthIndex < 0 ? 12 + monthIndex : monthIndex;
                
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    months[normalizedIndex],
                    style: TextStyle(
                      color: AppColors.secondary.withValues(alpha: 0.6),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 5,
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            isStepLineChart: true, // This creates the "stepped" effect
            color: AppColors.success,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(
              show: true,
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withValues(alpha: 0.3),
                  AppColors.success.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                return LineTooltipItem(
                  '${touchedSpot.y.toStringAsFixed(0)} €',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

class _SpendBarChart extends StatelessWidget {
  const _SpendBarChart({required this.history});
  final List<double> history;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    
    final maxVal = history.isEmpty ? 100.0 : history.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal == 0 ? 100.0 : maxVal * 1.2;

    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4 == 0 ? 25 : maxY / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.secondary.withValues(alpha: 0.1),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < 0 || value.toInt() > 5) return const SizedBox.shrink();
                final monthIndex = (now.month - 1) - (5 - value.toInt());
                final normalizedIndex = monthIndex < 0 ? 12 + monthIndex : monthIndex;
                
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    months[normalizedIndex],
                    style: TextStyle(
                      color: value.toInt() == 5 ? Colors.red.shade700 : AppColors.secondary.withValues(alpha: 0.6),
                      fontWeight: value.toInt() == 5 ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: maxY,
        barGroups: List.generate(6, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: history[i],
                color: i == 5 ? Colors.red.shade400 : Colors.red.shade200,
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toStringAsFixed(0)} €',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Helper class for gradient binding
class LinearBinding extends LinearGradient {
  const LinearBinding({
    required super.colors,
  }) : super(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
}
