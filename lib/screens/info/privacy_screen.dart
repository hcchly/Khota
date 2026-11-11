import 'package:flutter/material.dart';

import '../../theme/khota_colors.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/info_card.dart';
import '../../widgets/brand_surface.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'الخصوصية'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          const BrandIntro(
            eyebrow: 'خصوصية ووضوح',
            title: 'بلاغك في أيدٍ أمينة',
            description:
                'نعرض بيانات المشكلة اللازمة على الخريطة، '
                'ونحمي صور بلاغك وبيانات حسابك.',
            icon: Icons.shield_outlined,
          ),
          const SizedBox(height: 16),
          const _PrivacyItem(
            icon: Icons.photo_library_outlined,
            title: 'صورك ليست عامة',
            body: 'لا تُعرض الصور التي ترسلها للعامة أو لمستخدمي التطبيق الآخرين.',
          ),
          const _PrivacyItem(
            icon: Icons.lock_outline,
            title: 'وصول محمي',
            body: 'لا يمكن الوصول إلى البلاغات إلا من قبل المستخدمين المصرّح لهم.',
          ),
          const _PrivacyItem(
            icon: Icons.location_on_outlined,
            title: 'استخدام الموقع',
            body: 'يُستخدم موقعك فقط لوضع البلاغ على الخريطة وتوجيهه للجهة المعنية.',
          ),
        ],
      ),
    );
  }
}

class _PrivacyItem extends StatelessWidget {
  const _PrivacyItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InfoCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile(icon: icon, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: text.bodyMedium?.copyWith(
                      color: context.khota.muted(0.7),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
