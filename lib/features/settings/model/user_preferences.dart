import 'package:flutter/foundation.dart';

/// 性别偏好——影响穿搭推荐风格。
enum GenderPreference {
  male('男款'),
  universal('通用'),
  female('女款');

  const GenderPreference(this.label);
  final String label;
}

/// 穿衣风格——后续可扩展为多选 / 详细风格树。
enum ClothingStyle {
  casual('休闲日常'),
  business('商务正装'),
  sporty('运动'),
  street('街头'),
  vintage('复古');

  const ClothingStyle(this.label);
  final String label;
}

/// 用户设置偏好。
@immutable
class UserPreferences {
  const UserPreferences({
    this.gender = GenderPreference.universal,
    this.style = ClothingStyle.casual,
    this.thermalSensitivity = 0.4,
    this.dailyReminderEnabled = true,
    this.reminderHour = 7,
    this.reminderMinute = 30,
    this.rainAlertEnabled = true,
  });

  final GenderPreference gender;
  final ClothingStyle style;

  /// 怕冷 / 怕热敏感度，0=怕冷，1=怕热。
  final double thermalSensitivity;

  final bool dailyReminderEnabled;

  /// 24h 制提醒时间。
  final int reminderHour;
  final int reminderMinute;

  final bool rainAlertEnabled;

  String get reminderTimeLabel =>
      '${reminderHour.toString().padLeft(2, '0')}:${reminderMinute.toString().padLeft(2, '0')}';

  UserPreferences copyWith({
    GenderPreference? gender,
    ClothingStyle? style,
    double? thermalSensitivity,
    bool? dailyReminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    bool? rainAlertEnabled,
  }) {
    return UserPreferences(
      gender: gender ?? this.gender,
      style: style ?? this.style,
      thermalSensitivity: thermalSensitivity ?? this.thermalSensitivity,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      rainAlertEnabled: rainAlertEnabled ?? this.rainAlertEnabled,
    );
  }
}
