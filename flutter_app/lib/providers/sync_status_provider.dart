import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final syncStatusProvider = NotifierProvider<SyncStatusNotifier, String>(() {
  return SyncStatusNotifier();
});

class SyncStatusNotifier extends Notifier<String> {
  static const _key = 'last_sync_time';

  @override
  String build() {
    _load();
    return 'Never';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final lastTime = prefs.getString(_key);
    if (lastTime != null) {
      state = lastTime;
    }
  }

  Future<void> updateSyncTime() async {
    final now = DateTime.now();
    final timeStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, timeStr);
    state = timeStr;
  }
}
