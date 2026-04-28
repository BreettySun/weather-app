import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/app.dart';

void main() {
  testWidgets('app boots without crashing', (tester) async {
    // Simulate a typical phone viewport so onboarding layout has room.
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(child: WeatherApp()),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
