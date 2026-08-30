import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scorchepay/main.dart';

void main() {
  testWidgets('App builds without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const ScorchePayApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
