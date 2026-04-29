import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/features/settings/controller/preferences_provider.dart';
import 'package:weather_app/features/settings/model/user_preferences.dart';

void main() {
  group('UserPreferencesController', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('first launch falls back to defaults', () async {
      final prefs = await SharedPreferences.getInstance();
      final c = UserPreferencesController(prefs);

      expect(c.state.gender, GenderPreference.universal);
      expect(c.state.style, ClothingStyle.casual);
      expect(c.state.dailyReminderEnabled, true);
    });

    test('setters mutate state and write to disk', () async {
      final prefs = await SharedPreferences.getInstance();
      final c = UserPreferencesController(prefs);

      c.setGender(GenderPreference.female);
      c.setStyle(ClothingStyle.business);
      c.setThermalSensitivity(0.8);
      c.setDailyReminderEnabled(false);
      c.setReminderTime(8, 15);
      c.setRainAlertEnabled(false);

      // 让微任务跑完，确保 fire-and-forget 的 setString 完成。
      await Future<void>.delayed(Duration.zero);

      // 用一个新的 controller 复用同一份 SharedPreferences，模拟下一次启动。
      final c2 = UserPreferencesController(prefs);
      expect(c2.state.gender, GenderPreference.female);
      expect(c2.state.style, ClothingStyle.business);
      expect(c2.state.thermalSensitivity, closeTo(0.8, 1e-9));
      expect(c2.state.dailyReminderEnabled, false);
      expect(c2.state.reminderHour, 8);
      expect(c2.state.reminderMinute, 15);
      expect(c2.state.rainAlertEnabled, false);
    });

    test('corrupt JSON resets to defaults without throwing', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'user_preferences.v1': 'not-valid-json{',
      });
      final prefs = await SharedPreferences.getInstance();

      final c = UserPreferencesController(prefs);
      expect(c.state.gender, GenderPreference.universal);
      // 损坏数据被清掉，避免下次启动重复解析失败。
      expect(prefs.getString('user_preferences.v1'), isNull);
    });

    test('unknown enum values fall back to default field-by-field', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'user_preferences.v1':
            '{"gender":"alien","style":"business","thermalSensitivity":0.7}',
      });
      final prefs = await SharedPreferences.getInstance();

      final c = UserPreferencesController(prefs);
      // gender 不识别 → fallback；style/sensitivity 仍然保留。
      expect(c.state.gender, GenderPreference.universal);
      expect(c.state.style, ClothingStyle.business);
      expect(c.state.thermalSensitivity, closeTo(0.7, 1e-9));
    });
  });
}
