import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/khota_colors.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/brand_surface.dart';
import '../../widgets/info_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final bodyStyle = text.bodyLarge?.copyWith(
      color: context.khota.muted(0.76),
      height: 1.65,
    );

    return Scaffold(
      appBar: const GradientAppBar(title: 'عن خُطى'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          BrandSurface(
            padding: const EdgeInsets.fromLTRB(22, 32, 22, 30),
            child: Column(
              children: [
                ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    AppColors.mint,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'assets/images/khota_mark_mist.png',
                    width: 76,
                    height: 56,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'خُطى',
                  style: text.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'أرصفة أفضل تبدأ بخطوة',
                  textAlign: TextAlign.center,
                  style: text.titleMedium?.copyWith(color: AppColors.mist),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'خطوة أقرب لمدينة تمشي',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'خُطى يساعد سكان الرياض على الإبلاغ عن تضرّر الأرصفة '
                  'ومنحدراتها ومتابعة حالة بلاغاتهم.',
                  style: bodyStyle,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const IconTile(icon: Icons.insights_outlined, size: 40),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'مؤشر حالة الرصيف',
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'درجة تُحسب من البلاغات المكتملة في الموقع. '
                  'الدرجة الأعلى تشير إلى حالة أفضل للرصيف. '
                  'المؤشر تقديري، وليس ضمانًا هندسيًا للسلامة.',
                  style: bodyStyle,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'مشروع تخرج · جامعة الملك سعود',
            textAlign: TextAlign.center,
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'الإصدار ١٫٠٫٠',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: context.khota.muted(0.62)),
          ),
        ],
      ),
    );
  }
}
