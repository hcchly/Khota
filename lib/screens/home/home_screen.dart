import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/app_user.dart';
import '../../services/profile_service.dart';
import '../../services/report_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/khota_colors.dart';
import '../../utils/date_format.dart';
import '../../utils/report_sort.dart';
import '../../widgets/coming_soon.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/info_card.dart';
import '../../widgets/report_card.dart';
import '../info/about_screen.dart';
import '../info/photo_guide_screen.dart';

/// Home tab.
///
/// A new report is started only from the "بلاغ جديد" button in the centre of
/// the navigation bar, so the home screen does not repeat that action.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenTab, this.service});

  /// Switches the bottom navigation tab (1 = reports, 2 = map).
  final ValueChanged<int> onOpenTab;
  final ProfileService? service;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ProfileService _service =
      widget.service ?? FirestoreProfileService.instance;
  late final Future<AppUser> _profile = _service.getProfile();
  late final Stream<QuerySnapshot<Map<String, dynamic>>>? _reports =
      _watchOwnReports();

  Stream<QuerySnapshot<Map<String, dynamic>>>? _watchOwnReports() {
    if (Firebase.apps.isEmpty) return null;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    return FirebaseFirestore.instance
        .collection(ReportService.collection)
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  DateTime? _createdAt(QueryDocumentSnapshot<Map<String, dynamic>> report) {
    final timestamp = report.data()['createdAt'];
    return timestamp is Timestamp ? timestamp.toDate() : null;
  }

  int _newestFirst(
    QueryDocumentSnapshot<Map<String, dynamic>> first,
    QueryDocumentSnapshot<Map<String, dynamic>> second,
  ) => compareNewestFirst(
    _createdAt(first),
    first.id,
    _createdAt(second),
    second.id,
  );

  Widget _reportCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> report,
  ) {
    final data = report.data();
    final description = (data['description'] ?? '').toString().trim();
    final location = data['location'];
    final address = data['address'];
    final createdAt = _createdAt(report);
    final imageUrl = data['imageUrl'];
    final rawStatus = (data['reportStatus'] ?? data['status'] ?? '').toString();
    final reportStatus = switch (rawStatus.trim().toLowerCase()) {
      'قيد التنفيذ من الجهة المختصة' => 'in_progress',
      'completed' || 'done' || 'تم الحل' => 'resolved',
      _ => rawStatus,
    };

    return ReportSummaryCard(
      key: ValueKey(report.id),
      title: description.isEmpty ? 'بلاغ عن مشكلة في الرصيف' : description,
      // Saved place name; older reports get it looked up from the point.
      locationText: address is String ? address.trim() : '',
      latitude: location is GeoPoint ? location.latitude : null,
      longitude: location is GeoPoint ? location.longitude : null,
      dateText: createdAt == null
          ? 'التاريخ غير متاح'
          : formatArabicDate(createdAt),
      reportStatus: reportStatus,
      analysisStatus:
          (data['analysisStatus'] ?? data['imageAnalysisStatus'] ?? '')
              .toString(),
      reportNumber: ReportService.displayNumber(report.id),
      imageUrl: imageUrl is String && imageUrl.isNotEmpty ? imageUrl : null,
      onTap: () => widget.onOpenTab(1),
    );
  }

  Widget _emptyReports(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = context.khota.muted(0.65);
    return InfoCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        children: [
          const IconTile(icon: Icons.inbox_outlined, size: 56),
          const SizedBox(height: 14),
          Text(
            'لا توجد بلاغات بعد',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'اضغط «بلاغ جديد» في الأسفل لإرسال أول بلاغ، '
            'وستظهر بلاغاتك هنا.',
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: muted, height: 1.6),
          ),
        ],
      ),
    );
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Plain page background under the status bar.
      value: context.khota.pageOverlayStyle,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          GradientHeader(
            bottomRadius: 34,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(22, 16, 22, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<AppUser>(
                    future: _profile,
                    builder: (context, snapshot) {
                      final user = snapshot.data;
                      return Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: context.khota.headerBadge,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              user?.initial ?? '',
                              style: text.titleLarge?.copyWith(
                                color: context.khota.onHeaderBadge,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'أهلًا بك في خُطى',
                                  style: text.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                                Text(
                                  user?.fullName ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'الإشعارات',
                            onPressed: () => showComingSoon(context),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.1,
                              ),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.notifications_none_rounded),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'أرصفة أفضل\nتبدأ بخطوة',
                    style: text.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'بلّغ عن المشكلة، وتابع أثر خطوتك.',
                    style: text.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Photo guide card.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _GuideCard(onTap: () => _open(const PhotoGuideScreen())),
          ),
          const SizedBox(height: 28),

          // Services: one row the user slides through.
          const _SectionTitle('الخدمات'),
          SizedBox(
            height: 118,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              children: [
                _ServiceTile(
                  icon: Icons.assignment_outlined,
                  label: 'بلاغاتي',
                  onTap: () => widget.onOpenTab(1),
                ),
                _ServiceTile(
                  icon: Icons.directions_walk_rounded,
                  label: 'خريطة خُطى',
                  onTap: () => widget.onOpenTab(2),
                ),
                _ServiceTile(
                  icon: Icons.photo_camera_rounded,
                  label: 'دليل التصوير',
                  onTap: () => _open(const PhotoGuideScreen()),
                ),
                _ServiceTile(
                  icon: Icons.info_rounded,
                  label: 'عن خُطى',
                  onTap: () => _open(const AboutScreen()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          _SectionTitle(
            'آخر البلاغات',
            action: TextButton(
              onPressed: () => widget.onOpenTab(1),
              child: const Text('عرض الكل'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _reports,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const InfoCard(
                    child: Text(
                      'تعذّر تحميل آخر البلاغات.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final reports = snapshot.data?.docs.toList() ?? [];
                if (reports.isEmpty) return _emptyReports(context);
                reports.sort(_newestFirst);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final report in reports.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _reportCard(context, report),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 48), // space above the centre button
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        16,
        0,
        12,
        action == null ? 12 : 4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Short tips before taking the photo; opens the photo guide.

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.khota;
    final radius = BorderRadius.circular(24);
    return Material(
      color: colors.isDark
          ? colors.surface
          : Color.alphaBlend(
              AppColors.mint.withValues(alpha: 0.12),
              Colors.white,
            ),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: AppColors.mint.withValues(alpha: 0.45)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.photo_camera_rounded,
                  size: 26,
                  color: colors.isDark ? colors.onPrimary : Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'صورة أوضح. بلاغ أدق.',
                      style: text.titleMedium?.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'افتح دليل التصوير قبل إرسال بلاغك.',
                      style: text.bodySmall?.copyWith(
                        color: colors.muted(0.7),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_back_rounded, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.khota;
    final radius = BorderRadius.circular(18);
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 10, bottom: 6),
      child: Material(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: colors.divider),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: SizedBox(
            width: 104,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.mint.withValues(
                      alpha: colors.isDark ? 0.18 : 0.14,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: colors.primary, size: 25),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
