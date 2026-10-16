
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Display labels used by the report interface.
class ReportStatusLabels {
  static const analyzing = 'جارٍ تحليل الصورة';

  static const pending = 'قيد الانتظار';
  static const inProgress = 'قيد التنفيذ من الجهة المختصة';
  static const resolved = 'تم الحل';

  static const filters = [
    'الكل',
    pending,
    inProgress,
    resolved,
  ];
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusItem(
          title: 'حالة تحليل الصورة',
          value: analysisStatus,
          icon: Icons.image_search_outlined,
        ),
        const SizedBox(height: 16),
        _StatusItem(
          title: 'حالة البلاغ',
          value: reportStatus,
          icon: Icons.assignment_outlined,
        ),
      ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(icon, color: AppColors.teal, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
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
            onSelected: (_) => onFilterChanged(filter),
          ),
      ],
    );
  }
}
