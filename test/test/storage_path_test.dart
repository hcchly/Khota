import 'package:flutter_test/flutter_test.dart';
import 'package:khota_app/services/storage_service.dart';

void main() {
  test(
    'Accepts only the owner private image path',
    () {
      const id = '0123456789abcdef0123456789abcdef';

      expect(
        StorageService.isOwnImagePath(
          'uploads/userA/$id',
          'userA',
        ),
        isTrue,
      );

      expect(
        StorageService.isOwnImagePath(
          'uploads/userA/$id',
          'userB',
        ),
        isFalse,
      );

      expect(
        StorageService.isOwnImagePath(
          'https://example.com/image.jpg',
          'userA',
        ),
        isFalse,
      );

      expect(
        StorageService.isOwnImagePath(
          'uploads/userA/short',
          'userA',
        ),
        isFalse,
      );
    },
  );
}
