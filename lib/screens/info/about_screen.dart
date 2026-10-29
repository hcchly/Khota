
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
      appBar: const GradientAppBar(
        title: 'عن التطبيق',
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16, 28, 16, 32,
        ),

        children: [
          // New app icon: navy background and mint symbol.
          Center(
            child: Container(
              width: 156,
              height: 156,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFF173652),
                borderRadius: BorderRadius.circular(34),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(
                      alpha: 0.12,
                    ),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Transform.scale(
                  scale: 2.7,
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      AppColors.mint,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(
                      'assets/images/khota_symbol_original.png',
                      width: 156,
                      height: 156,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      semanticLabel: 'أيقونة تطبيق خُطى',
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'خُطى',
            textAlign: TextAlign.center,
            style: text.displaySmall?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'معًا لأرصفة أفضل',
            textAlign: TextAlign.center,
            style: text.titleMedium?.copyWith(
              color: AppColors.ocean,
            ),
          ),

          const SizedBox(height: 24),

          InfoCard(
            child: Text(
              'تطبيق مدني يتيح لسكان الرياض '
              'الإبلاغ بسهولة عن الأرصفة '
              'ومنحدرات الرصيف المتضررة '
              'ومتابعة معالجتها.',
              softWrap: true,
              style: text.bodyLarge?.copyWith(
                color: muted,
                height: 1.7,
              ),
            ),
          ),

          const SizedBox(height: 16),

          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مؤشر حالة الرصيف',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'درجة بصرية تُحسب من البلاغات '
                  'المكتملة في الموقع. كلما ارتفعت '
                  'الدرجة كانت الحالة أفضل، '
                  'وهي ليست ضمانًا هندسيًا للسلامة.',
                  softWrap: true,
                  style: text.bodyLarge?.copyWith(
                    color: muted,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Text(
            'مشروع تخرج – جامعة الملك سعود',
            textAlign: TextAlign.center,
            style: text.titleSmall?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'الإصدار ١٫٠٫٠',
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(
              color: muted,
            ),
          ),
        ],
      ),
    );
  }
}
