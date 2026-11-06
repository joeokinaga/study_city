import '../models/review_item.dart';
import 'sm2_algorithm.dart';

class ReviewService {
  final SM2Algorithm _sm2 = SM2Algorithm();

  /// Process a review and return the updated ReviewItem.
  ReviewItem processReview(ReviewItem item, int difficulty) {
    final schedule = _sm2.calculate(
      difficulty,
      item.repetitions,
      item.easeFactor,
      item.interval,
      DateTime.now(),
    );

    return item.copyWith(
      difficulty: difficulty,
      interval: schedule.interval,
      easeFactor: schedule.easeFactor,
      repetitions: difficulty < 3 ? 0 : item.repetitions + 1,
      nextReviewDate: schedule.nextReviewDate,
    );
  }
}
