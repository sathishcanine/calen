import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which admin status stories the user has viewed (local only).
class StatusStoryService {
  StatusStoryService._();

  static final StatusStoryService instance = StatusStoryService._();

  static const _viewedKey = 'status_story_viewed_ids';

  Future<Set<String>> getViewedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_viewedKey)?.toSet() ?? {};
  }

  Future<void> markViewed(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_viewedKey)?.toSet() ?? {};
    ids.add(id);
    await prefs.setStringList(_viewedKey, ids.toList());
  }
}
