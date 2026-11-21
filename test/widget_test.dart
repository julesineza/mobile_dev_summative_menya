import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_dev_summative_menya/main.dart';

void main() {
  testWidgets('shows the assessment start screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('New Assessment'), findsOneWidget);
    expect(find.text('Soma (Reading)'), findsOneWidget);
    expect(find.text('Imibare (Mathematics)'), findsOneWidget);
  });
}
