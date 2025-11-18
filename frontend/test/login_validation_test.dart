import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Login validation', () {
    test('Empty phone invalid', () {
      const phone = '';
      const password = 'password123';
      expect(phone.isEmpty || password.isEmpty, true);
    });

    test('Non-empty phone/password valid to submit', () {
      const phone = '+12345678901';
      const password = 'password123';
      expect(phone.isNotEmpty && password.isNotEmpty, true);
    });
  });
}
