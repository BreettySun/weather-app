import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/features/weather/controller/location_provider.dart';
import 'package:weather_app/features/weather/model/geo_location.dart';

void main() {
  group('SelectedLocationController', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('first launch returns null (no cached location)', () async {
      final prefs = await SharedPreferences.getInstance();
      final c = SelectedLocationController(prefs);
      expect(c.state, isNull);
    });

    test('set then re-load round-trips all fields', () async {
      final prefs = await SharedPreferences.getInstance();
      final c = SelectedLocationController(prefs);

      const loc = GeoLocation(
        name: '杭州',
        latitude: 30.27,
        longitude: 120.16,
        admin1: '浙江省',
        country: '中国',
        countryCode: 'CN',
        timezone: 'Asia/Shanghai',
      );
      c.set(loc);
      await Future<void>.delayed(Duration.zero);

      final c2 = SelectedLocationController(prefs);
      expect(c2.state, isNotNull);
      expect(c2.state!.name, '杭州');
      expect(c2.state!.latitude, closeTo(30.27, 1e-9));
      expect(c2.state!.longitude, closeTo(120.16, 1e-9));
      expect(c2.state!.admin1, '浙江省');
      expect(c2.state!.country, '中国');
      expect(c2.state!.countryCode, 'CN');
      expect(c2.state!.timezone, 'Asia/Shanghai');
    });

    test('clear removes the cached value', () async {
      final prefs = await SharedPreferences.getInstance();
      final c = SelectedLocationController(prefs);
      c.set(GeoLocation.coords(latitude: 1, longitude: 2));
      await Future<void>.delayed(Duration.zero);

      c.clear();
      await Future<void>.delayed(Duration.zero);

      final c2 = SelectedLocationController(prefs);
      expect(c2.state, isNull);
    });

    test('corrupt JSON resets to null without throwing', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'selected_location.v1': 'not-json{',
      });
      final prefs = await SharedPreferences.getInstance();
      final c = SelectedLocationController(prefs);
      expect(c.state, isNull);
      expect(prefs.getString('selected_location.v1'), isNull);
    });
  });
}
