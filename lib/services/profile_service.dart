import '../models/app_user.dart';

/// Reads and updates the signed-in citizen's profile.
///
/// The screens only talk to this interface. When Firebase is connected,
/// add a FirestoreProfileService that implements it and pass it in,
/// without changing the screens.
abstract class ProfileService {
  Future<AppUser> getProfile();
  Future<AppUser> updateName(String fullName);
}

/// TEMPORARY fake data until login and Firebase are ready.
class MockProfileService implements ProfileService {
  MockProfileService._();
  static final MockProfileService instance = MockProfileService._();

  AppUser _user = const AppUser(
    uid: 'demo-user',
    fullName: 'محمد عبدالله الشمري',
    email: 'mohammed.alshamri@email.com',
  );

  @override
  Future<AppUser> getProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return _user;
  }

  @override
  Future<AppUser> updateName(String fullName) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _user = _user.copyWith(fullName: fullName.trim());
    return _user;
  }
}
