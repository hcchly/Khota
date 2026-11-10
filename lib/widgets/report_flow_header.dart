import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'gradient_header.dart';

class ReportFlowHeader extends StatelessWidget {
  const ReportFlowHeader({
    super.key,
    required this.title,
    required this.step,
    this.onBack,
    this.stepLabels = const ['الصورة', 'الموقع', 'المراجعة'],
  });

  final String title;
  final int step;
  final VoidCallback? onBack;
  final List<String> stepLabels;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GradientHeader(
      bottomRadius: 30,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(18, 12, 18, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (onBack != null) ...[
                  IconButton(
                    tooltip: 'رجوع',
                    onPressed: onBack,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'بلاغ جديد · خطوة $step من ${stepLabels.length}',
                        style: text.labelMedium?.copyWith(
                          color: AppColors.mint,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        title,
                        style: text.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Semantics(
              label:
                  'الخطوة $step من ${stepLabels.length}: ${stepLabels[step - 1]}',
              excludeSemantics: true,
              child: Row(
                children: [
                  for (var i = 0; i < stepLabels.length; i++) ...[
                    Expanded(
                      child: _StepSegment(
                        number: i + 1,
                        label: stepLabels[i],
                        done: i + 1 < step,
                        current: i + 1 == step,
                      ),
                    ),
                    if (i + 1 < stepLabels.length) const SizedBox(width: 7),
                  ],
                ],
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
    required this.number,
    required this.label,
    required this.done,
    required this.current,
  });

  final int number;
  final String label;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: current ? AppColors.mint : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (done)
            const Icon(Icons.check_rounded, size: 16, color: AppColors.mint)
          else
            Text(
              '$number',
              style: TextStyle(
                color: current ? AppColors.ink : Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: current ? AppColors.ink : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
