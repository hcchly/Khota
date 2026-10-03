import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/profile_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/coming_soon.dart';
import '../../widgets/gradient_header.dart';
import '../info/about_screen.dart';
import '../info/photo_guide_screen.dart';
import '../info/privacy_screen.dart';
import '../settings/settings_screen.dart';
import 'edit_profile_screen.dart';

/// PBI-07: As a citizen, I want to view my profile
/// so that I can review my account information.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.service});

  /// Leave empty to use the temporary fake data.
  final ProfileService? service;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileService _service =
      widget.service ?? MockProfileService.instance;
  late Future<AppUser> _profile;

  @override
  void initState() {
    super.initState();
    _profile = _service.getProfile();
  }

  void _reload() {
    setState(() {
      _profile = _service.getProfile();
    });
  }

  Future<void> _openEditProfile(AppUser user) async {
    final updated = await Navigator.of(context).push<AppUser>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(user: user, service: _service),
      ),
    );
    if (updated != null) _reload();
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<AppUser>(
        future: _profile,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _ErrorView(onRetry: _reload);
          }

          final user = snapshot.data!;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _ProfileHeader(user: user),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  children: [
                    _MenuTile(
                      icon: Icons.edit_outlined,
                      label: 'تعديل البيانات',
                      onTap: () => _openEditProfile(user),
                    ),
                    _MenuTile(
                      icon: Icons.settings_outlined,
                      label: 'الإعدادات',
                      onTap: () => _open(const SettingsScreen()),
                    ),
                    _MenuTile(
                      icon: Icons.photo_camera_outlined,
                      label: 'دليل التصوير',
                      onTap: () => _open(const PhotoGuideScreen()),
                    ),
                    _MenuTile(
                      icon: Icons.privacy_tip_outlined,
                      label: 'الخصوصية',
                      onTap: () => _open(const PrivacyScreen()),
                    ),
                    _MenuTile(
                      icon: Icons.info_outline,
                      label: 'عن التطبيق',
                      onTap: () => _open(const AboutScreen()),
                    ),
                    const SizedBox(height: 8),
                    // Log out belongs to the login/logout task.
                    _MenuTile(
                      icon: Icons.logout,
                      label: 'تسجيل الخروج',
                      color: AppColors.error,
                      onTap: () => showComingSoon(context),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GradientHeader(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          children: [
            Text(
              'حسابي',
              style: text.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            Semantics(
              label: 'الصورة الرمزية',
              child: Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 3,
                  ),
                ),
                child: Text(
                  user.initial,
                  style: text.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.fullName,
              textAlign: TextAlign.center,
              style: text.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              textDirection: TextDirection.ltr,
              style: text.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.indigo,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final iconColor = color == AppColors.error ? AppColors.error : AppColors.teal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(16),
        elevation: 0.5,
        shadowColor: AppColors.indigo.withValues(alpha: 0.2),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // In RTL the first child sits on the right.
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, semanticLabel: label),
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'تعذّر تحميل بيانات الحساب',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
