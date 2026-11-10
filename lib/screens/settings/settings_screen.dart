import 'package:flutter/material.dart';

import '../../settings/app_settings.dart';
import '../../theme/app_colors.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/info_card.dart';
import '../../widgets/brand_surface.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const GradientAppBar(title: 'الإعدادات'),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          final index = settings.textScaleIndex;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            children: [
              const BrandIntro(
                eyebrow: 'تفضيلاتك',
                title: 'خلّ خُطى على راحتك',
                description: 'اضبط حجم الخط ووضوحه لتجربة قراءة تناسبك.',
                icon: Icons.tune_rounded,
              ),
              const SizedBox(height: 20),
              InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const IconTile(
                          icon: Icons.text_fields_rounded,
                          size: 40,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'حجم الخط',
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            AppSettings.textScaleLabels[index],
                            style: text.bodyMedium?.copyWith(
                              color: AppColors.ocean,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Slider(
                      value: index.toDouble(),
                      min: 0,
                      max: (AppSettings.textScaleSteps.length - 1).toDouble(),
                      divisions: AppSettings.textScaleSteps.length - 1,
                      label: AppSettings.textScaleLabels[index],
                      semanticFormatterCallback: (v) =>
                          'حجم الخط: ${AppSettings.textScaleLabels[v.round()]}',
                      onChanged: (v) => settings.setTextScaleIndex(v.round()),
                    ),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.sand,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.mist),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'معاينة النص',
                            style: text.labelMedium?.copyWith(
                              color: AppColors.ocean,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'أرصفة أفضل تبدأ بخطوة',
                            textAlign: TextAlign.center,
                            style: text.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              InfoCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'نص عريض',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    'يساعد على إبراز الكلمات أثناء القراءة.',
                  ),
                  value: settings.boldText,
                  onChanged: settings.setBoldText,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'يتبع خُطى أيضًا إعدادات إمكانية الوصول في جهازك، '
                'مثل حجم الخط وقارئ الشاشة.',
                style: text.bodyMedium?.copyWith(
                  color: AppColors.ink.withValues(alpha: 0.68),
                  height: 1.6,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
