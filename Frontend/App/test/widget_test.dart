// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:argus_x_hud/main.dart';
import 'package:argus_x_hud/services/websocket_service.dart';

void main() {
  testWidgets('HUD App smoke test', (WidgetTester tester) async {
    final wsService = WebSocketService();
    // Build our app and trigger a frame.
    await tester.pumpWidget(ArgusHUDApp(wsService: wsService));

    // Verify that the MaterialApp is constructed.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
