import 'package:flutter_test/flutter_test.dart';
import 'package:expense_buddy/main.dart';

void main() {
  testWidgets('App starts with Onboarding Screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ExpenseBuddyApp());

    // Verify that we are on the Onboarding Screen.
    expect(find.textContaining('Manage your daily'), findsOneWidget);
  });
}
