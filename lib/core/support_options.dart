// owner: member 4. support activity choices and recheck date helpers.
import 'package:intl/intl.dart';

/// the support activities a teacher can pick.
/// [storageName] is saved in supportPlans.practiceType.
enum SupportActivity {
  pairedReading(
    storageName: 'paired reading',
    title: 'Paired reading',
    description: 'Read a short passage together, then let the learner try.',
  ),
  wordPractice(
    storageName: 'word practice',
    title: 'Word practice',
    description: 'Practise words the learner found difficult.',
  ),
  smallGroup(
    storageName: 'small-group reading',
    title: 'Small-group reading',
    description:
        'Use a short guided session with learners needing similar help.',
  );

  const SupportActivity({
    required this.storageName,
    required this.title,
    required this.description,
  });

  final String storageName;
  final String title;
  final String description;

  /// null if [value] is not a known activity.
  static SupportActivity? fromStorage(String value) {
    for (final a in SupportActivity.values) {
      if (a.storageName == value) return a;
    }
    return null;
  }
}

/// plan focus used when the teacher leaves the note empty.
const String defaultSupportFocus = 'General reading practice';

DateTime oneWeekFrom(DateTime from) {
  final day = DateTime(from.year, from.month, from.day);
  return day.add(const Duration(days: 7));
}

/// a recheck can be today or later, never in the past.
bool isValidRecheckDate(DateTime date, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  return !DateTime(date.year, date.month, date.day).isBefore(today);
}

String formatPlanDate(DateTime date) => DateFormat('d MMM yyyy').format(date);
