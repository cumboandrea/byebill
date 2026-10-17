import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class MainLayout extends ConsumerWidget {
  const MainLayout({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(settingsProvider); // watch to rebuild on language change

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _goBranch,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home, color: AppColors.primary),
            label: AppStrings.t('Inicio', 'Home', 'Home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history, color: AppColors.primary),
            label: AppStrings.t('Histórico', 'History', 'Storico'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.savings_outlined),
            selectedIcon: const Icon(Icons.savings, color: AppColors.primary),
            label: AppStrings.t('Ahorro', 'Savings', 'Risparmio'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings, color: AppColors.primary),
            label: AppStrings.t('Ajustes', 'Settings', 'Impostazioni'),
          ),
        ],
      ),
    );
  }
}
