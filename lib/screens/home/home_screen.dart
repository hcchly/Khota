import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/profile_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/coming_soon.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/info_card.dart';
import '../info/photo_guide_screen.dart';

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
      widget.service ?? MockProfileService.instance;
  late final Future<AppUser> _profile = _service.getProfile();

  void _openPhotoGuide() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PhotoGuideScreen()),
    );
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
            child: FutureBuilder<AppUser>(
              future: _profile,
              builder: (context, snapshot) {
                final user = snapshot.data;
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.teal,
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
                        Icons.notifications_none,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Report card.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _ReportCard(
            onReport: () => showComingSoon(context),
            onHowTo: _openPhotoGuide,
          ),
        ),
        const SizedBox(height: 28),

        // Services grid.
        _SectionTitle('الخدمات'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _ServiceTile(
                icon: Icons.add,
                label: 'بلاغ جديد',
                onTap: () => showComingSoon(context),
              ),
              _ServiceTile(
                icon: Icons.format_list_bulleted,
                label: 'بلاغاتي',
                onTap: () => widget.onOpenTab(1),
              ),
              _ServiceTile(
                icon: Icons.directions_walk,
                label: 'خريطة خُطى',
                onTap: () => widget.onOpenTab(2),
              ),
              _ServiceTile(
                icon: Icons.photo_camera_outlined,
                label: 'دليل التصوير',
                onTap: _openPhotoGuide,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Latest reports: available when report submission is built.
        _SectionTitle('آخر البلاغات'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: InfoCard(
            child: Column(
              children: [
                const IconTile(icon: Icons.inbox_outlined, size: 56),
                const SizedBox(height: 12),
                Text(
                  'لا توجد بلاغات بعد',
                  style: text.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'ستظهر بلاغاتك هنا بعد إرسالها.',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.indigo.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40), // space above the center button
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.onReport, required this.onHowTo});

  final VoidCallback onReport;
  final VoidCallback onHowTo;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Material(
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.indigo, AppColors.teal],
            ),
          ),
          child: InkWell(
            onTap: onReport,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'أبلغ عن مشكلة في الرصيف',
                          style: text.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ساعدنا في تحسين البنية التحتية',
                          style: text.bodyMedium
                              ?.copyWith(color: AppColors.tealLight),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: onHowTo,
                          child: Text(
                            'كيف أصوّر المشكلة؟',
                            style: text.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.photo_camera_outlined,
                      color: Colors.white,
                      size: 32,
                      semanticLabel: 'بلاغ جديد',
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
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
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
