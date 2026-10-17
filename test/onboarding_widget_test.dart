import 'package:byebill/core/constants/app_strings.dart';
import 'package:byebill/core/theme/app_theme.dart';
import 'package:byebill/features/subscriptions/presentation/pages/onboarding_page.dart';
import 'package:byebill/features/subscriptions/presentation/providers/onboarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Onboarding renders hero texts and CTA Empezar',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const OnboardingPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('ByeBill'), findsWidgets);
    expect(find.text(AppStrings.onboardingCta), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding_page')), findsOneWidget);
  });

  testWidgets('Pressing Empezar marks onboarding seen via provider',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(onboardingNotifierProvider), false);
    await container
        .read(onboardingNotifierProvider.notifier)
        .setOnboardingSeen();
    expect(container.read(onboardingNotifierProvider), true);
    final SharedPreferences sp = await SharedPreferences.getInstance();
    expect(sp.getBool('has_seen_onboarding'), isTrue);
  });
}
