import 'package:flutter_test/flutter_test.dart';
import 'package:campusfix/core/constants/app_constants.dart';
import 'package:campusfix/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets(
    'CampusFix welcome screen renders core branding and entry options',
    (WidgetTester tester) async {
      // Build our app wrapped in ProviderScope and trigger a frame.
      await tester.pumpWidget(const ProviderScope(child: CampusFixApp()));
      await tester.pumpAndSettle();

      // Verify application branding exists
      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.text(AppConstants.appTagline), findsOneWidget);

      // Verify Student and Staff portal entry buttons exist
      expect(find.text('Student Portal'), findsOneWidget);
      expect(find.text('Staff Portal'), findsOneWidget);

      // Verify feature highlights are rendered
      expect(find.text('QR-Enabled Reporting'), findsOneWidget);
      expect(find.text('Real-Time Tracking'), findsOneWidget);
      expect(find.text('Verified Resolution'), findsOneWidget);
    },
  );
}
