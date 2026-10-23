import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/onboarding_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  static const int _slideCount = 3;
  final PageController _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    await notifier.setOnboardingSeen();
    if (mounted) {
      context.go('/home');
    }
  }

  void _next() {
    if (_current < _slideCount - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final slides = [
      _Slide(
        icon: Icons.subscriptions_outlined,
        title: AppStrings.onboardingTitle,
        subtitle:
            '${AppStrings.onboardingClaim} ${AppStrings.onboardingSubtitle}',
      ),
      _Slide(
        icon: Icons.notifications_active_outlined,
        title: AppStrings.onboardingSlide2Title,
        subtitle: AppStrings.onboardingSlide2Subtitle,
      ),
      _Slide(
        icon: Icons.savings_outlined,
        title: AppStrings.onboardingSlide3Title,
        subtitle: AppStrings.onboardingSlide3Subtitle,
      ),
    ];

    return Scaffold(
      key: const ValueKey('onboarding_page'),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Omitir: cerrar el onboarding en cualquier momento.
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 8),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    AppStrings.onboardingSkip,
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slideCount,
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (context, index) => slides[index],
              ),
            ),
            // Indicadores de progreso (dots).
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  List.generate(_slideCount, (i) => _dot(i == _current)),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _next,
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
                  child: Text(
                    _current < _slideCount - 1
                        ? AppStrings.onboardingNext
                        : AppStrings.onboardingCta,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _dot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: active ? 24 : 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: active
            ? AppColors.primary
            : AppColors.secondary.withValues(alpha: 0.3),
      ),
    );
  }
}

/// Contenido de una diapositiva: marca, icono ilustrativo, título y texto.
class _Slide extends StatelessWidget {
  const _Slide({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/logo.png',
                width: 36,
                height: 36,
              ),
              const SizedBox(width: 10),
              Text(
                AppStrings.appName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(icon, size: 44, color: AppColors.primary),
          ),
          const SizedBox(height: 36),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.secondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}