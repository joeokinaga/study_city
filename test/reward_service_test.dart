import 'package:flutter_test/flutter_test.dart';
import 'package:study_city/services/reward_service.dart';

void main() {
  group('RewardService', () {
    final service = RewardService();

    // ----------------------------------------------------------------
    // Study session rewards
    // ----------------------------------------------------------------
    group('calculateStudyReward', () {
      test('30-minute session gives 300 EXP and 150 coins', () {
        final reward = service.calculateStudyReward(const Duration(minutes: 30));
        expect(reward.exp, equals(300));
        expect(reward.coins, equals(150));
      });

      test('1-minute session gives 10 EXP and 5 coins', () {
        final reward = service.calculateStudyReward(const Duration(minutes: 1));
        expect(reward.exp, equals(10));
        expect(reward.coins, equals(5));
      });

      test('Zero-duration session gives 0 EXP and 0 coins', () {
        final reward = service.calculateStudyReward(Duration.zero);
        expect(reward.exp, equals(0));
        expect(reward.coins, equals(0));
      });

      test('45-second session (< 1 min) gives 0 EXP and 0 coins', () {
        final reward = service.calculateStudyReward(const Duration(seconds: 45));
        expect(reward.exp, equals(0));
        expect(reward.coins, equals(0));
      });

      test('90-minute session gives 900 EXP and 450 coins', () {
        final reward = service.calculateStudyReward(const Duration(minutes: 90));
        expect(reward.exp, equals(900));
        expect(reward.coins, equals(450));
      });

      test('EXP is always exactly double the coins for study rewards', () {
        for (final minutes in [1, 5, 10, 25, 60, 120]) {
          final reward = service.calculateStudyReward(Duration(minutes: minutes));
          expect(reward.exp, equals(reward.coins * 2),
              reason: 'EXP should be 2x coins for $minutes minutes');
        }
      });
    });

    // ----------------------------------------------------------------
    // Review completion rewards
    // ----------------------------------------------------------------
    group('calculateReviewReward', () {
      test('1 review gives 20 EXP and 10 coins', () {
        final reward = service.calculateReviewReward(1);
        expect(reward.exp, equals(20));
        expect(reward.coins, equals(10));
      });

      test('5 reviews give 100 EXP and 50 coins', () {
        final reward = service.calculateReviewReward(5);
        expect(reward.exp, equals(100));
        expect(reward.coins, equals(50));
      });

      test('0 reviews give 0 EXP and 0 coins', () {
        final reward = service.calculateReviewReward(0);
        expect(reward.exp, equals(0));
        expect(reward.coins, equals(0));
      });

      test('Review EXP is always double the review coins', () {
        for (final count in [1, 3, 7, 10, 20]) {
          final reward = service.calculateReviewReward(count);
          expect(reward.exp, equals(reward.coins * 2),
              reason: 'EXP should be 2x coins for $count reviews');
        }
      });

      test('Rewards scale linearly with review count', () {
        final r1 = service.calculateReviewReward(3);
        final r2 = service.calculateReviewReward(6);
        expect(r2.exp, equals(r1.exp * 2));
        expect(r2.coins, equals(r1.coins * 2));
      });
    });
  });
}
