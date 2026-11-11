import 'package:flutter/material.dart';

import '../reports/reports_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/khota_colors.dart';
import '../reports/new_report_screen.dart';
import '../reports/report_submitted_screen.dart';
import '../../models/submitted_report.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../map/reports_map_screen.dart';

/// The main app frame: bottom navigation bar with four tabs
/// and the "بلاغ جديد" button in the middle.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  Future<void> _openNewReport() async {
    final navigator = Navigator.of(context);
    final submitted = await navigator.push<SubmittedReport>(
      MaterialPageRoute(builder: (_) => const NewReportScreen()),
    );
    if (!mounted || submitted == null) return;
    // Confirmation screen: report number, location and next steps.
    final openReports = await navigator.push<bool>(
      MaterialPageRoute(
        builder: (_) => ReportSubmittedScreen(report: submitted),
      ),
    );
    if (!mounted) return;
    setState(() => _index = openReports == true ? 1 : 0);
  }

  void _openTab(int index) => setState(() => _index = index);

  Widget _buildTab() {
    switch (_index) {
      case 0:
        return HomeScreen(onOpenTab: _openTab);
      case 1:
        return const ReportsScreen();
      case 2:
        return const ReportsMapScreen();
      default:
        return const ProfileScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.khota;
    return Scaffold(
      body: _buildTab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _NewReportButton(onPressed: _openNewReport),
      bottomNavigationBar: BottomAppBar(
        color: colors.navBar,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: colors.isDark ? 0.5 : 0.25),
        elevation: 12,
        padding: EdgeInsets.zero,
        height: 80,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          // In RTL the first item sits on the right.
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              label: 'الرئيسية',
              selected: _index == 0,
              onTap: () => _openTab(0),
            ),
            _NavItem(
              icon: Icons.assignment_outlined,
              selectedIcon: Icons.assignment_rounded,
              label: 'البلاغات',
              selected: _index == 1,
              onTap: () => _openTab(1),
            ),
            // Space for the centre button, with its label under it.
            SizedBox(
              width: 88,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'بلاغ جديد',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
            _NavItem(
              icon: Icons.directions_walk_rounded,
              selectedIcon: Icons.directions_walk_rounded,
              label: 'الخريطة',
              selected: _index == 2,
              onTap: () => _openTab(2),
            ),
            _NavItem(
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
              label: 'حسابي',
              selected: _index == 3,
              onTap: () => _openTab(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.khota;
    final color = selected ? colors.primary : colors.muted(0.55);
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.mint.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  selected ? selectedIcon : icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewReportButton extends StatelessWidget {
  const _NewReportButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.khota;
    return Semantics(
      button: true,
      label: 'بلاغ جديد',
      excludeSemantics: true,
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colors.navBar, width: 4),
          boxShadow: [
            BoxShadow(
              color: AppColors.mint.withValues(
                alpha: colors.isDark ? 0.25 : 0.45,
              ),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              // Dark mode: the brand's solid primary green.
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colors.isDark
                    ? const [AppColors.mint, AppColors.mint]
                    : const [AppColors.mint, AppColors.greenDeep],
              ),
            ),
            child: InkWell(
              onTap: onPressed,
              child: Center(
                child: Icon(
                  Icons.photo_camera_rounded,
                  color: colors.onPrimary,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
