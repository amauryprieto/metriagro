// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:metriagro/main.dart';

void main() {
  testWidgets('App starts with welcome page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MetriagroApp());

    // Verify that our app shows the welcome page
    expect(find.text('Metriagro'), findsOneWidget);
    expect(find.text('Haz tu mejor trabajo con Metriagro'), findsOneWidget);
    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(find.text('Ingresa tu email o teléfono'), findsOneWidget);
  });
}
