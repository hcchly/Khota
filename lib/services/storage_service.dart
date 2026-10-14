import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';

/// Standalone Storage integration; never creates or changes Firestore documents.
/// Call explicitly with the approved photo bytes when upload is needed.
class StorageService {
  StorageService({FirebaseStorage? storage, FirebaseAuth? auth})
    : _storage = storage ?? FirebaseStorage.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  Future<String> uploadImage(Uint8List bytes) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('يجب تسجيل الدخول قبل رفع الصورة.');
    }
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw ArgumentError('اختر صورة بحجم لا يتجاوز 10 ميجابايت.');
    }
    final type = lookupMimeType('image', headerBytes: bytes);
    if (!['image/jpeg', 'image/png', 'image/webp'].contains(type)) {
      throw ArgumentError('استخدم صورة بصيغة JPG أو PNG أو WebP.');
    }
    final random = Random.secure();
    final name = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final reference = _storage.ref('uploads/${user.uid}/$name');
    await reference.putData(bytes, SettableMetadata(contentType: type));
    return reference.getDownloadURL();
  }
}
