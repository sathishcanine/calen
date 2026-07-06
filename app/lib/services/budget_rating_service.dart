import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the user accepted the budget screen rating prompt.
class BudgetRatingService {
  BudgetRatingService._();

  static final BudgetRatingService instance = BudgetRatingService._();

  static const _keyRated = 'budget_rating_prompt_accepted';

  Future<bool> hasAcceptedRating() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRated) ?? false;
  }

  Future<void> markRatingAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRated, true);
  }
}
