import 'package:shared_preferences/shared_preferences.dart';

class PendingOperationsService {
  static const _pendingDeletesKey = 'pending_deletes';

  Future<List<String>> getPendingDeletes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_pendingDeletesKey) ?? <String>[];
  }

  Future<void> addPendingDelete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_pendingDeletesKey) ?? <String>[];
    if (!list.contains(id)) {
      list.add(id);
      await prefs.setStringList(_pendingDeletesKey, list);
    }
  }

  Future<void> removePendingDelete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_pendingDeletesKey) ?? <String>[];
    if (list.contains(id)) {
      list.remove(id);
      await prefs.setStringList(_pendingDeletesKey, list);
    }
  }

  Future<void> clearPendingDeletes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingDeletesKey);
  }
}
