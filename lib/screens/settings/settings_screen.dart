import 'package:flutter/material.dart';

import '../../settings/app_settings.dart';
import '../../theme/app_colors.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/info_card.dart';

/// Accessibility settings (supports the Accessibility NFR).
/// Map and notification settings will be added with those features.
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
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12, right: 4),
                child: Text(
                  'إمكانية الوصول',
                  style: text.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Font size.
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'حجم الخط',
                            style: text.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          AppSettings.textScaleLabels[index],
                          style: text.bodyMedium
                              ?.copyWith(color: AppColors.teal),
                        ),
                      ],
                    ),
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
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.sand,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'معاً لأرصفة أفضل وأكثر أماناً',
                        textAlign: TextAlign.center,
                        style: text.titleMedium,
                      ),
                    ),
                    const Divider(height: 32, color: AppColors.slate),

                    // Bold text.
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'نص عريض',
                        style: text.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      value: settings.boldText,
                      onChanged: settings.setBoldText,
                    ),
                    const SizedBox(height: 8),

                    // Note.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.tealLight.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'يتبع التطبيق أيضاً إعدادات إمكانية الوصول في جهازك، مثل حجم الخط وقارئ الشاشة.',
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.indigo.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
