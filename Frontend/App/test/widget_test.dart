import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:argusx/main.dart';

import 'package:argusx/services/auth_service.dart';

void main() {
  testWidgets('ArgusX app smoke test', (WidgetTester tester) async {
    final auth = ArgusXAuthService();
    await tester.pumpWidget(
      ArgusXApp(authService: auth),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
