import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test: renderiza um widget simples', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('notat')),
        ),
      ),
    );

    expect(find.text('notat'), findsOneWidget);
  });
}
