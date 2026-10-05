import '../models/app_user.dart';
import 'auth_service.dart';

/// Reads and updates the signed-in citizen's profile.
///
/// The screens only talk to this interface. When Firebase is connected,
/// add a FirestoreProfileService that reads and writes users/{uid}.
abstract class ProfileService {
  Future<AppUser> getProfile();
  Future<AppUser> updateName(String fullName);
}

/// TEMPORARY: uses the signed-in account from MockAuthService.
class MockProfileService implements ProfileService {
  MockProfileService._();
  static final MockProfileService instance = MockProfileService._();

  final MockAuthService _auth = MockAuthService.instance;

  @override
  Future<AppUser> getProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final user = _auth.currentUser;
    if (user == null) throw const AuthException('لم يتم تسجيل الدخول');
    return user;
  }

  @override
  Future<AppUser> updateName(String fullName) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final user = _auth.currentUser;
    if (user == null) throw const AuthException('لم يتم تسجيل الدخول');
    final updated = user.copyWith(fullName: fullName.trim());
    _auth.updateCurrentUser(updated);
    return updated;
  }
}
