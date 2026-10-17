import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/onboarding_provider.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      key: const ValueKey('onboarding_page'),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Image.asset(
                  'assets/logo.png',
                  width: 160,
                  height: 160,
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: 32,
                      height: 32,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ByeBill',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  AppStrings.onboardingTitle,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  AppStrings.onboardingClaim,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.onboardingSubtitle,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.secondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _dot(true),
                    const SizedBox(width: 8),
                    _dot(false),
                    const SizedBox(width: 8),
                    _dot(false),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.08,
                ),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      final notifier =
                          ref.read(onboardingNotifierProvider.notifier);
                      await notifier.setOnboardingSeen();
                      if (context.mounted) {
                        context.go('/home');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(AppStrings.onboardingCta),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot(bool active) {
    return Container(
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: active
            ? AppColors.primary
            : AppColors.secondary.withValues(alpha: 0.3),
      ),
    );
  }
}
