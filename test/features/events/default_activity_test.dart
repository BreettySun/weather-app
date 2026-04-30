import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/features/events/model/activity.dart';

void main() {
  group('defaultActivityForDate', () {
    test('周一 ~ 周五 → commute', () {
      // 2026-04-27 是周一，往后推 4 天到周五
      for (var i = 0; i < 5; i++) {
        final d = DateTime(2026, 4, 27).add(Duration(days: i));
        expect(defaultActivityForDate(d), Activity.commute,
            reason: 'weekday=${d.weekday}');
      }
    });

    test('周六 / 周日 → casual', () {
      // 2026-05-02 周六, 2026-05-03 周日
      expect(defaultActivityForDate(DateTime(2026, 5, 2)), Activity.casual);
      expect(defaultActivityForDate(DateTime(2026, 5, 3)), Activity.casual);
    });
  });

  group('defaultActivityContextLabel', () {
    test('工作日 · 通勤', () {
      // 2026-04-30 是周四
      expect(defaultActivityContextLabel(DateTime(2026, 4, 30)), '工作日 · 通勤');
    });

    test('周末 · 休闲', () {
      // 2026-05-02 是周六
      expect(defaultActivityContextLabel(DateTime(2026, 5, 2)), '周末 · 休闲');
    });
  });
}
