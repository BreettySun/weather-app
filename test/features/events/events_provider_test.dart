import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/core/storage/preferences.dart';
import 'package:weather_app/features/events/controller/events_provider.dart';
import 'package:weather_app/features/events/model/activity.dart';
import 'package:weather_app/features/events/model/day_event.dart';

DateTime _hour(int h) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day, h);
}

DayEvent _make({required String id, required int hour, Activity? activity}) {
  return DayEvent(
    id: id,
    activity: activity ?? Activity.casual,
    startAt: _hour(hour),
  );
}

Future<ProviderContainer> _container({Map<String, Object> seed = const {}}) async {
  SharedPreferences.setMockInitialValues(seed);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
}

void main() {
  test('add 后按 startAt 升序', () async {
    final container = await _container();
    addTearDown(container.dispose);

    final ctrl = container.read(eventsProvider.notifier);
    ctrl.add(_make(id: 'b', hour: 14));
    ctrl.add(_make(id: 'a', hour: 9));
    ctrl.add(_make(id: 'c', hour: 20));

    final list = container.read(eventsProvider);
    expect(list.map((e) => e.id), ['a', 'b', 'c']);
  });

  test('remove 删除指定 id', () async {
    final container = await _container();
    addTearDown(container.dispose);

    final ctrl = container.read(eventsProvider.notifier);
    ctrl.add(_make(id: 'x', hour: 10));
    ctrl.add(_make(id: 'y', hour: 14));
    ctrl.remove('x');
    expect(container.read(eventsProvider).map((e) => e.id), ['y']);
  });

  test('add → 持久化 → 新 container 能 load 回来', () async {
    SharedPreferences.setMockInitialValues(const {});
    var prefs = await SharedPreferences.getInstance();
    var c1 = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    c1.read(eventsProvider.notifier).add(_make(id: 'persist', hour: 11));
    // 让 write 落地。
    await Future<void>.delayed(Duration.zero);
    c1.dispose();

    // 用同一个 mock prefs 起一个新 container（模拟冷启动）
    prefs = await SharedPreferences.getInstance();
    final c2 = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(c2.dispose);
    expect(c2.read(eventsProvider).map((e) => e.id), ['persist']);
  });

  test('跨日：昨天的事件在冷启动后被清空', () async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yDay = DateTime(yesterday.year, yesterday.month, yesterday.day);
    final payload = jsonEncode({
      'date': yDay.toIso8601String(),
      'events': [
        {
          'id': 'old',
          'activity': 'casual',
          'startAt': yDay.add(const Duration(hours: 14)).toIso8601String(),
        }
      ],
    });

    final container = await _container(
      seed: <String, Object>{'day_events.v1': payload},
    );
    addTearDown(container.dispose);

    expect(container.read(eventsProvider), isEmpty);
    // 顺便确认脏数据被清掉
    expect(container.read(sharedPreferencesProvider).getString('day_events.v1'), isNull);
  });

  test('坏 JSON 不抛错并清掉', () async {
    final container = await _container(
      seed: <String, Object>{'day_events.v1': 'not json'},
    );
    addTearDown(container.dispose);
    expect(container.read(eventsProvider), isEmpty);
  });
}
