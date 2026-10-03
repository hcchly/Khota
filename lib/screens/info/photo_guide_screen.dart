import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/info_card.dart';

class PhotoGuideScreen extends StatelessWidget {
  const PhotoGuideScreen({super.key});

  static const _tips = [
    ('صوّر المشكلة بوضوح', 'ثبّت الهاتف وتأكد من وضوح التلف.'),
    ('أظهر ما حول المشكلة', 'ضمّن الرصيف والطريق لتوضيح الموقع.'),
    ('صوّر منحدر الرصيف من الأمام', 'أظهر كامل المنحدر وحوافه.'),
    ('احمِ خصوصية الآخرين', 'تجنّب تصوير الوجوه ولوحات السيارات.'),
  ];

  static const _numbers = ['٠١', '٠٢', '٠٣', '٠٤'];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: const GradientAppBar(title: 'دليل التصوير'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          // Intro banner.
          InfoCard(
            color: AppColors.tealLight.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: Row(
              children: [
                const Icon(
                  Icons.photo_camera_outlined,
                  size: 44,
                  color: AppColors.indigo,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'صورة واضحة، تقييم أدق',
                        style: text.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'اتبع هذه الخطوات قبل إرسال بلاغك',
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.indigo.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Numbered tips.
          for (var i = 0; i < _tips.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InfoCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tips[i].$1,
                            style: text.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _tips[i].$2,
                            style: text.bodyMedium?.copyWith(
                              color: AppColors.indigo.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _numbers[i],
                      style: text.headlineSmall?.copyWith(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),

          // Good vs. bad example.
          Text(
            'مثال سريع',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ExampleCard(
                  good: true,
                  title: 'صورة جيدة',
                  subtitle: 'واضحة وتُظهر المحيط',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _ExampleCard(
                  good: false,
                  title: 'صورة غير مناسبة',
                  subtitle: 'قريبة ومهزوزة',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  const _ExampleCard({
    required this.good,
    required this.title,
    required this.subtitle,
  });

  final bool good;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InfoCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [
                    AppColors.teal.withValues(alpha: good ? 0.35 : 0.2),
                    AppColors.slate.withValues(alpha: good ? 0.6 : 0.35),
                  ],
                ),
              ),
              child: Icon(
                good ? Icons.check : Icons.close,
                size: 40,
                color: good ? AppColors.teal : AppColors.error,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(
              color: AppColors.indigo.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
