import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/info_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = AppColors.indigo.withValues(alpha: 0.7);
    return Scaffold(
      appBar: const GradientAppBar(title: 'عن التطبيق'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 32),
        children: [
          Center(
            child: Container(
              width: 128,
              height: 128,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.tealLight.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Image.asset(
                'assets/images/khota_logo.png',
                semanticLabel: 'شعار خُطى',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'خُطى',
            textAlign: TextAlign.center,
            style: text.displaySmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            'معاً لأرصفة أفضل',
            textAlign: TextAlign.center,
            style: text.titleMedium?.copyWith(color: AppColors.teal),
          ),
          const SizedBox(height: 24),
          InfoCard(
            child: Text(
              'تطبيق مدني يتيح لسكان الرياض الإبلاغ بسهولة عن الأرصفة ومنحدرات الرصيف المتضررة ومتابعة معالجتها.',
              style: text.bodyLarge?.copyWith(color: muted, height: 1.7),
            ),
          ),
          const SizedBox(height: 16),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مؤشر حالة الرصيف',
                  style: text.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'درجة بصرية تُحسب من البلاغات المكتملة في الموقع. كلما ارتفعت الدرجة كانت الحالة أفضل، وهي ليست ضماناً هندسياً للسلامة.',
                  style: text.bodyLarge?.copyWith(color: muted, height: 1.7),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'مشروع تخرج – جامعة الملك سعود',
            textAlign: TextAlign.center,
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'الإصدار ١٫٠٫٠',
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}
