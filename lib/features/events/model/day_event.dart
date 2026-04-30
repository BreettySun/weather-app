import 'dart:math' show Random;

import 'package:flutter/foundation.dart';

import 'activity.dart';

/// 用户在首页加的"今日安排"。仅当日有效，跨日自动清空（见 EventsController）。
@immutable
class DayEvent {
  const DayEvent({
    required this.id,
    required this.activity,
    required this.startAt,
    this.note,
  });

  final String id;
  final Activity activity;

  /// 当天的某个整点（小时精度即可，分秒部分按 0 处理）。
  final DateTime startAt;
  final String? note;

  /// 简易 id 生成——时间戳 + 4 位随机。不上 uuid 包，避免新依赖。
  static String newId() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final r = Random().nextInt(9999).toString().padLeft(4, '0');
    return '${ts}_$r';
  }

  DayEvent copyWith({Activity? activity, DateTime? startAt, String? note}) {
    return DayEvent(
      id: id,
      activity: activity ?? this.activity,
      startAt: startAt ?? this.startAt,
      note: note ?? this.note,
    );
  }

  factory DayEvent.fromJson(Map<String, dynamic> json) {
    return DayEvent(
      id: json['id'] as String,
      activity: Activity.values.byName(json['activity'] as String),
      startAt: DateTime.parse(json['startAt'] as String),
      note: json['note'] as String?,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'activity': activity.name,
        'startAt': startAt.toIso8601String(),
        if (note != null) 'note': note,
      };
}
