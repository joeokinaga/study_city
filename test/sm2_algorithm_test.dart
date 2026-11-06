import 'package:flutter_test/flutter_test.dart';
import 'package:study_city/services/sm2_algorithm.dart';

void main() {
  group('SM2Algorithm', () {
    final sm2 = SM2Algorithm();
    const double initialEF = 2.5;
    final fixedNow = DateTime(2024, 1, 1);

    // ----------------------------------------------------------------
    // Ease factor updates
    // ----------------------------------------------------------------
    group('ease factor', () {
      test('Easy (q=5) increases ease factor by +0.1', () {
        final result = sm2.calculate(5, 2, initialEF, 6, fixedNow);
        expect(result.easeFactor, closeTo(2.6, 0.001));
      });

      test('Good (q=3) decreases ease factor by -0.14', () {
        final result = sm2.calculate(3, 2, initialEF, 6, fixedNow);
        expect(result.easeFactor, closeTo(2.36, 0.001));
      });

      test('Hard (q=0) decreases ease factor significantly', () {
        final result = sm2.calculate(0, 2, initialEF, 6, fixedNow);
        // 2.5 + (0.1 - 5*(0.08 + 5*0.02)) = 2.5 - 0.80 = 1.70
        expect(result.easeFactor, closeTo(1.70, 0.001));
      });

      test('Ease factor never drops below 1.3', () {
        final result = sm2.calculate(0, 2, 1.3, 6, fixedNow);
        expect(result.easeFactor, greaterThanOrEqualTo(1.3));
      });

      test('Multiple Hard ratings clamp at 1.3', () {
        double ef = 2.5;
        for (int i = 0; i < 10; i++) {
          final r = sm2.calculate(0, 2, ef, 6, fixedNow);
          ef = r.easeFactor;
        }
        expect(ef, closeTo(1.3, 0.001));
      });
    });

    // ----------------------------------------------------------------
    // Interval calculation
    // ----------------------------------------------------------------
    group('interval calculation', () {
      test('First successful review (repetitions=0) → interval=1', () {
        final result = sm2.calculate(5, 0, initialEF, 0, fixedNow);
        expect(result.interval, equals(1));
      });

      test('Second successful review (repetitions=1) → interval=6', () {
        final result = sm2.calculate(5, 1, initialEF, 1, fixedNow);
        expect(result.interval, equals(6));
      });

      test('Third review (repetitions=2) → interval = ceil(prev * EF)', () {
        final newEF = initialEF + 0.1; // Easy: EF' = 2.6
        final result = sm2.calculate(5, 2, initialEF, 6, fixedNow);
        final expected = (6 * newEF).ceil(); // ceil(15.6) = 16
        expect(result.interval, equals(expected));
      });

      test('Hard (q=0) resets interval to 1 regardless of previous', () {
        final result = sm2.calculate(0, 5, initialEF, 100, fixedNow);
        expect(result.interval, equals(1));
      });

      test('q=1 also resets interval (below threshold of 3)', () {
        final result = sm2.calculate(1, 3, initialEF, 30, fixedNow);
        expect(result.interval, equals(1));
      });

      test('q=2 resets interval (below threshold of 3)', () {
        final result = sm2.calculate(2, 3, initialEF, 30, fixedNow);
        expect(result.interval, equals(1));
      });

      test('q=3 is the minimum passing rating', () {
        final result = sm2.calculate(3, 1, initialEF, 1, fixedNow);
        expect(result.interval, equals(6)); // repetitions=1 path
      });
    });

    // ----------------------------------------------------------------
    // Next review date
    // ----------------------------------------------------------------
    group('next review date', () {
      test('Next review date is exactly now + interval days', () {
        // Easy (q=5), repetitions=2, prev interval=6 → interval=16
        final result = sm2.calculate(5, 2, initialEF, 6, fixedNow);
        expect(result.interval, equals(16));
        expect(result.nextReviewDate, equals(DateTime(2024, 1, 17)));
      });

      test('Hard (q=0) resets to tomorrow', () {
        final result = sm2.calculate(0, 5, initialEF, 100, fixedNow);
        expect(result.nextReviewDate, equals(DateTime(2024, 1, 2)));
      });
    });

    // ----------------------------------------------------------------
    // Simulated review sequence
    // ----------------------------------------------------------------
    group('full review sequence', () {
      test('Easy-rated item intervals grow over successive reviews', () {
        double ef = 2.5;
        int interval = 0;
        int repetitions = 0;
        final intervals = <int>[];

        for (int i = 0; i < 5; i++) {
          final result = sm2.calculate(5, repetitions, ef, interval, fixedNow);
          intervals.add(result.interval);
          ef = result.easeFactor;
          interval = result.interval;
          repetitions++;
        }

        // Expected: 1, 6, then growing by factor ~2.6
        expect(intervals[0], equals(1));
        expect(intervals[1], equals(6));
        expect(intervals[2], greaterThan(intervals[1]));
        expect(intervals[3], greaterThan(intervals[2]));
        expect(intervals[4], greaterThan(intervals[3]));
      });

      test('Hard after long interval resets to 1', () {
        final result = sm2.calculate(0, 10, 2.8, 200, fixedNow);
        expect(result.interval, equals(1));
      });
    });
  });
}
