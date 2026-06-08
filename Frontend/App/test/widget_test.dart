import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:argusx/main.dart';

void main() {
  testWidgets('ArgusX app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ArgusXApp(),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
