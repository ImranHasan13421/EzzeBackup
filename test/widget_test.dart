import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ezze_backup/app.dart';

void main() {
  testWidgets('Ezze Backup App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: EzzeBackupApp(),
      ),
    );

    // Initial frames
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify app title and feature cards
    expect(find.text('Ezze Backup'), findsOneWidget);
    expect(find.text('File Backup'), findsOneWidget);
    expect(find.text('Contact Backup'), findsOneWidget);
    expect(find.text('Backup Location'), findsOneWidget);
  });
}
