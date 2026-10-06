import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import 'auth_service.dart';

abstract class ProfileService {
  Future<AppUser> getProfile();
  Future<AppUser> updateName(String fullName);
}

/// Reads and updates the signed-in user's Firestore profile at users/{uid}.
class FirestoreProfileService implements ProfileService {
  FirestoreProfileService._();

  static final FirestoreProfileService instance = FirestoreProfileService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User _requireSignedInUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('سجّلي الدخول لعرض بيانات حسابك');
    }
    return user;
  }

  @override
  Future<AppUser> getProfile() async {
    final user = _requireSignedInUser();

    try {
      final document = _firestore.collection('users').doc(user.uid);
      final snapshot = await document.get();

      if (!snapshot.exists) {
        throw const AuthException('لم يتم العثور على بيانات الملف الشخصي');
      }

      final data = snapshot.data()!;
      final fullName = data['fullName'];
      final email = data['email'];

      if (fullName is! String || email is! String) {
        throw const AuthException('بيانات الملف الشخصي غير مكتملة');
      }

      return AppUser(
        uid: user.uid,
        fullName: fullName,
        email: email,
      );
    } on FirebaseException catch (error) {
      throw AuthException(_messageFor(error));
    }
  }

  @override
  Future<AppUser> updateName(String fullName) async {
    final user = _requireSignedInUser();
    final name = fullName.trim();

    if (name.isEmpty) {
      throw const AuthException('الرجاء إدخال الاسم الكامل');
    }

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'fullName': name,
      });
      await user.updateDisplayName(name);

      return AppUser(
        uid: user.uid,
        fullName: name,
        email: user.email ?? '',
      );
    } on FirebaseException catch (error) {
      throw AuthException(_messageFor(error));
    }
  }

  String _messageFor(FirebaseException error) {
    if (error.code == 'permission-denied') {
      return 'ما عندك صلاحية للوصول إلى بيانات الحساب';
    }
    if (error.code == 'unavailable') {
      return 'تعذّر الاتصال. تحققي من الإنترنت وحاولي مرة أخرى';
    }
    return 'تعذّر تحميل أو حفظ بيانات الحساب. حاولي مرة أخرى';
  }
}