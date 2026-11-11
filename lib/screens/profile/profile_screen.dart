import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/khota_colors.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/info_card.dart';
import '../auth/login_screen.dart';
import '../info/about_screen.dart';
import '../info/photo_guide_screen.dart';
import '../info/privacy_screen.dart';
import '../settings/settings_screen.dart';
import 'edit_profile_screen.dart';

/// PBI-07: As a citizen, I want to view my profile
/// so that I can review my account information.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.service});

  /// Optional override for tests. The app uses Firestore by default.
  final ProfileService? service;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileService _service =
      widget.service ?? FirestoreProfileService.instance;
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

  /// PBI-06: log out, end the session and return to the login screen.
  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.khota.surface,
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج من حسابك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await FirebaseAuthService.instance.signOut();
    if (!mounted) return;

    // Remove every screen so the user cannot go back without logging in.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Plain page background under the status bar.
      value: context.khota.pageOverlayStyle,
      child: Scaffold(
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
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'الحساب',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      _MenuTile(
                        icon: Icons.manage_accounts_outlined,
                        label: 'تعديل البيانات',
                        onTap: () => _openEditProfile(user),
                      ),
                      _MenuTile(
                        icon: Icons.settings_outlined,
                        label: 'الإعدادات',
                        onTap: () => _open(const SettingsScreen()),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'المساعدة والمعلومات',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
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
                      _MenuTile(
                        icon: Icons.logout,
                        label: 'تسجيل الخروج',
                        color: AppColors.error,
                        onTap: _confirmLogout,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
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
        padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 20, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'حسابي',
              style: text.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Semantics(
                  label: 'الصورة الرمزية',
                  child: Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.khota.headerBadge,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.7),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      user.initial,
                      style: text.headlineSmall?.copyWith(
                        color: context.khota.onHeaderBadge,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: text.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        textDirection: TextDirection.ltr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium?.copyWith(color: AppColors.mist),
                      ),
                    ],
                  ),
                ),
              ],
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
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Label colour; the theme's text colour when null.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.khota.text;
    final iconColor = color == AppColors.error
        ? AppColors.error
        : context.khota.primary;

    final radius = BorderRadius.circular(16);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: context.khota.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: context.khota.divider),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                IconTile(icon: icon, color: iconColor, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: color, fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(Icons.chevron_left_rounded, color: iconColor, size: 22),
              ],
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
