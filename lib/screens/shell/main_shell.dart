import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/coming_soon.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import 'placeholder_tab.dart';

/// The main app frame: bottom navigation bar with four tabs
/// and the "بلاغ جديد" button in the middle.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _openTab(int index) => setState(() => _index = index);

  Widget _buildTab() {
    switch (_index) {
      case 0:
        return HomeScreen(onOpenTab: _openTab);
      case 1:
        return const PlaceholderTab(
          title: 'بلاغاتي',
          icon: Icons.format_list_bulleted,
          message: 'ستظهر هنا بلاغاتك وحالة كل بلاغ.',
        );
      case 2:
        return const PlaceholderTab(
          title: 'خُطى',
          icon: Icons.directions_walk,
          message: 'ستظهر هنا خريطة البلاغات في الرياض.',
        );
      default:
        return const ProfileScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildTab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _NewReportButton(
        onPressed: () => showComingSoon(context),
      ),
      bottomNavigationBar: BottomAppBar(
        color: AppColors.warmWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        padding: EdgeInsets.zero,
        height: 72,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          // In RTL the first item sits on the right.
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: 'الرئيسية',
              selected: _index == 0,
              onTap: () => _openTab(0),
            ),
            _NavItem(
              icon: Icons.format_list_bulleted,
              selectedIcon: Icons.format_list_bulleted,
              label: 'البلاغات',
              selected: _index == 1,
              onTap: () => _openTab(1),
            ),
            const SizedBox(width: 88), // space for the center button
            _NavItem(
              icon: Icons.directions_walk,
              selectedIcon: Icons.directions_walk,
              label: 'خُطى',
              selected: _index == 2,
              onTap: () => _openTab(2),
            ),
            _NavItem(
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
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
    final color =
        selected ? AppColors.teal : AppColors.indigo.withValues(alpha: 0.45);
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
              Icon(selected ? selectedIcon : icon, color: color, size: 26),
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
    return SizedBox(
      width: 76,
      height: 76,
      child: FloatingActionButton(
        onPressed: onPressed,
        tooltip: 'بلاغ جديد',
        backgroundColor: AppColors.indigo,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.warmWhite, width: 4),
        ),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: FittedBox(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.photo_camera_outlined, size: 28),
                SizedBox(height: 2),
                Text(
                  'بلاغ جديد',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
