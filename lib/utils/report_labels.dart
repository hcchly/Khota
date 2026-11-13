/// Arabic labels for the image analysis results (issue class and severity).
/// Shared by the report details screen and the map marker summary.
library;

const unknownIssueClass = 'غير محدد';
const unknownSeverity = 'غير محددة';

String _key(Object? value) => value is String
    ? value.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_')
    : '';

/// "تضرر سطح الرصيف", "مشكلة في منحدر الرصيف", or [unknownIssueClass].
String issueClassLabel(Object? value) => switch (_key(value)) {
  'surface_damage' => 'تضرر سطح الرصيف',
  'curb_ramp_issue' => 'مشكلة في منحدر الرصيف',
  _ => unknownIssueClass,
};

/// True for the high-severity values used by the analysis pipeline.
bool isSevere(Object? value) => const {'high', 'severe'}.contains(_key(value));

/// "عالية", "منخفضة إلى متوسطة", or [unknownSeverity].
String severityLabel(Object? value) {
  if (isSevere(value)) return 'عالية';
  return switch (_key(value)) {
    'low_medium' ||
    'non_severe' ||
    'not_severe' ||
    'low' ||
    'medium' => 'منخفضة إلى متوسطة',
    _ => unknownSeverity,
  };
}
