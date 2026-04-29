import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/core/units/units.dart';

void main() {
  group('convertCelsius', () {
    test('passes through celsius', () {
      expect(convertCelsius(20, TemperatureUnit.celsius), 20);
    });
    test('converts to fahrenheit using 9/5 + 32', () {
      expect(convertCelsius(0, TemperatureUnit.fahrenheit), 32);
      expect(convertCelsius(100, TemperatureUnit.fahrenheit), 212);
      expect(
        convertCelsius(20, TemperatureUnit.fahrenheit),
        closeTo(68, 1e-9),
      );
    });
  });

  group('convertKmh', () {
    test('passes through kmh', () {
      expect(convertKmh(36, WindSpeedUnit.kmh), 36);
    });
    test('converts to m/s by dividing by 3.6', () {
      expect(convertKmh(36, WindSpeedUnit.ms), closeTo(10, 1e-9));
      expect(convertKmh(0, WindSpeedUnit.ms), 0);
    });
  });

  group('formatTemperature', () {
    test('rounds and appends celsius symbol', () {
      expect(formatTemperature(21.4, TemperatureUnit.celsius), '21°C');
      expect(formatTemperature(21.6, TemperatureUnit.celsius), '22°C');
    });
    test('converts to fahrenheit before formatting', () {
      // 20°C → 68°F
      expect(formatTemperature(20, TemperatureUnit.fahrenheit), '68°F');
    });
  });

  group('formatTemperatureShort', () {
    test('omits unit symbol but keeps degree', () {
      expect(formatTemperatureShort(21.0, TemperatureUnit.celsius), '21°');
      expect(formatTemperatureShort(20, TemperatureUnit.fahrenheit), '68°');
    });
  });

  group('formatWindSpeed', () {
    test('kmh: integer rounding', () {
      expect(formatWindSpeed(12.4, WindSpeedUnit.kmh), '12 km/h');
    });
    test('m/s: 1-decimal precision', () {
      // 36 km/h = 10.0 m/s
      expect(formatWindSpeed(36, WindSpeedUnit.ms), '10.0 m/s');
      // 10 km/h = 2.78 m/s
      expect(formatWindSpeed(10, WindSpeedUnit.ms), '2.8 m/s');
    });
  });
}
