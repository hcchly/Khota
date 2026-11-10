import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/profile_service.dart';
import '../../services/report_service.dart';
import '../../theme/app_colors.dart';
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
  ) {
    final firstDate = _createdAt(first);
    final secondDate = _createdAt(second);
    if (firstDate == null && secondDate != null) return 1;
    if (secondDate == null && firstDate != null) return -1;
    final byDate = firstDate == null ? 0 : secondDate!.compareTo(firstDate);
    return byDate == 0 ? first.id.compareTo(second.id) : byDate;
  }

  Widget _reportCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> report,
  ) {
    final data = report.data();
    final description = (data['description'] ?? '').toString().trim();
    final location = data['location'];
    final createdAt = _createdAt(report);
    final imageUrl = data['imageUrl'];
    final rawStatus =
        (data['reportStatus'] ?? data['status'] ?? '').toString();
    final reportStatus = switch (rawStatus.trim().toLowerCase()) {
      'قيد التنفيذ من الجهة المختصة' => 'in_progress',
      'completed' || 'done' || 'تم الحل' => 'resolved',
      _ => rawStatus,
    };

    return ReportSummaryCard(
      key: ValueKey(report.id),
      title: description.isEmpty ? 'بلاغ عن مشكلة في الرصيف' : description,
      locationText: location is GeoPoint
          ? '${location.latitude.toStringAsFixed(5)}، '
                '${location.longitude.toStringAsFixed(5)}'
          : 'الموقع غير متاح',
      dateText: createdAt == null
          ? 'التاريخ غير متاح'
          : MaterialLocalizations.of(context).formatCompactDate(createdAt),
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
    final muted = AppColors.indigo.withValues(alpha: 0.65);
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
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // Header: avatar, greeting, notifications.
        GradientHeader(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 32),
            child: FutureBuilder<AppUser>(
              future: _profile,
              builder: (context, snapshot) {
                final user = snapshot.data;
                return Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.teal,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        user?.initial ?? '',
                        style: text.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مرحباً،',
                            style: text.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          Text(
                            user?.fullName ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleLarge?.copyWith(
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
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                );
              },
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

        // Services.
        const _SectionTitle('الخدمات'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ServiceTile(
                icon: Icons.assignment_outlined,
                label: 'بلاغاتي',
                onTap: () => widget.onOpenTab(1),
              ),
              _ServiceTile(
                icon: Icons.map_outlined,
                label: 'خريطة خُطى',
                onTap: () => widget.onOpenTab(2),
              ),
              _ServiceTile(
                icon: Icons.menu_book_outlined,
                label: 'دليل التصوير',
                onTap: () => _open(const PhotoGuideScreen()),
              ),
              _ServiceTile(
                icon: Icons.info_outline_rounded,
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
      padding: EdgeInsets.fromLTRB(16, 0, 8, action == null ? 12 : 4),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (action != null) action!,
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.ink,
            image: brandBackground(5),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'أبلغ عن مشكلة في الرصيف',
                              style: text.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'صورة واضحة تساعد على تقييم المشكلة بدقة.',
                              style: text.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: 0.14,
                          ),
                          borderRadius:
                              BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: 0.20,
                            ),
                          ),
                        ),
                        child: const Icon(
                          Icons.tips_and_updates_outlined,
                          color: AppColors.mint,
                          size: 28,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _TipChip(
                        icon: Icons.wb_sunny_outlined,
                        label: 'إضاءة جيدة',
                      ),
                      _TipChip(
                        icon: Icons.crop_free,
                        label: 'المشكلة كاملة',
                      ),
                      _TipChip(
                        icon: Icons.straighten,
                        label: 'مسافة مناسبة',
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Text(
                        'كيف أصوّر المشكلة؟',
                        style: text.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward,
                        color: AppColors.mint,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TipChip extends StatelessWidget {
  const _TipChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: AppColors.warmWhite,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              child: Column(
                children: [
                  IconTile(icon: icon, size: 48),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
