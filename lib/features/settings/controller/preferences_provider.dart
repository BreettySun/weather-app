import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/user_preferences.dart';

/// 用户偏好状态管理。
///
/// 当前为内存态，应用重启会丢。
/// TODO: 接 [AppPreferences] / shared_preferences 做持久化。
class UserPreferencesController extends StateNotifier<UserPreferences> {
  UserPreferencesController() : super(const UserPreferences());

  void setGender(GenderPreference value) {
    state = state.copyWith(gender: value);
  }

  void setStyle(ClothingStyle value) {
    state = state.copyWith(style: value);
  }

  void setThermalSensitivity(double value) {
    state = state.copyWith(thermalSensitivity: value.clamp(0.0, 1.0));
  }

  void setDailyReminderEnabled(bool value) {
    state = state.copyWith(dailyReminderEnabled: value);
  }

  void setReminderTime(int hour, int minute) {
    state = state.copyWith(reminderHour: hour, reminderMinute: minute);
  }

  void setRainAlertEnabled(bool value) {
    state = state.copyWith(rainAlertEnabled: value);
  }
}

final userPreferencesProvider =
    StateNotifierProvider<UserPreferencesController, UserPreferences>(
      (ref) => UserPreferencesController(),
    );
