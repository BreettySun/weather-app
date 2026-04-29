import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/storage/preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // iOS 端通过 App Group 在主 App 与 Widget Extension 间共享 UserDefaults；
  // Android 端忽略此设置（直接用 SharedPreferences），所以无条件调用是安全的。
  await HomeWidget.setAppGroupId('group.com.softandapp.weather_app');
  // 预热 SharedPreferences，让所有同步消费者构造期就能拿到旧值。
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const WeatherApp(),
    ),
  );
}
