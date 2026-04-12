import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/src/app.dart';

void main() {
  testWidgets('renders dashboard shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FieldDispatchApp()));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
  });
}
