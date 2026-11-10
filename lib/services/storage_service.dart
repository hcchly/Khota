import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';

class StorageService {
  StorageService({
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  static const int maxImageBytes = 10 * 1024 * 1024;

  static bool isOwnImagePath(
    String path,
    String uid,
  ) {
    final segments = path.split('/');

    return segments.length == 3 &&
        segments[0] == 'uploads' &&
        segments[1] == uid &&
        RegExp(r'^[0-9a-f]{32}$')
            .hasMatch(segments[2]);
  }

  Future<String> uploadImage(Uint8List bytes) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError(
        'يجب تسجيل الدخول قبل رفع الصورة.',
      );
    }

    if (bytes.isEmpty ||
        bytes.length > maxImageBytes) {
      throw ArgumentError(
        'اختر صورة بحجم لا يتجاوز 10 ميجابايت.',
      );
    }

    final type = lookupMimeType(
      'image',
      headerBytes: bytes,
    );

    if (![
      'image/jpeg',
      'image/png',
      'image/webp',
    ].contains(type)) {
      throw ArgumentError(
        'استخدم صورة بصيغة JPG أو PNG أو WebP.',
      );
    }

    final random = Random.secure();

    final name = List.generate(
      16,
      (_) => random
          .nextInt(256)
          .toRadixString(16)
          .padLeft(2, '0'),
    ).join();

    final path = 'uploads/${user.uid}/$name';

    await _storage.ref(path).putData(
      bytes,
      SettableMetadata(contentType: type),
    );

    // Return a private Storage path, not a public URL.
    return path;
  }

  Future<Uint8List?> downloadImage(
    String path,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError(
        'يجب تسجيل الدخول لعرض صورة البلاغ.',
      );
    }

    if (!isOwnImagePath(path, user.uid)) {
      throw StateError(
        'لا يمكن الوصول إلى صورة البلاغ.',
      );
    }

    return _storage
        .ref(path)
        .getData(maxImageBytes);
  }
}
