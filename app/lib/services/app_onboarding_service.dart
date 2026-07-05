import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the user has seen the first-launch feature intro.
class AppOnboardingService {
  AppOnboardingService._();

  static final AppOnboardingService instance = AppOnboardingService._();

  static const _keyIntroDone = 'app_intro_onboarding_done';

  Future<bool> hasCompletedIntro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIntroDone) ?? false;
  }

  Future<void> markIntroCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIntroDone, true);
  }
}
