import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'gradient_header.dart';

/// Header of the new-report flow: back button, title and a 3-step indicator
/// (الصورة · الموقع · المراجعة).
class ReportFlowHeader extends StatelessWidget {
  const ReportFlowHeader({
    super.key,
    required this.title,
    required this.step,
    this.onBack,
    this.stepLabels = const ['الصورة', 'الموقع', 'المراجعة'],
  });

  final String title;

  /// Current step, starting at 1.
  final int step;

  /// Back button action; hidden when null.
  final VoidCallback? onBack;
  final List<String> stepLabels;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final total = stepLabels.length;
    return GradientHeader(
      bottomRadius: 24,
      pattern: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 18),
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: onBack == null
                        ? null
                        : IconButton(
                            tooltip: 'رجوع',
                            onPressed: onBack,
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: text.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Semantics(
              label: 'الخطوة $step من $total: ${stepLabels[step - 1]}',
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    for (var i = 1; i <= total; i++) ...[
                      Expanded(
                        child: _StepSegment(
                          label: stepLabels[i - 1],
                          done: i < step,
                          current: i == step,
                        ),
                      ),
                      if (i < total) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepSegment extends StatelessWidget {
  const _StepSegment({
    required this.label,
    required this.done,
    required this.current,
  });

  final String label;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final active = done || current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 5,
          decoration: BoxDecoration(
            color: active
                ? AppColors.tealLight
                : Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (done)
              const Padding(
                padding: EdgeInsetsDirectional.only(end: 4),
                child: Icon(
                  Icons.check_circle,
                  size: 14,
                  color: AppColors.tealLight,
                ),
              ),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: active ? 1 : 0.6),
                  fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
