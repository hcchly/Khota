/// The citizen's account information shown on the profile screens.
class AppUser {
  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
  });

  final String uid;
  final String fullName;
  final String email;

  /// First letter of the name, shown inside the avatar circle.
  String get initial {
    final name = fullName.trim();
    return name.isEmpty ? '؟' : name.substring(0, 1);
  }

  AppUser copyWith({String? fullName}) {
    return AppUser(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email,
    );
  }
}
