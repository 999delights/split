import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_paper/main.dart';

void main() {
  test('Equal split retains cents and manual remainder', () {
    expect(allocateShares(10001, ['a', 'b', 'c'], {}), {
      'a': 3334,
      'b': 3334,
      'c': 3333,
    });
    expect(allocateShares(10001, ['a', 'b', 'c'], {'a': 2000}), {
      'a': 2000,
      'b': 4001,
      'c': 4000,
    });
    expect(
      () => allocateShares(100, ['a', 'b'], {'a': 101}),
      throwsFormatException,
    );
    expect(parseMinor('12,34'), 1234);
    expect(money(2700, ''), '27');
  });
  testWidgets(
    'Original split flow highlights selection and recomputes manual remainder',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ExpenseForm(
            group: {
              'id': 'g',
              'name': 'Trip',
              'currency': '',
              'members': [
                {'id': 'a', 'name': 'Me'},
                {'id': 'b', 'name': 'Ana'},
              ],
            },
          ),
        ),
      );
      expect(find.text('What is this for?'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Dinner');
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '100');
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CupertinoSwitch));
      await tester.pumpAndSettle();
      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields.map((x) => x.controller!.text), ['50', '50']);
      await tester.enterText(find.byType(TextField).first, '30');
      await tester.pumpAndSettle();
      expect(fields.last.controller!.text, '70');
      final cards = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .where(
            (x) =>
                x.decoration is BoxDecoration &&
                (x.decoration as BoxDecoration).borderRadius ==
                    BorderRadius.circular(15),
          );
      expect(cards.length, 2);
      expect(
        cards.every(
          (x) =>
              (x.decoration as BoxDecoration).color ==
              Colors.blue.withValues(alpha: .15),
        ),
        true,
      );
      await tester.tap(find.text('Split with 2'));
      await tester.pumpAndSettle();
      expect(find.text('split review'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
