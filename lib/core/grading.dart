import '../models/enums.dart';

/// Automatic grading. The teacher still makes the final 1-2-3 choice.
/// !! The cutoffs below are PLACEHOLDERS. Replace with the REB/LEGRA benchmarks for each grade.
class Grading {
  static const double proficientCutoff = 90; // percent
  static const double developingCutoff = 70; // percent

  static ResponseLevel levelFromPercent(double percent) {
    if (percent >= proficientCutoff) return ResponseLevel.proficient;
    if (percent >= developingCutoff) return ResponseLevel.developing;
    return ResponseLevel.struggling;
  }

  /// accuracy = correct words / words in passage * 100
  static double readingAccuracy({required int wordsInPassage, required int errors}) {
    if (wordsInPassage == 0) return 0;
    final correct = (wordsInPassage - errors).clamp(0, wordsInPassage);
    return correct / wordsInPassage * 100;
  }

  /// words correct per minute
  static double wordsPerMinute({required int wordsInPassage, required int errors, required int seconds}) {
    if (seconds == 0) return 0;
    final correct = (wordsInPassage - errors).clamp(0, wordsInPassage);
    return correct / (seconds / 60);
  }

  static double mathPercent({required int itemsCorrect, required int itemsTotal}) =>
      itemsTotal == 0 ? 0 : itemsCorrect / itemsTotal * 100;

  /// What the roster/progress screens show after each graded result.
  static SupportStatus statusFromLevel(ResponseLevel level) => switch (level) {
        ResponseLevel.struggling => SupportStatus.needsSupport,
        ResponseLevel.developing => SupportStatus.watch,
        ResponseLevel.proficient => SupportStatus.onTrack,
      };
}
