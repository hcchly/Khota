// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
import 'package:flutter_test/flutter_test.dart';

import '../lib/models/app_user.dart';

void main() {
  test('AppUser.initial returns the first letter of the name', () {
    const user = AppUser(
      uid: 'test-user',
      fullName: 'Reema',
      email: 'reema@example.com',
    );

    expect(user.initial, 'R');
  });

  test('copyWith updates the name and keeps the other details', () {
    const user = AppUser(
      uid: 'test-user',
      fullName: 'Reema',
      email: 'reema@example.com',
    );

    final updated = user.copyWith(fullName: 'Reema Alshalwi');

    expect(updated.fullName, 'Reema Alshalwi');
    expect(updated.uid, user.uid);
    expect(updated.email, user.email);
  });
}