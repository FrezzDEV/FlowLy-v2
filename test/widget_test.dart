import 'package:flutter_test/flutter_test.dart';
import 'package:flowly/app.dart';

void main() {
  testWidgets('FlowLy opens on home and navigation changes tabs', (tester) async {
    await tester.pumpWidget(const FlowLyApp());
    expect(find.text('FlowLy'), findsOneWidget);
    expect(find.text('Популярное'), findsOneWidget);
    await tester.tap(find.text('Поиск').last);
    await tester.pumpAndSettle();
    expect(find.text('Популярные жанры'), findsOneWidget);
  });
}
