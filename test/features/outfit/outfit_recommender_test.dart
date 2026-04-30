import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/features/events/model/activity.dart';
import 'package:weather_app/features/outfit/controller/outfit_provider.dart';
import 'package:weather_app/features/outfit/data/outfit_catalog.dart';
import 'package:weather_app/features/outfit/model/temperature_bracket.dart';
import 'package:weather_app/features/settings/model/user_preferences.dart';
import 'package:weather_app/features/weather/model/current_weather.dart';
import 'package:weather_app/features/weather/model/daily_forecast.dart';
import 'package:weather_app/features/weather/model/hourly_forecast.dart';
import 'package:weather_app/features/weather/model/weather_condition.dart';

CurrentWeather _current({
  double feels = 18,
  double precipitationMm = 0,
  WeatherCondition condition = WeatherCondition.partlyCloudy,
}) {
  return CurrentWeather(
    time: DateTime.utc(2026, 4, 29, 9),
    temperatureC: feels + 1,
    apparentTemperatureC: feels,
    humidityPct: 50,
    precipitationMm: precipitationMm,
    isDay: true,
    condition: condition,
    windSpeedKmh: 10,
    windDirectionDeg: 90,
  );
}

DailyForecast _today({
  double feels = 18,
  int popPct = 10,
  double uv = 3,
}) {
  return DailyForecast(
    date: DateTime.utc(2026, 4, 29),
    tempMaxC: feels + 4,
    tempMinC: feels - 4,
    apparentMaxC: feels + 4,
    apparentMinC: feels - 4,
    condition: WeatherCondition.partlyCloudy,
    precipitationSumMm: 0,
    precipitationProbabilityPct: popPct,
    uvIndexMax: uv,
    windSpeedMaxKmh: 12,
  );
}

void main() {
  group('adjustFeelsBySensitivity', () {
    test('0.5 = neutral, no shift', () {
      expect(adjustFeelsBySensitivity(20, 0.5), closeTo(20, 1e-9));
    });

    test('0 = cold-sensitive → shifts down 4°C', () {
      expect(adjustFeelsBySensitivity(20, 0), closeTo(16, 1e-9));
    });

    test('1 = heat-sensitive → shifts up 4°C', () {
      expect(adjustFeelsBySensitivity(20, 1), closeTo(24, 1e-9));
    });
  });

  group('outfitPiecesFor', () {
    test('default casual + universal returns base table', () {
      final p = outfitPiecesFor(
        bracket: TemperatureBracket.mild,
        style: ClothingStyle.casual,
        gender: GenderPreference.universal,
      );
      expect(p.top, '长袖衬衫');
      expect(p.bottom, '休闲长裤');
      expect(p.jacket, '薄风衣');
      expect(p.shoes, '运动鞋');
    });

    test('business style swaps all 4 pieces', () {
      final p = outfitPiecesFor(
        bracket: TemperatureBracket.cool,
        style: ClothingStyle.business,
        gender: GenderPreference.universal,
      );
      expect(p.top, '正装衬衫');
      expect(p.bottom, '西装长裤');
      expect(p.jacket, '西装外套');
      expect(p.shoes, '商务皮鞋');
    });

    test('female gender refines top/bottom on top of style', () {
      // 女款 + 休闲 → 在 mild 档把 top 换成针织开衫，bottom 换成长裙
      final p = outfitPiecesFor(
        bracket: TemperatureBracket.mild,
        style: ClothingStyle.casual,
        gender: GenderPreference.female,
      );
      expect(p.top, '针织开衫');
      expect(p.bottom, '长裙 / 阔腿裤');
      // jacket / shoes 不在 gender 覆盖里——保留 base
      expect(p.jacket, '薄风衣');
      expect(p.shoes, '运动鞋');
    });

    test('female gender overrides style override (gender wins)', () {
      // 女款 + 商务 → 顶部从"正装衬衫"被女款"针织开衫"压过；
      // bottom 同理被换成"长裙 / 阔腿裤"；jacket / shoes 仍保留商务覆盖。
      final p = outfitPiecesFor(
        bracket: TemperatureBracket.mild,
        style: ClothingStyle.business,
        gender: GenderPreference.female,
      );
      expect(p.top, '针织开衫');
      expect(p.bottom, '长裙 / 阔腿裤');
      expect(p.jacket, '薄西装');
      expect(p.shoes, '商务皮鞋');
    });

    test('male gender only swaps the few items it specifies', () {
      final p = outfitPiecesFor(
        bracket: TemperatureBracket.mild,
        style: ClothingStyle.casual,
        gender: GenderPreference.male,
      );
      expect(p.top, 'POLO 衫');
      // 其他 3 件保留 base
      expect(p.bottom, '休闲长裤');
      expect(p.jacket, '薄风衣');
      expect(p.shoes, '运动鞋');
    });

    test('exercise activity 覆盖 shoes 与 jacket=null，保留 style 上衣 (mild)', () {
      // sporty 风格 mild 档：top=速干 T 恤、bottom=运动长裤、jacket=运动外套、shoes=跑鞋
      // exercise overlay 在 mild 档：top/bottom/jacket=null/shoes=跑鞋（jacket null 表示去掉外套）
      final p = outfitPiecesFor(
        bracket: TemperatureBracket.mild,
        style: ClothingStyle.sporty,
        gender: GenderPreference.universal,
        activity: Activity.exercise,
      );
      // exercise 在 mild 档明确给了 top='速干 T 恤'/bottom='运动短裤'，会覆盖 sporty 的运动长裤
      expect(p.bottom, '运动短裤');
      expect(p.shoes, '跑鞋');
      // jacket=null 表示沿用前一层（sporty 给的"运动外套"）。
      // 注意：activity overlay 的 null 不能"显式去掉"前一层值——这是 _apply 的语义。
      expect(p.jacket, '运动外套');
    });

    test('formal activity 在 cool 档覆盖全部 4 件', () {
      final p = outfitPiecesFor(
        bracket: TemperatureBracket.cool,
        style: ClothingStyle.casual,
        gender: GenderPreference.universal,
        activity: Activity.formal,
      );
      expect(p.top, '正装衬衫');
      expect(p.bottom, '西装长裤');
      expect(p.jacket, '西装外套');
      expect(p.shoes, '商务皮鞋');
    });

    test('outing activity 覆盖 jacket+shoes，保留 style 上衣下装', () {
      final p = outfitPiecesFor(
        bracket: TemperatureBracket.mild,
        style: ClothingStyle.casual,
        gender: GenderPreference.universal,
        activity: Activity.outing,
      );
      // outing 只给 jacket / shoes，其他保留 casual base
      expect(p.top, '长袖衬衫');
      expect(p.bottom, '休闲长裤');
      expect(p.jacket, '防风外套');
      expect(p.shoes, '徒步鞋');
    });

    test('commute / casual activity 不覆盖任何项', () {
      final base = outfitPiecesFor(
        bracket: TemperatureBracket.mild,
        style: ClothingStyle.casual,
        gender: GenderPreference.universal,
      );
      final commute = outfitPiecesFor(
        bracket: TemperatureBracket.mild,
        style: ClothingStyle.casual,
        gender: GenderPreference.universal,
        activity: Activity.commute,
      );
      expect(commute.top, base.top);
      expect(commute.bottom, base.bottom);
      expect(commute.jacket, base.jacket);
      expect(commute.shoes, base.shoes);
    });
  });

  group('recommendOutfit', () {
    test('default prefs at feels=20° picks mild bracket', () {
      const prefs = UserPreferences();
      final r = recommendOutfit(
        current: _current(feels: 20),
        today: _today(feels: 20),
        prefs: prefs,
      );
      // mild [15, 22) base
      expect(r.top, '长袖衬衫');
      expect(r.bottom, '休闲长裤');
    });

    test('cold-sensitive (sensitivity=0) at feels=10° picks cold bracket', () {
      // adjusted = 10 - 4 = 6°C → cold [0, 8)
      const prefs = UserPreferences(thermalSensitivity: 0);
      final r = recommendOutfit(
        current: _current(feels: 10),
        today: _today(feels: 10),
        prefs: prefs,
      );
      expect(r.jacket, '加厚外套'); // cold base
    });

    test('heat-sensitive (sensitivity=1) at feels=20° picks warm bracket', () {
      // adjusted = 20 + 4 = 24°C → warm [22, 28)
      const prefs = UserPreferences(thermalSensitivity: 1);
      final r = recommendOutfit(
        current: _current(feels: 20),
        today: _today(feels: 20),
        prefs: prefs,
      );
      expect(r.jacket, '无需外套'); // warm base
    });

    test('rainy weather forces 防水短靴 regardless of style', () {
      const prefs = UserPreferences(style: ClothingStyle.business);
      final r = recommendOutfit(
        current: _current(feels: 18, precipitationMm: 1.0),
        today: _today(feels: 18),
        prefs: prefs,
      );
      expect(r.shoes, '防水短靴');
      // top 仍由 business 风格决定
      expect(r.top, '正装衬衫');
    });

    test('female + sporty + warm → bottom 半身裙 / 九分裤 (gender wins)', () {
      const prefs = UserPreferences(
        style: ClothingStyle.sporty,
        gender: GenderPreference.female,
      );
      final r = recommendOutfit(
        current: _current(feels: 25),
        today: _today(feels: 25),
        prefs: prefs,
      );
      // 性别覆盖压过 sporty.bottom='运动短裤'
      expect(r.bottom, '半身裙 / 九分裤');
      expect(r.top, '雪纺短袖');
    });

    test('tip ignores thermal sensitivity (uses raw feels)', () {
      // 怕冷的用户在 30°C 真实体感，依然应看到"高温"提示
      // 使用日温差 <8 的 today，避免被"早晚温差大"分支命中。
      const prefs = UserPreferences(thermalSensitivity: 0);
      final today = DailyForecast(
        date: DateTime.utc(2026, 7, 15),
        tempMaxC: 31,
        tempMinC: 28,
        apparentMaxC: 31,
        apparentMinC: 28,
        condition: WeatherCondition.partlyCloudy,
        precipitationSumMm: 0,
        precipitationProbabilityPct: 10,
        uvIndexMax: 3,
        windSpeedMaxKmh: 8,
      );
      final r = recommendOutfit(
        current: _current(feels: 30),
        today: today,
        prefs: prefs,
      );
      expect(r.tip, '高温天气，注意防晒补水');
    });

    test('targetHour 给定时按那个小时的体感选 bracket', () {
      // 当前 25°C（warm）但目标小时 4°C（cold）。
      // 默认 sensitivity=0.4 → adjusted=4-0.8=3.2°C → cold [0,8)
      const prefs = UserPreferences();
      final hour = HourlyForecast(
        time: DateTime.utc(2026, 4, 30, 19),
        temperatureC: 5,
        apparentTemperatureC: 4,
        condition: WeatherCondition.partlyCloudy,
        precipitationProbabilityPct: 10,
        windSpeedKmh: 8,
      );
      final r = recommendOutfit(
        current: _current(feels: 25),
        today: _today(feels: 25),
        targetHour: hour,
        prefs: prefs,
      );
      // cold base：外套"加厚外套"
      expect(r.jacket, '加厚外套');
    });

    test('雨天兜底压过 activity 的运动鞋（exercise + 雨）', () {
      const prefs = UserPreferences();
      final r = recommendOutfit(
        current: _current(feels: 18, precipitationMm: 1.0),
        today: _today(feels: 18),
        activity: Activity.exercise,
        prefs: prefs,
      );
      expect(r.shoes, '防水短靴');
    });

    test('targetHour 降水 ≥60% 时鞋换成防水短靴', () {
      const prefs = UserPreferences();
      final hour = HourlyForecast(
        time: DateTime.utc(2026, 4, 30, 14),
        temperatureC: 18,
        apparentTemperatureC: 17,
        condition: WeatherCondition.rain,
        precipitationProbabilityPct: 80,
        windSpeedKmh: 10,
      );
      final r = recommendOutfit(
        current: _current(feels: 25), // 当前没下雨
        today: _today(feels: 18, popPct: 5),
        targetHour: hour,
        activity: Activity.outing, // 本来是徒步鞋
        prefs: prefs,
      );
      expect(r.shoes, '防水短靴');
    });
  });
}
