import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingNotifier extends Notifier<bool> {
  static const _key = 'has_seen_onboarding';

  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_key) ?? false;
    if (seen) {
      state = true;
    }
  }

  Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    state = true;
  }
}

final onboardingNotifierProvider = NotifierProvider<OnboardingNotifier, bool>(
  OnboardingNotifier.new,
);
