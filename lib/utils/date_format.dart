/// One date format for the whole app, e.g. "10 نوفمبر 2026".
const _arabicMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

String formatArabicDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day} ${_arabicMonths[local.month - 1]} ${local.year}';
}
