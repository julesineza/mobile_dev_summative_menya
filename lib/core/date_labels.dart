import 'package:intl/intl.dart';

/// Short label for when a quick check happened, e.g. "Today, 8:30 AM".
/// [now] can be passed in for testing.
String checkTimeLabel(DateTime when, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final day = DateTime(when.year, when.month, when.day);
  final daysAgo = today.difference(day).inDays;

  if (daysAgo == 0) return 'Today, ${DateFormat('h:mm a').format(when)}';
  if (daysAgo == 1) return 'Yesterday';
  return DateFormat('MMM d').format(when);
}
