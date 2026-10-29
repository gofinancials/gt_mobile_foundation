import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

void main() {
  final navigatorKey = GlobalKey<NavigatorState>();
  final screenKey = GlobalKey();
  final screenField = FocusNode(debugLabel: 'screen field');
  final sheetField = FocusNode(debugLabel: 'sheet field');

  tearDownAll(() {
    screenField.dispose();
    sheetField.dispose();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: Scaffold(
          key: screenKey,
          body: TextField(focusNode: screenField),
        ),
      ),
    );
  }

  Future<void> pushSheet(WidgetTester tester) async {
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(body: TextField(focusNode: sheetField)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('resetFocus drops the focused field', (tester) async {
    await pumpScreen(tester);
    screenField.requestFocus();
    await tester.pump();

    screenKey.currentContext!.resetFocus();
    await tester.pump();

    expect(screenField.hasFocus, isFalse);
  });

  testWidgets('a caller below the top route leaves focus off its route', (
    tester,
  ) async {
    await pumpScreen(tester);
    await pushSheet(tester);
    sheetField.requestFocus();
    await tester.pump();

    screenKey.currentContext!.resetFocus();
    await tester.pump();

    final screenScope = FocusScope.of(screenKey.currentContext!);
    expect(sheetField.hasFocus, isFalse);
    expect(screenScope.hasFocus, isFalse);
  });

  testWidgets('a closing route does not hand focus back to the field', (
    tester,
  ) async {
    await pumpScreen(tester);
    screenField.requestFocus();
    await tester.pump();

    screenKey.currentContext!.resetFocus();
    await pushSheet(tester);
    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();

    expect(screenField.hasFocus, isFalse);
  });
}
