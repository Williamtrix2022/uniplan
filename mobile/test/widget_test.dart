import 'package:flutter_test/flutter_test.dart';
import 'package:uniplan/main.dart';




void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Bienvenido a Uniplan'), findsOneWidget);
  });
}
