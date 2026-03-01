import '../models/review_schedule.dart';

class SM2Algorithm {
  /// Calculate next review schedule using the SuperMemo 2 algorithm.
  ///
  /// [difficulty] 0-5 rating (0=forgot, 3=normal, 5=perfect)
  /// [repetitions] number of successful reviews so far
  /// [easeFactor] current ease factor (starts at 2.5)
  /// [previousInterval] previous interval in days
  ReviewSchedule calculate(
    int difficulty,
    int repetitions,
    double easeFactor,
    int previousInterval,
  ) {
    // Step 1: Update ease factor
    // New EF = Old EF + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
    double newEF = easeFactor +
        (0.1 - (5 - difficulty) * (0.08 + (5 - difficulty) * 0.02));
    if (newEF < 1.3) newEF = 1.3;

    // Step 2: Calculate next interval
    int newInterval;

    if (difficulty < 3) {
      // Review failed — reset
      newInterval = 1;
    } else {
      // Review succeeded
      if (repetitions == 0) {
        newInterval = 1;
      } else if (repetitions == 1) {
        newInterval = 6;
      } else {
        newInterval = (previousInterval * newEF).ceil();
      }
    }

    final nextReviewDate =
        DateTime.now().add(Duration(days: newInterval));

    return ReviewSchedule(
      interval: newInterval,
      easeFactor: newEF,
      nextReviewDate: nextReviewDate,
    );
  }
}
