import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/report_draft.dart';
import '../models/report_location.dart';

/// Saves submitted reports in the `reports` collection.
///
/// A new report always starts with reportStatus `pending` and analysisStatus
/// `processing`. issueClass and severity stay null until the computer vision
/// result is stored (Release 2).
class ReportService {
  ReportService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const collection = 'reports';
  static const statusPending = 'pending';
  static const analysisProcessing = 'processing';

  /// Creates a document ID on the device, before anything is sent. Retrying
  /// with the same ID can never create a second copy of the same report.
  static String generateId() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(20, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Short reference, e.g. "AB12CD34".
  static String shortCode(String reportId) =>
      reportId.substring(0, reportId.length < 8 ? reportId.length : 8)
          .toUpperCase();

  /// Report number shown to the citizen everywhere, e.g. "KHT-AB12CD34".
  /// Use this in the report list and details too, so the numbers match.
  static String displayNumber(String reportId) => 'KHT-${shortCode(reportId)}';

  /// The exact fields written for a new report.
  static Map<String, dynamic> newReportFields({
    required String userId,
    required ReportDraft draft,
    required ReportLocation location,
  }) {
    return {
      'userId': userId,
      'imageUrl': draft.imageUrl,
      ...draft.toFirestoreFields(), // description
      'location': GeoPoint(location.latitude, location.longitude),
      'locationSource': location.source,
      'locationAccuracyMeters': location.accuracyMeters,
      'reportStatus': statusPending,
      'analysisStatus': analysisProcessing,
      'issueClass': null,
      'severity': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Saves the report under [reportId]. If an earlier attempt already reached
  /// the server (for example, the connection dropped before the reply), the
  /// existing document is kept and nothing is written twice.
  Future<void> submit(
    String reportId,
    ReportDraft draft,
    ReportLocation location,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('يجب تسجيل الدخول قبل إرسال البلاغ.');
    }
    if (draft.imageUrl == null) {
      throw StateError('ارفع صورة المشكلة قبل إرسال البلاغ.');
    }
    final ref = _firestore.collection(collection).doc(reportId);
    try {
      final existing = await ref.get(const GetOptions(source: Source.server));
      if (existing.exists) return;
    } catch (_) {
      // Not found (reading a missing document is denied) or offline: continue.
    }
    await ref.set(
      newReportFields(userId: user.uid, draft: draft, location: location),
    );
  }
}
