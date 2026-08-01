// Smoke test for the login screen. Pumps LoginScreen directly (wrapped in a
// MaterialApp) rather than App, so it stays valid even while App is
// temporarily pointed at HomeScreen during dashboard UI work.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:corn_detection/screens/auth/login_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('Login screen renders email, password, and login button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap(const LoginScreen()));

    expect(find.text('MaisNutri'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
  });

  testWidgets('Empty submit shows validation errors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap(const LoginScreen()));

    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();

    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
  });
}
