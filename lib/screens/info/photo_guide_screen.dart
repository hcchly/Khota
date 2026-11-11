import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/khota_colors.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/info_card.dart';
import '../../widgets/brand_surface.dart';

class PhotoGuideScreen extends StatelessWidget {
  const PhotoGuideScreen({super.key});

  static const _tips = [
    (
      'زاوية التصوير',
      'صوّر الرصيف من زاوية تُظهر الضرر كاملًا.',
      'angle_good.jpg',
      'angle_bad.jpg',
      'زاوية واضحة تُظهر العيب.',
      'زاوية غير مناسبة تخفي العيب.',
    ),
    (
      'المسافة المناسبة',
      'أظهر المشكلة والرصيف المحيط بها.',
      'distance_good.jpg',
      'distance_bad.jpg',
      'المشكلة والمحيط ظاهران.',
      'الصورة لا تُظهر المشكلة كاملة.',
    ),
    (
      'الإضاءة',
      'تأكد من وجود إضاءة كافية دون وهج قوي.',
      'lighting_good.jpg',
      'lighting_bad.jpg',
      'إضاءة مناسبة وتفاصيل واضحة.',
      'الإضاءة تخفي تفاصيل الضرر.',
    ),
    (
      'وضوح العيب',
      'ثبّت الهاتف وركّز على الجزء المتضرر.',
      'clarity_good.jpg',
      'clarity_bad.jpg',
      'صورة واضحة تُظهر التلف.',
      'صورة مهزوزة أو غير واضحة.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const GradientAppBar(title: 'دليل التصوير'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          const BrandIntro(
            eyebrow: 'قبل ما تصوّر',
            title: 'الصورة الواضحة\nتشرح المشكلة',
            description:
                'أظهر الضرر والرصيف المحيط به. '
                'هنا أمثلة تساعدك تختار الزاوية والمسافة المناسبة.',
            icon: Icons.camera_alt_outlined,
          ),

          const SizedBox(height: 20),

          for (var i = 0; i < _tips.length; i++) ...[
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: context.khota.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: text.titleSmall?.copyWith(
                            color: context.khota.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _tips[i].$1,
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(_tips[i].$2, style: text.bodyMedium),

                  const SizedBox(height: 16),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final good = _ExampleCard(
                        good: true,
                        imageName: _tips[i].$3,
                        subtitle: _tips[i].$5,
                      );

                      final bad = _ExampleCard(
                        good: false,
                        imageName: _tips[i].$4,
                        subtitle: _tips[i].$6,
                      );

                      if (constraints.maxWidth < 420) {
                        return Column(
                          children: [good, const SizedBox(height: 12), bad],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: good),
                          const SizedBox(width: 12),
                          Expanded(child: bad),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],

          InfoCard(
            child: Row(
              children: [
                Icon(Icons.privacy_tip_outlined, color: context.khota.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'احمِ خصوصية الآخرين: تجنّب تصوير الوجوه ولوحات السيارات.',
                    style: text.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  const _ExampleCard({
    required this.good,
    required this.imageName,
    required this.subtitle,
  });

  final bool good;
  final String imageName;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final color = good ? context.khota.primary : AppColors.error;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              children: [
                Icon(
                  good ? Icons.check_circle_outline : Icons.cancel_outlined,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    good ? 'تصوير صحيح' : 'تصوير خاطئ',
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.asset(
              'assets/images/$imageName',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: context.khota.background,
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'الصورة لم تُضف بعد',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 8),

        Text(subtitle, style: text.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }
}
