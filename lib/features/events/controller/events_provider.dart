import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/preferences.dart';
import '../model/day_event.dart';

/// 持久化用的 key——payload 既存事件列表也存"日期戳"，用于跨日清空。
const _kEventsKey = 'day_events.v1';

/// 今日事件列表。仅当日——构造期对照 [_load] 的 `date` 字段，
/// 与 [DateTime.now()] 不同则清空（"用户上次开 app 是昨天"的兜底）。
class EventsController extends StateNotifier<List<DayEvent>> {
  EventsController(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static List<DayEvent> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_kEventsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const [];
      final map = decoded.cast<String, dynamic>();
      final stored = DateTime.tryParse(map['date'] as String? ?? '');
      if (stored == null || !_sameDay(stored, DateTime.now())) {
        // 跨日，清掉旧值——下一次 add 自然写入新日期。
        unawaited(prefs.remove(_kEventsKey));
        return const [];
      }
      final list = (map['events'] as List).cast<Map>();
      return list
          .map((m) => DayEvent.fromJson(m.cast<String, dynamic>()))
          .toList(growable: false);
    } catch (e, st) {
      debugPrint('[Events] failed to parse, dropping: $e\n$st');
      unawaited(prefs.remove(_kEventsKey));
      return const [];
    }
  }

  /// 今日新增事件——按 startAt 升序保持有序，便于 UI 直接渲染。
  void add(DayEvent event) {
    final next = [...state, event]..sort((a, b) => a.startAt.compareTo(b.startAt));
    state = next;
    _persist();
  }

  void remove(String id) {
    state = state.where((e) => e.id != id).toList(growable: false);
    _persist();
  }

  void update(DayEvent event) {
    final idx = state.indexWhere((e) => e.id == event.id);
    if (idx < 0) return;
    final next = [...state];
    next[idx] = event;
    next.sort((a, b) => a.startAt.compareTo(b.startAt));
    state = next;
    _persist();
  }

  void clear() {
    state = const [];
    unawaited(_prefs.remove(_kEventsKey));
  }

  void _persist() {
    if (state.isEmpty) {
      unawaited(_prefs.remove(_kEventsKey));
      return;
    }
    final payload = jsonEncode({
      'date': _today().toIso8601String(),
      'events': state.map((e) => e.toJson()).toList(growable: false),
    });
    unawaited(_prefs.setString(_kEventsKey, payload));
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

final eventsProvider =
    StateNotifierProvider<EventsController, List<DayEvent>>((ref) {
  return EventsController(ref.watch(sharedPreferencesProvider));
});
