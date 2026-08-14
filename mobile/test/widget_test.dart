// ============================================
// TESTS: widget_test.dart (smoke test de MyApp)
// ============================================
// Antes: este archivo era boilerplate de `flutter create` que buscaba
// 'Bienvenido a Uniplan' — un texto eliminado por el rediseño de auth.
// Eso rompía `flutter test` con una falla que no probaba nada real.
//
// Ahora: smoke test mínimo que verifica SOLO que `MyApp()` se monta sin
// lanzar excepciones. La cobertura real de cada provider vive en sus tests
// específicos (p. ej. `test/providers/notification_provider_test.dart`),
// donde se inyectan servicios fake y no se monta toda la app.
//
// Notas técnicas:
//   * Usamos `pump()` (no `pumpAndSettle`) para no chocar con la animación
//     ni con la navegación diferida.
//   * Drenamos los timers del `SplashScreen` (2500 ms `Future.delayed`)
//     con `tester.pump(Duration(...))`, así la navegación a `LoginScreen`
//     ocurre dentro del test y el widget tree se desmonta limpio.
//   * Usamos `WidgetTester.runAsync` con `fakeAsync`-like helper de Flutter
//     (pump + duration simulado) para evitar 'Timer is still pending'.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uniplan/main.dart';

void main() {
  testWidgets('MyApp() se monta sin lanzar excepciones', (WidgetTester tester) async {
    // Montamos la app y capturamos el frame inicial.
    await tester.pumpWidget(const MyApp());
    // Una sola frame basta para confirmar que el árbol inicial se compone.
    expect(tester.takeException(), isNull);
    // La home actual es SplashScreen: basta con que haya algún Scaffold.
    expect(find.byType(Scaffold), findsWidgets);

    // Drenamos el Timer que el SplashScreen programa para navegar al login.
    // Sin esto, el test termina con un Timer pendiente y `_verifyInvariants`
    // falla con: 'A Timer is still pending even after the widget tree was disposed'.
    await tester.pump(const Duration(seconds: 3));
    // Permitimos que cualquier microtask aplazado por la navegación se asiente.
    await tester.pump();
  });
}
