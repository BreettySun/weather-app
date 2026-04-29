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

  Map<String, Object?> toJson() => <String, Object?>{
    'gender': gender.name,
    'style': style.name,
    'thermalSensitivity': thermalSensitivity,
    'dailyReminderEnabled': dailyReminderEnabled,
    'reminderHour': reminderHour,
    'reminderMinute': reminderMinute,
    'rainAlertEnabled': rainAlertEnabled,
  };

  /// 解析旧数据时缺失/类型错误的字段回落到默认值，避免破坏已存在的安装。
  factory UserPreferences.fromJson(Map<String, Object?> json) {
    const defaults = UserPreferences();
    return UserPreferences(
      gender: _parseEnum(
        json['gender'],
        GenderPreference.values,
        defaults.gender,
      ),
      style: _parseEnum(json['style'], ClothingStyle.values, defaults.style),
      thermalSensitivity: switch (json['thermalSensitivity']) {
        final num v => v.toDouble().clamp(0.0, 1.0),
        _ => defaults.thermalSensitivity,
      },
      dailyReminderEnabled: switch (json['dailyReminderEnabled']) {
        final bool v => v,
        _ => defaults.dailyReminderEnabled,
      },
      reminderHour: switch (json['reminderHour']) {
        final int v when v >= 0 && v <= 23 => v,
        _ => defaults.reminderHour,
      },
      reminderMinute: switch (json['reminderMinute']) {
        final int v when v >= 0 && v <= 59 => v,
        _ => defaults.reminderMinute,
      },
      rainAlertEnabled: switch (json['rainAlertEnabled']) {
        final bool v => v,
        _ => defaults.rainAlertEnabled,
      },
    );
  }
}

T _parseEnum<T extends Enum>(Object? raw, List<T> values, T fallback) {
  if (raw is! String) return fallback;
  for (final v in values) {
    if (v.name == raw) return v;
  }
  return fallback;
}
