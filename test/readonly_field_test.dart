import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spades/widget/readonly_field.dart';
import 'package:spades/colors.dart';

void main() {
  testWidgets('ReadonlyField displays text', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: ReadonlyField(text: 'Hello'),
      ),
    );
    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('ReadonlyField uses custom textAlign', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: ReadonlyField(text: 'Align', textAlign: TextAlign.left),
      ),
    );
    final text = tester.widget<Text>(find.text('Align'));
    expect(text.textAlign, TextAlign.left);
  });

  testWidgets('ReadonlyField uses custom backgroundColor', (WidgetTester tester) async {
    const color = Color(0xFF123456);
    await tester.pumpWidget(
      const CupertinoApp(
        home: ReadonlyField(text: 'BG', backgroundColor: color),
      ),
    );
    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, color);
  });

  testWidgets('ReadonlyField uses custom padding', (WidgetTester tester) async {
    const padding = EdgeInsets.all(20);
    await tester.pumpWidget(
      const CupertinoApp(
        home: ReadonlyField(text: 'Pad', padding: padding),
      ),
    );
    final container = tester.widget<Container>(find.byType(Container));
    expect(container.padding, padding);
  });

  testWidgets('ReadonlyField uses AppColors.textPrimary for text', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: ReadonlyField(text: 'Color'),
      ),
    );
    final text = tester.widget<Text>(find.text('Color'));
    expect(text.style?.color, AppColors.textPrimary);
  });
}
