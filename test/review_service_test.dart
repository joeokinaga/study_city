import 'package:flutter_test/flutter_test.dart';
import 'package:study_city/models/review_item.dart';
import 'package:study_city/services/review_service.dart';

void main() {
  group('ReviewService', () {
    final service = ReviewService();

    // ── Helper ───────────────────────────────────────────────────────
    ReviewItem makeItem({
      int repetitions = 0,
      double easeFactor = 2.5,
      int interval = 1,
    }) =>
        ReviewItem(
          id: 'item_1',
          userId: 'user_1',
          title: 'Test Item',
          subjectId: 'subject_1',
          nextReviewDate: DateTime.now(),
          repetitions: repetitions,
          easeFactor: easeFactor,
          interval: interval,
          createdAt: DateTime.now(),
        );

    // ── Hard (q = 0) ─────────────────────────────────────────────────
    group('Hard (q=0)', () {
      test('resets repetitions to 0', () {
        final result = service.processReview(makeItem(repetitions: 5), 0);
        expect(result.repetitions, equals(0));
      });

      test('sets interval to 1 day regardless of previous interval', () {
        final result = service.processReview(makeItem(interval: 100), 0);
        expect(result.interval, equals(1));
      });

      test('next review date is approximately tomorrow', () {
        final result = service.processReview(makeItem(), 0);
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        expect(result.nextReviewDate.day, equals(tomorrow.day));
      });

      test('saves difficulty=0 on the item', () {
        final result = service.processReview(makeItem(), 0);
        expect(result.difficulty, equals(0));
      });

      test('resets a well-learned item (many repetitions) back to basics', () {
        final item = makeItem(repetitions: 20, interval: 365, easeFactor: 3.0);
        final result = service.processReview(item, 0);
        expect(result.repetitions, equals(0));
        expect(result.interval, equals(1));
      });
    });

    // ── Good (q = 3) ─────────────────────────────────────────────────
    group('Good (q=3)', () {
      test('increments repetitions by 1', () {
        final result = service.processReview(makeItem(repetitions: 2), 3);
        expect(result.repetitions, equals(3));
      });

      test('next review date is in the future', () {
        final result = service.processReview(makeItem(), 3);
        expect(result.nextReviewDate.isAfter(DateTime.now()), isTrue);
      });

      test('saves difficulty=3 on the item', () {
        final result = service.processReview(makeItem(), 3);
        expect(result.difficulty, equals(3));
      });

      test('ease factor decreases slightly after Good rating', () {
        final result = service.processReview(makeItem(easeFactor: 2.5), 3);
        expect(result.easeFactor, lessThan(2.5));
      });
    });

    // ── Easy (q = 5) ─────────────────────────────────────────────────
    group('Easy (q=5)', () {
      test('increments repetitions by 1', () {
        final result = service.processReview(makeItem(repetitions: 3), 5);
        expect(result.repetitions, equals(4));
      });

      test('ease factor increases after Easy rating', () {
        final result = service.processReview(makeItem(easeFactor: 2.5), 5);
        expect(result.easeFactor, greaterThan(2.5));
      });

      test('Easy produces a longer interval than Good for the same item', () {
        final item = makeItem(repetitions: 2, interval: 6);
        final easy = service.processReview(item, 5);
        final good = service.processReview(item, 3);
        expect(easy.interval, greaterThan(good.interval));
      });

      test('saves difficulty=5 on the item', () {
        final result = service.processReview(makeItem(), 5);
        expect(result.difficulty, equals(5));
      });
    });

    // ── Repetition stage boundaries ──────────────────────────────────
    group('repetition stage boundaries', () {
      test('first success (repetitions=0) always gives interval=1', () {
        final result = service.processReview(makeItem(repetitions: 0), 5);
        expect(result.interval, equals(1));
        expect(result.repetitions, equals(1));
      });

      test('second success (repetitions=1) gives interval=6', () {
        final result = service.processReview(makeItem(repetitions: 1, interval: 1), 5);
        expect(result.interval, equals(6));
        expect(result.repetitions, equals(2));
      });

      test('third success computes interval from previous * EF', () {
        final item = makeItem(repetitions: 2, interval: 6, easeFactor: 2.5);
        final result = service.processReview(item, 5);
        // newEF = 2.5 + 0.1 = 2.6; interval = ceil(6 * 2.6) = 16
        expect(result.interval, equals(16));
      });
    });

    // ── Full sequence ────────────────────────────────────────────────
    group('full review sequence', () {
      test('5 consecutive Easy reviews produce growing intervals', () {
        var item = makeItem();
        final intervals = <int>[];
        for (int i = 0; i < 5; i++) {
          item = service.processReview(item, 5);
          intervals.add(item.interval);
        }
        expect(intervals[0], equals(1));
        expect(intervals[1], equals(6));
        expect(intervals[2], greaterThan(6));
        expect(intervals[3], greaterThan(intervals[2]));
        expect(intervals[4], greaterThan(intervals[3]));
      });

      test('Hard after a long streak resets and restarts from zero', () {
        // Build up a good item
        var item = makeItem();
        for (int i = 0; i < 5; i++) {
          item = service.processReview(item, 5);
        }
        expect(item.repetitions, equals(5));

        // Then forget it
        item = service.processReview(item, 0);
        expect(item.repetitions, equals(0));
        expect(item.interval, equals(1));

        // Recover: first success is 1-day interval again
        item = service.processReview(item, 5);
        expect(item.interval, equals(1));
        expect(item.repetitions, equals(1));
      });
    });
  });
}
