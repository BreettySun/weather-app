import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 异步获取的 [SharedPreferences] 实例。
///
/// 用法：在 main 中预热后通过 `ProviderScope.overrides` 注入同步值，
/// 或在异步 provider 中 `await ref.watch(sharedPreferencesProvider.future)`。
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

/// 在 [SharedPreferences] 之上的轻量封装，避免散落的 key 字符串。
class AppPreferences {
  AppPreferences(this._prefs);

  final SharedPreferences _prefs;

  // 预留示例 key，按需扩展。
  // static const _kLastCity = 'last_city';

  Future<bool> setString(String key, String value) => _prefs.setString(key, value);
  String? getString(String key) => _prefs.getString(key);

  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);
  bool? getBool(String key) => _prefs.getBool(key);

  Future<bool> remove(String key) => _prefs.remove(key);
  Future<bool> clear() => _prefs.clear();
}

final appPreferencesProvider = FutureProvider<AppPreferences>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return AppPreferences(prefs);
});
