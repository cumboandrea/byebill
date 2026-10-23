import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/subscriptions/domain/entities/subscription.dart';
import '../../features/subscriptions/presentation/providers/onboarding_provider.dart';
import '../../features/premium/presentation/pages/premium_page.dart';
import '../../features/subscriptions/presentation/pages/add_subscription_page.dart';
import '../../features/subscriptions/presentation/pages/detail_subscription_page.dart';
import '../../features/subscriptions/presentation/pages/home_page.dart';
import '../../features/subscriptions/presentation/pages/onboarding_page.dart';
import '../../features/subscriptions/presentation/pages/main_layout.dart';
import '../../features/subscriptions/presentation/pages/history_page.dart';
import '../../features/subscriptions/presentation/pages/savings_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../presentation/pages/splash_page.dart';

class AppRouter {
  static GoRouter routerConfig(Ref ref) {
    final listenable = ValueNotifier<int>(0);

    ref.listen(onboardingNotifierProvider, (previous, next) {
      listenable.value++;
    });

    return GoRouter(
      initialLocation: '/',
      refreshListenable: listenable,
      redirect: (context, state) {
        final hasSeenOnboarding = ref.read(onboardingNotifierProvider);
        final location = state.matchedLocation;

        // El splash (/') se encarga de decidir la primera pantalla, así que
        // solo se fuerza el onboarding si se accede directo a otra ruta.
        if (!hasSeenOnboarding &&
            location != '/onboarding' &&
            location != '/') {
          return '/onboarding';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingPage(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainLayout(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => const HomePage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/history',
                  builder: (context, state) => const HistoryPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/savings',
                  builder: (context, state) => const SavingsPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/settings',
                  builder: (context, state) => const SettingsPage(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/add',
          builder: (context, state) {
            final Subscription? initial = state.extra is Subscription ? state.extra as Subscription : null;
            return AddSubscriptionPage(initialSubscription: initial);
          },
        ),
        GoRoute(
          path: '/detail/:id',
          builder: (context, state) => DetailSubscriptionPage(
            id: state.pathParameters['id'] ?? '',
          ),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: '/premium',
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const PremiumPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1), // Entra desde abajo
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutExpo)),
                  child: child,
                );
              },
            );
          },
        ),
      ],
    );
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return AppRouter.routerConfig(ref);
});
