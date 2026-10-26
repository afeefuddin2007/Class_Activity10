import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signup_app/main.dart';

void main() {
  testWidgets('empty form displays validation errors', (tester) async {
    await tester.pumpWidget(const LaunchpadApp());
    await tester.ensureVisible(find.text('Sign up'));
    await tester.tap(find.text('Sign up'));
    await tester.pump();
    expect(find.text('Enter your full name.'), findsOneWidget);
    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter a password.'), findsOneWidget);
  });

  testWidgets('mock signup tip appears after request', (tester) async {
    await tester.pumpWidget(const LaunchpadApp());
    await tester.ensureVisible(find.text('Get a signup tip'));
    await tester.tap(find.text('Get a signup tip'));
    await tester.pumpAndSettle();
    expect(find.text('Mock AI-generated advice (no live AI called)'), findsOneWidget);
  });

  testWidgets('offline mode shows error and retry', (tester) async {
    await tester.pumpWidget(const LaunchpadApp());
    await tester.ensureVisible(find.text('Simulate offline (for testing)'));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    await tester.ensureVisible(find.text('Get a signup tip'));
    await tester.tap(find.text('Get a signup tip'));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
  });
}
