import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

/// Error with a message that can be shown to the user.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Sign in, create an account and sign out.
abstract class AuthService {
  AppUser? get currentUser;

  Future<AppUser> signIn({
    required String email,
    required String password,
  });

  Future<AppUser> register({
    required String fullName,
    required String email,
    required String password,
  });

  Future<void> signOut();
}

/// Temporary in-memory accounts.
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

class FirebaseAuthService implements AuthService {
  FirebaseAuthService._();

  static final FirebaseAuthService instance = FirebaseAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppUser? _toAppUser(User? user) {
    if (user == null) return null;

    return AppUser(
      uid: user.uid,
      fullName: user.displayName ?? '',
      email: user.email ?? '',
    );
  }

  @override
  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      return _toAppUser(result.user)!;
    } on FirebaseAuthException catch (error) {
      throw AuthException(_messageFor(error.code));
    }
  }

  @override
  Future<AppUser> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final name = fullName.trim();
      final normalizedEmail = email.trim().toLowerCase();

      final result = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = result.user!;

      await user.updateDisplayName(name);

      await _firestore.collection('users').doc(user.uid).set({
        'fullName': name,
        'email': normalizedEmail,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return AppUser(
        uid: user.uid,
        fullName: name,
        email: normalizedEmail,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthException(_messageFor(error.code));
    } on FirebaseException {
      throw const AuthException('تعذّر حفظ بيانات الحساب. حاولي مرة أخرى');
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  String _messageFor(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'البريد الإلكتروني مسجل مسبقاً';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      case 'weak-password':
        return 'كلمة المرور يجب أن تكون ٨ أحرف على الأقل';
      case 'invalid-email':
        return 'صيغة البريد الإلكتروني غير صحيحة';
      default:
        return 'تعذّر تسجيل الدخول. حاولي مرة أخرى';
    }
  }
}