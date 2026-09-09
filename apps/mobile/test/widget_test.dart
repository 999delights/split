import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_paper/main.dart';

void main() {
  testWidgets('Original welcome artwork and labels are retained', (
    tester,
  ) async {
    await tester.pumpWidget(const SplitApp());
    expect(find.text('split paper'), findsOneWidget);
    expect(find.text('Split expenses with any group.'), findsOneWidget);
    expect(find.text('Sign up with Email'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Group creation exposes original title and action', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CreateGroup()));
    expect(find.text('What is the group name?'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
