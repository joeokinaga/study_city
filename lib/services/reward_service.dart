import '../models/reward.dart';

class RewardService {
  /// Calculate reward for a study session.
  /// EXP = minutes × 10, Coins = minutes × 5
  Reward calculateStudyReward(Duration studyDuration) {
    final minutes = studyDuration.inMinutes;
    return Reward(
      exp: minutes * 10,
      coins: minutes * 5,
    );
  }

  /// Calculate reward for completing reviews.
  /// Per review: EXP 20, Coins 10
  Reward calculateReviewReward(int reviewCount) {
    return Reward(
      exp: reviewCount * 20,
      coins: reviewCount * 10,
    );
  }
}
