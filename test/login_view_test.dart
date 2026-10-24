import 'package:aitek_task/features/auth/presentation/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sign in stays on the form until login and password are valid', (
    tester,
  ) async {
    int? submitted;
    await tester.pumpWidget(
      MaterialApp(
        home: LoginView(
          loading: false,
          onSubmit: (login, password) => submitted = login,
        ),
      ),
    );

    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text('Enter your account login.'), findsOneWidget);
    expect(submitted, isNull);

    await tester.enterText(find.byType(TextFormField).at(0), '20234561');
    await tester.enterText(find.byType(TextFormField).at(1), 'ladevi31');
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(submitted, 20234561);
  });

  testWidgets('an authorization error is shown on the sign-in screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginView(
          loading: false,
          errorMessage: 'The login or password is incorrect.',
          onSubmit: _noop,
        ),
      ),
    );
    expect(find.text('The login or password is incorrect.'), findsOneWidget);
  });
}

void _noop(int login, String password) {}
