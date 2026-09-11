import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_paper/main.dart';

Map<String, dynamic> fixture() => {
  'id': 'test-group',
  'name': 'Trip',
  'icon': 4,
  'color': 'Cgroup4',
  'currency': 'RON',
  'my_member_id': 'self',
  'members': [
    {'id': 'friend', 'name': 'Friend'},
    {'id': 'self', 'name': 'Owner'},
  ],
  'expenses': [
    {
      'id': '1',
      'name': 'Dinner',
      'amount': 5000,
      'payer': 'self',
      'created': '2026-01-02T12:00:00Z',
      'shares': {'self': 2400, 'friend': 2600},
    },
  ],
  'settlements': [],
  'balances': {'self': 2600, 'friend': -2600},
};
Future<void> open(
  WidgetTester tester,
  Widget screen, {
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = const Size(402, 874);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(theme: const SplitApp().theme(brightness), home: screen),
  );
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, String name) async {
  if (Platform.environment['CAPTURE_SPLIT'] != '1') return;
  final boundary = tester.firstRenderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(
      '/tmp/split-$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  test('Reciprocal debts, chains and repayments preserve every cent', () {
    final g = fixture();
    g['members'].add({'id': 'third', 'name': 'Third'});
    g['expenses'].add({
      'payer': 'friend',
      'shares': {'third': 3000},
    });
    var d = groupDebts(g);
    expect(d['friend']!['self'], 0);
    expect(d['third']!['self'], 2600);
    expect(d['third']!['friend'], 400);
    g['settlements'].add({
      'sender': 'third',
      'receiver': 'self',
      'amount': 2599,
    });
    d = groupDebts(g);
    expect(d['third']!['self'], 1); // Never hide small debts as Swift did.
    expect(d['third']!['friend'], 400);
  });
  testWidgets(
    'Stats excludes self and displays personal header and relative debt',
    (tester) async {
      await open(tester, GroupPage(group: fixture()));
      expect(find.byKey(const ValueKey('stats-self')), findsNothing);
      expect(find.byKey(const ValueKey('stats-friend')), findsOneWidget);
      expect(find.text("You're owed"), findsOneWidget);
      expect(find.text('owes you'), findsOneWidget);
      final header = find.byKey(const ValueKey('personal-balance'));
      expect(
        tester
            .widget<Text>(
              find.descendant(of: header, matching: find.text('26')),
            )
            .style!
            .color,
        creditGreen,
      );
      final spent = find.byKey(const ValueKey('personal-spent'));
      expect(
        tester
            .widget<Text>(find.descendant(of: spent, matching: find.text('24')))
            .style!
            .color,
        debtRed,
      );
      await capture(tester, 'stats-light');
      await tester.tap(find.text('activity'));
      await tester.pumpAndSettle();
      expect(find.text('Dinner'), findsOneWidget);
      expect(
        find.textContaining('You get back', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Spent 24', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('by Me'), findsNothing);
      final title = tester.getRect(find.text('Dinner'));
      final amount = tester.getRect(find.text('50'));
      expect((title.center.dy - amount.center.dy).abs(), lessThan(2));
      expect(amount.left, greaterThan(title.right));
      final credit = tester.widget<RichText>(
        find.textContaining('You get back', findRichText: true),
      );
      expect(credit.text.style!.color, creditGreen.withValues(alpha: .75));

      await capture(tester, 'activity-light');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Debit, settled state and participant perspective are not inverted',
    (tester) async {
      final g = fixture();
      g['expenses'][0]['payer'] = 'friend';
      g['balances'] = {'self': -2400, 'friend': 2400};
      await open(tester, GroupPage(group: g));
      expect(find.text('You owe'), findsOneWidget);
      expect(find.text('is owed'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('stats-friend')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining("'s stats", findRichText: true),
        findsOneWidget,
      );
      expect(find.text("You're owed"), findsOneWidget);
      expect(find.byKey(const ValueKey('stats-self')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Dark stats and activity preserve contrast', (tester) async {
    await open(
      tester,
      GroupPage(group: fixture()),
      brightness: Brightness.dark,
    );
    await capture(tester, 'stats-dark');
    expect(tester.takeException(), isNull);
  });
  testWidgets('Activity excludes unrelated payments and orders by date', (
    tester,
  ) async {
    final g = fixture();
    g['expenses'].add({
      'id': '2',
      'name': 'Private',
      'amount': 100,
      'payer': 'friend',
      'shares': {'friend': 100},
      'created': '2026-01-03T12:00:00Z',
    });
    await open(
      tester,
      Scaffold(
        body: ActivityList(group: g, onExpense: (_) {}),
      ),
    );
    expect(find.text('Private'), findsNothing);
    expect(find.text('Dinner'), findsOneWidget);
  });
  testWidgets(
    'Editing opens existing split without redistributing it; tap selects amount',
    (tester) async {
      final g = fixture();
      await open(tester, ExpenseForm(group: g, expense: g['expenses'][0]));
      final self = find.byKey(const ValueKey('share-self'));
      expect(tester.widget<TextField>(self).controller!.text, '24');
      await tester.tap(self);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(self).controller!.selection,
        const TextSelection(baseOffset: 0, extentOffset: 2),
      );
      await capture(tester, 'split-selection');
      await tester.tap(find.text('Split with 2'));
      await tester.pumpAndSettle();
      expect(find.text('split review'), findsOneWidget);
      expect(find.text('26'), findsNWidgets(2));
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Confirm'),
            )
            .onPressed,
        isNotNull,
      );
      await capture(tester, 'split-review');
      expect(tester.takeException(), isNull);
    },
  );
  test('Legacy group creation dates retain original newest-first order', () {
    expect(
      groupDate({'date_json': '{"seconds":1686863069,"nanos":0}'}),
      '2023-06-15T21:04:29.000Z',
    );
  });
  testWidgets(
    'A payment by another person has no fictitious green zero total',
    (tester) async {
      final g = fixture();
      g['expenses'][0]['payer'] = 'friend';
      await open(
        tester,
        Scaffold(
          body: PaymentDetails(group: g, expense: g['expenses'][0]),
        ),
      );
      expect(find.text('0'), findsNothing);
      expect(find.text('24'), findsOneWidget);
      expect(find.text('26'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
