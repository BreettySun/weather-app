import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/app.dart';

void main() {
  testWidgets('app boots without crashing', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: WeatherApp()),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
