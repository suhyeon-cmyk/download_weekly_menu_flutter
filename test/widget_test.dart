import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menu/main.dart';

void main() {
  testWidgets('Settings screen loads test', (WidgetTester tester) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger a frame.
    // Since main() is async and does some setup, we manually pump the widget.
    await tester.pumpWidget(const MyTestApp());
    await tester.pump(); // Wait for initState's async work to complete if possible, or at least one frame.
    await tester.pumpAndSettle(); // Wait for animations and state updates

    // Verify that settings screen title is shown.
    expect(find.text('식단표 설정'), findsOneWidget);
  });
}

// Minimal app for testing because main() has complex async setup
class MyTestApp extends StatelessWidget {
  const MyTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SettingsScreen(),
    );
  }
}
