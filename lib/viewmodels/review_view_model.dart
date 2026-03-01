import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/review_item.dart';
import '../repositories/review_item_repository.dart';
import '../repositories/user_repository.dart';
import '../services/firestore_service.dart';
import '../services/review_service.dart';
import '../services/reward_service.dart';

class ReviewViewModel extends ChangeNotifier {
  final ReviewService _reviewService;
  final ReviewItemRepository _reviewItemRepository;
  final RewardService _rewardService;
  final UserRepository _userRepository;

  List<ReviewItem> todayItems = [];
  bool isLoading = false;
  int completedCount = 0;

  ReviewViewModel(
    this._reviewService,
    this._reviewItemRepository,
    this._rewardService,
    this._userRepository,
  );

  Future<void> loadTodayItems(String userId) async {
    isLoading = true;
    notifyListeners();
    todayItems = await _reviewItemRepository.getTodayReviewItems(userId);
    isLoading = false;
    notifyListeners();
  }

  Future<void> processReview(
    String userId,
    ReviewItem item,
    int difficulty,
  ) async {
    final updatedItem = _reviewService.processReview(item, difficulty);
    await _reviewItemRepository.updateReviewItem(updatedItem);

    final reward = _rewardService.calculateReviewReward(1);
    await _userRepository.addExpAndCoins(userId, reward.exp, reward.coins);

    completedCount++;
    todayItems = todayItems.where((i) => i.id != item.id).toList();
    notifyListeners();
  }

  Future<void> addReviewItem(ReviewItem item) async {
    await _reviewItemRepository.saveReviewItem(item);
    todayItems = [...todayItems, item];
    notifyListeners();
  }
}

final reviewViewModelProvider = ChangeNotifierProvider<ReviewViewModel>((ref) {
  final firestore = FirestoreService();
  return ReviewViewModel(
    ReviewService(),
    ReviewItemRepository(firestore),
    RewardService(),
    UserRepository(firestore),
  );
});
