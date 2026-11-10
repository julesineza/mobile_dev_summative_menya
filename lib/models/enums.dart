enum Subject { reading, math }

/// Only English is enabled in the UI for now; the field exists so Kinyarwanda/French can be added later.
enum Language { english, kinyarwanda, french }

/// 1 = Struggling, 2 = Developing, 3 = Proficient (the rubric selector in the UI)
enum ResponseLevel {
  struggling(1),
  developing(2),
  proficient(3);

  const ResponseLevel(this.value);
  final int value;
  static ResponseLevel fromValue(int v) =>
      ResponseLevel.values.firstWhere((e) => e.value == v);
}

enum SupportStatus { onTrack, watch, needsSupport }

enum SessionStatus { inProgress, paused, completed }

enum PlanStatus { active, rechecked, closed }

enum EnrollmentStatus { active, exited }
