import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const _historyKey = 'search_history';
  static const _maxHistoryLength = 15;

  Future<SharedPreferences> _getPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (e) {
      print("!!! SearchHistoryService: Error getting SharedPreferences instance: $e");
      rethrow;
    }
  }

  // Lấy danh sách lịch sử tìm kiếm
  Future<List<String>> getSearchHistory() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getStringList(_historyKey) ?? [];
    } catch (e) {
      print("!!! SearchHistoryService: Error getting search history: $e");
      return [];
    }
  }

  Future<void> addSearchTerm(String term) async {
    final normalizedTerm = term.trim();
    if (normalizedTerm.isEmpty) {
      print("[SearchHistoryService] Ignoring empty search term.");
      return;
    }

    try {
      final prefs = await _getPrefs();
      List<String> history = await getSearchHistory();

      history.removeWhere((item) => item.toLowerCase() == normalizedTerm.toLowerCase());

      history.insert(0, normalizedTerm);

      if (history.length > _maxHistoryLength) {
        history = history.sublist(0, _maxHistoryLength);
      }

      await prefs.setStringList(_historyKey, history);
      print("[SearchHistoryService] Added term '$normalizedTerm'. History size: ${history.length}");

    } catch (e) {
      print("!!! SearchHistoryService: Error adding search term '$normalizedTerm': $e");
    }
  }

  Future<void> clearSearchHistory() async {
     try {
        final prefs = await _getPrefs();
        await prefs.remove(_historyKey);
         print("[SearchHistoryService] Cleared search history.");
     } catch(e) {
         print("!!! SearchHistoryService: Error clearing search history: $e");
     }
  }
}