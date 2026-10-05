import '../models/app_user.dart';

/// Error with a message that can be shown to the user.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Sign in, create an account and sign out.
///
/// The screens only use this interface. When Firebase is connected,
/// add a FirebaseAuthService that implements it, and map Firebase error
/// codes to the same Arabic messages:
///   email-already-in-use      -> 'البريد الإلكتروني مسجل مسبقاً'
///   invalid-credential / wrong-password / user-not-found
///                             -> 'البريد الإلكتروني أو كلمة المرور غير صحيحة'
///   weak-password             -> 'كلمة المرور يجب أن تكون ٨ أحرف على الأقل'
///   invalid-email             -> 'صيغة البريد الإلكتروني غير صحيحة'
abstract class AuthService {
  AppUser? get currentUser;
  Future<AppUser> signIn({required String email, required String password});
  Future<AppUser> register({
    required String fullName,
    required String email,
    required String password,
  });
  Future<void> signOut();
}

/// TEMPORARY in-memory accounts until Firebase is connected.
/// Test account: test@khota.sa / 12345678
class MockAuthService implements AuthService {
  MockAuthService._();
  static final MockAuthService instance = MockAuthService._();

  final Map<String, ({String password, AppUser user})> _accounts = {
    'test@khota.sa': (
      password: '12345678',
      user: const AppUser(
        uid: 'demo-user',
        fullName: 'محمد عبدالله الشمري',
        email: 'test@khota.sa',
      ),
    ),
  };

  AppUser? _currentUser;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.password != password) {
      throw const AuthException('البريد الإلكتروني أو كلمة المرور غير صحيحة');
    }
    _currentUser = account.user;
    return account.user;
  }

  @override
  Future<AppUser> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      throw const AuthException('البريد الإلكتروني مسجل مسبقاً');
    }
    final user = AppUser(
      uid: 'user-${_accounts.length + 1}',
      fullName: fullName.trim(),
      email: key,
    );
    _accounts[key] = (password: password, user: user);
    _currentUser = user;
    return user;
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
  }

  /// Used by the mock profile service to save a new name.
  void updateCurrentUser(AppUser user) {
    _currentUser = user;
    final account = _accounts[user.email];
    if (account != null) {
      _accounts[user.email] = (password: account.password, user: user);
    }
  }
}
