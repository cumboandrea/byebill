import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../../features/subscriptions/presentation/providers/onboarding_provider.dart';

/// Página mostrada al abrir la app mientras se decide la ruta inicial
/// (onboarding si es la primera vez, Home si el usuario ya la ha visto).
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    Future.delayed(const Duration(milliseconds: 2000), _goToNextScreen);
  }

  void _goToNextScreen() {
    if (!mounted) return;
    final hasSeenOnboarding = ref.read(onboardingNotifierProvider);
    context.go(hasSeenOnboarding ? '/home' : '/onboarding');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entrance = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    final scale = Tween<double>(begin: 0.6, end: 1.0).animate(entrance);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _controller,
                child: ScaleTransition(
                  scale: scale,
                  child: Image.asset(
                    'assets/logo.png',
                    width: 160,
                    height: 160,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: _controller,
                child: const Text(
                  'ByeBill',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}