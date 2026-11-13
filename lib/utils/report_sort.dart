/// Newest report first. Reports without a date (the server timestamp has not
/// arrived yet) go last; equal dates are ordered by ID so the list is stable.
///
/// Shared by the home "آخر البلاغات" list and the "بلاغاتي" tab.
int compareNewestFirst(
  DateTime? firstDate,
  String firstId,
  DateTime? secondDate,
  String secondId,
) {
  if (firstDate == null && secondDate != null) return 1;
  if (secondDate == null && firstDate != null) return -1;
  final byDate = firstDate == null ? 0 : secondDate!.compareTo(firstDate);
  return byDate == 0 ? firstId.compareTo(secondId) : byDate;
}
