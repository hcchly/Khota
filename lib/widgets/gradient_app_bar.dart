import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'brand_surface.dart';

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GradientAppBar({super.key, required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 64,
      title: Text(title),
      centerTitle: true,
      foregroundColor: Colors.white,
      backgroundColor: AppColors.gradientTop,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: Theme.of(context).textTheme.titleLarge
          ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
      flexibleSpace: const BrandSurface(
        radius: 0,
        padding: EdgeInsets.zero,
        child: SizedBox.expand(),
      ),
    );
  }
}
