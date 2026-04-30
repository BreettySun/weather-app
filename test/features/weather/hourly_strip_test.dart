import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/core/units/units.dart';
import 'package:weather_app/features/weather/model/hourly_forecast.dart';
import 'package:weather_app/features/weather/model/weather_condition.dart';
import 'package:weather_app/features/weather/view/hourly_strip.dart';

List<HourlyForecast> _generate(DateTime start, int count) {
  return List.generate(count, (i) {
    return HourlyForecast(
      time: start.add(Duration(hours: i)),
      temperatureC: 18 + i.toDouble(),
      apparentTemperatureC: 17 + i.toDouble(),
      condition: WeatherCondition.partlyCloudy,
      precipitationProbabilityPct: 10,
      windSpeedKmh: 5,
    );
  });
}

void main() {
  testWidgets('从当前小时起渲染 24 个格子', (tester) async {
    final start = DateTime(2026, 4, 30, 0);
    final hourly = _generate(start, 48);
    final now = DateTime(2026, 4, 30, 8); // 当前 8 时

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HourlyStrip(
          hourly: hourly,
          tempUnit: TemperatureUnit.celsius,
          now: now,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // 滚动条横向滚动，离屏 cell 也已构建（ListView 默认 cacheExtent 含若干屏）；
    // 但保险起见用 textContaining 找一个一定在前 24 内的小时。
    expect(find.text('08时'), findsOneWidget); // 起始
    // 31 时这个文本不存在——只有 0~23
    expect(find.text('31时'), findsNothing);
  });

  testWidgets('当前小时的格子加粗描边（高亮）', (tester) async {
    final start = DateTime(2026, 4, 30, 0);
    final hourly = _generate(start, 24);
    final now = DateTime(2026, 4, 30, 14);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 1500, // 给足横向空间，避免 14 时被滚到屏幕外
          child: HourlyStrip(
            hourly: hourly,
            tempUnit: TemperatureUnit.celsius,
            now: now,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final hour14 = tester
        .widget<Text>(find.text('14时'))
        .style!;
    expect(hour14.fontWeight, FontWeight.w800);
  });

  testWidgets('hourly 为空时返回 SizedBox.shrink', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: HourlyStrip(
          hourly: [],
          tempUnit: TemperatureUnit.celsius,
        ),
      ),
    ));
    expect(find.byType(ListView), findsNothing);
  });
}
