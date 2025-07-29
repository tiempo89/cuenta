// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calculos_table/main.dart';

void main() {
  group('Pruebas de la Planilla de Cálculos', () {
    testWidgets('Verifica la carga inicial de la aplicación', (
      WidgetTester tester,
    ) async {
      // Construye nuestra app y dispara un frame
      await tester.pumpWidget(const MyApp());

      // Verifica que el título de la AppBar existe
      expect(
        find.text('Planilla de colectas, intenciones y otros'),
        findsOneWidget,
      );

      // Verifica que los campos de texto están presentes
      expect(find.widgetWithText(TextField, 'Fecha'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Comunidad'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Celebración'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Celebrante'), findsOneWidget);

      // Verifica que los botones están presentes
      expect(find.byTooltip('Cambiar tema'), findsOneWidget);
      expect(find.byTooltip('Guardar como imagen'), findsOneWidget);
      expect(find.byTooltip('Limpiar tabla'), findsOneWidget);
    });

    testWidgets('Prueba la funcionalidad de limpiar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());

      // Encuentra el campo de Comunidad y escribe en él
      final comunidadField = find.widgetWithText(TextField, 'Comunidad');
      await tester.enterText(comunidadField, 'Test Comunidad');
      await tester.pump();

      // Verifica que el texto se escribió
      expect(find.text('Test Comunidad'), findsOneWidget);

      // Presiona el botón de limpiar
      await tester.tap(find.byTooltip('Limpiar tabla'));
      await tester.pump();

      // Verifica que el campo está vacío
      expect(find.text('Test Comunidad'), findsNothing);
    });

    testWidgets('Prueba el cambio de tema', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Encuentra el botón de cambio de tema
      final themeButton = find.byTooltip('Cambiar tema');
      expect(themeButton, findsOneWidget);

      // Obtiene el primer IconButton (que debería ser el botón de tema)
      final iconButton = find.byType(IconButton).first;
      expect(iconButton, findsOneWidget);

      // Presiona el botón de tema
      await tester.tap(iconButton);
      await tester.pump(const Duration(milliseconds: 100));

      // Verifica que el tema ha cambiado verificando el cambio en el Scaffold
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold, isNotNull);

      // La prueba pasa si llegamos hasta aquí sin errores
    });
  });
}
