import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Display labels used by the report interface.
class ReportStatusLabels {
  static const analyzing = 'جارٍ تحليل الصورة';

  static const pending = 'قيد الانتظار';
  static const inProgress = 'قيد التنفيذ من الجهة المختصة';
  static const resolved = 'تم الحل';

  static const filters = ['الكل', pending, inProgress, resolved];
}

/// Shows image analysis and report progress separately.
class ReportStatusSummary extends StatelessWidget {
  const ReportStatusSummary({
    super.key,
    required this.analysisStatus,
    required this.reportStatus,
  });

  final String analysisStatus;
  final String reportStatus;

  @override
  Widget build(BuildContext context) {
    final analysis = _StatusItem(
      title: 'حالة تحليل الصورة',
      value: analysisStatus,
      icon: Icons.image_search_outlined,
    );
    final report = _StatusItem(
      title: 'حالة البلاغ',
      value: reportStatus,
      icon: Icons.assignment_outlined,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >= 288 &&
            MediaQuery.textScalerOf(context).scale(14) <= 18;
        if (columns) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: analysis),
              const SizedBox(width: 8),
              Expanded(child: report),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [analysis, const SizedBox(height: 8), report],
        );
      },
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.ocean, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(title, style: theme.textTheme.bodySmall)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Filter controls for report progress only.
class ReportStatusFilters extends StatelessWidget {
  const ReportStatusFilters({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final filter in ReportStatusLabels.filters)
          ChoiceChip(
            label: Text(filter),
            selected: selectedFilter == filter,
            backgroundColor: AppColors.warmWhite,
            selectedColor: Color.alphaBlend(
              AppColors.mint.withValues(alpha: 0.21),
              AppColors.warmWhite,
            ),
            side: BorderSide(
              color: selectedFilter == filter
                  ? AppColors.ocean.withValues(alpha: 0.38)
                  : AppColors.mist,
            ),
            onSelected: (_) => onFilterChanged(filter),
          ),
      ],
    );
  }
}
