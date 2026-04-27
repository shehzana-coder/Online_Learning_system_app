import 'package:flutter_test/flutter_test.dart';
import 'package:myproject/main.dart';

void main() {
  testWidgets('WelcomeScreen UI test', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the welcome text is displayed.
    expect(find.text('TeachUp'), findsOneWidget);

    // Verify that the description text is displayed.
    expect(
      find.text(
        'Discover knowledgeable tutors near you with ease. Connect with qualified educators effortlessly.',
      ),
      findsOneWidget,
    );

    // Verify that the "Log In" button is present.
    expect(find.text('Log In'), findsOneWidget);

    // Verify that the "Sign Up" button is present.
    expect(find.text('Sign Up'), findsOneWidget);

    // Tap the "Log In" button and trigger a frame.
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    // Add your expectations after tapping "Log In" here.

    // Navigate back to the welcome screen.
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Tap the "Sign Up" button and trigger a frame.
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    // Add your expectations after tapping "Sign Up" here.
  });
}
