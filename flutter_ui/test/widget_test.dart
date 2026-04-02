// Prueba de humo de la UI; monta BluhorizonApp y verifica elementos base del chat.

import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "package:bluhorizon_flutter_ui/main.dart";

void main() {
  testWidgets("Renderiza la pantalla principal del chat", (
    WidgetTester tester,
  ) async {
    // Evita que SharedPreferences falle en entorno de la prueba
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const BluhorizonApp());
    await tester.pumpAndSettle();

    expect(find.text("Tutor GenAI"), findsOneWidget);
    expect(find.text("Enviar"), findsOneWidget);
  });
}
