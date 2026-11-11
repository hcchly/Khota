import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Display labels used by the report interface.
class ReportStatusLabels {
  static const analyzing = 'جارٍ تحليل الصورة';

  static const pending = 'قيد الانتظار';
  static const inProgress = 'قيد التنفيذ من الجهة المختصة';
  static const resolved = 'تم الحل';

  static const all = 'الكل';
  static const filters = [all, pending, inProgress, resolved];

  /// Short chip text; the full status stays in the report details.
  static String short(String filter) =>
      filter == inProgress ? 'قيد التنفيذ' : filter;
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

/// Filter controls for report progress only: one row of chips the user
/// slides through, each with its number of reports.
class ReportStatusFilters extends StatelessWidget {
  const ReportStatusFilters({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.counts = const {},
  });

  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  /// Number of reports per filter (filter label -> count).
  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: ReportStatusLabels.filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = ReportStatusLabels.filters[index];
          final selected = selectedFilter == filter;
          final count = counts[filter];
          final fg = selected ? Colors.white : AppColors.charcoal;
          return ChoiceChip(
            showCheckmark: false,
            selected: selected,
            onSelected: (_) => onFilterChanged(filter),
            backgroundColor: AppColors.warmWhite,
            selectedColor: AppColors.greenDeep,
            shape: StadiumBorder(
              side: BorderSide(
                color: selected ? AppColors.greenDeep : AppColors.slate,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ReportStatusLabels.short(filter),
                  style: text.bodyMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.22)
                          : AppColors.mist,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      semanticsLabel: '$count بلاغ',
                      style: text.labelMedium?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
