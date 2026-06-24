import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheManager {
  static const String _prefix = 'cache_';
  static const String _timestampPrefix = 'cache_ts_';

  static String _key(String key) => '$_prefix$key';
  static String _tsKey(String key) => '$_timestampPrefix$key';

  /// Save JSON-serializable data to cache
  static Future<void> cacheData(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(key), json.encode(data));
    await prefs.setInt(_tsKey(key), DateTime.now().millisecondsSinceEpoch);
  }

  /// Get cached data. Returns null if no cache exists.
  static Future<dynamic> getCachedData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key(key));
    if (data == null) return null;
    return json.decode(data);
  }

  /// Clear a specific cache entry
  static Future<void> clearCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(key));
    await prefs.remove(_tsKey(key));
  }

  /// Clear all app cache entries
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keysToRemove = prefs.getKeys().where((k) =>
        k.startsWith(_prefix) || k.startsWith(_timestampPrefix)).toList();
    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
  }
}
