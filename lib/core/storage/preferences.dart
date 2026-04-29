import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 同步注入的 [SharedPreferences] 实例。
///
/// 必须在 `main()` 中预热并通过 `ProviderScope.overrides` 注入，
/// 否则首次读取会抛 [UnimplementedError]。这样所有依赖偏好的
/// Provider 都能保持同步、构造期即可读到旧值。
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main() — '
    'await SharedPreferences.getInstance() before runApp.',
  );
});
