import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spades/widget/numeric_stepper.dart';

void main() {
  testWidgets('NumericStepper displays value and disables buttons at bounds', (
    WidgetTester tester,
  ) async {
    int value = 0;
    await tester.pumpWidget(
      CupertinoApp(
        home: NumericStepper(
          value: value,
          min: 0,
          max: 2,
          onDecrement: () {},
          onIncrement: () {},
        ),
      ),
    );

    expect(find.text('0'), findsOneWidget);
    final minusButton = find.widgetWithIcon(
      CupertinoButton,
      CupertinoIcons.minus,
    );
    final plusButton = find.widgetWithIcon(
      CupertinoButton,
      CupertinoIcons.plus,
    );

    expect(tester.widget<CupertinoButton>(minusButton).onPressed, isNull);
    expect(tester.widget<CupertinoButton>(plusButton).onPressed, isNotNull);
  });

  testWidgets('NumericStepper calls increment and decrement', (
    WidgetTester tester,
  ) async {
    int value = 1;
    int incrementCalls = 0;
    int decrementCalls = 0;

    await tester.pumpWidget(
      CupertinoApp(
        home: NumericStepper(
          value: value,
          min: 0,
          max: 2,
          onDecrement: () => decrementCalls++,
          onIncrement: () => incrementCalls++,
        ),
      ),
    );

    await tester.tap(find.widgetWithIcon(CupertinoButton, CupertinoIcons.plus));
    await tester.tap(
      find.widgetWithIcon(CupertinoButton, CupertinoIcons.minus),
    );
    expect(incrementCalls, 1);
    expect(decrementCalls, 1);
  });

  testWidgets('NumericStepper disables plus at max', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: NumericStepper(
          value: 2,
          min: 0,
          max: 2,
          onDecrement: () {},
          onIncrement: () {},
        ),
      ),
    );
    final plusButton = find.widgetWithIcon(
      CupertinoButton,
      CupertinoIcons.plus,
    );
    expect(tester.widget<CupertinoButton>(plusButton).onPressed, isNull);
  });
}
