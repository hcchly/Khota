import 'dart:typed_data';

/// Photo/details handoff to the location and submission step.
/// Image bytes must be uploaded separately, never written into Firestore.
class ReportDraft {
  const ReportDraft({
    required this.imageBytes,
    this.description = '',
    this.imageUrl,
  });

  static const maxDescriptionLength = 500;
  final Uint8List imageBytes;
  final String description;
  final String? imageUrl;

  Map<String, dynamic> toFirestoreFields() => {
    'description': description.trim(),
  };
}
