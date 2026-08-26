import 'package:flutter_test/flutter_test.dart';
import 'package:integriscan/theme/auth_provider.dart';

void main() {
  group('AuthProvider Dispose Safety', () {
    test('methods do not throw after dispose', () async {
      final authProvider = AuthProvider();
      authProvider.dispose();

      // These should not throw after dispose
      await authProvider.login('test@test.com', '123456');
      await authProvider.register('test@test.com', '123456', 'Test Display Name');
      await authProvider.logout();
      await authProvider.forgotPassword('test@test.com');
      authProvider.clear();
    });

    test('user property accessible after dispose', () async {
      final authProvider = AuthProvider();
      await authProvider.login('test@test.com', '123456');
      expect(authProvider.user, isNotNull);
      final user = authProvider.user;
      authProvider.dispose();
      // After dispose, we can still read the user property
      expect(authProvider.user, equals(user));
    });
  });
}