import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/review_item.dart';
import '../repositories/review_item_repository.dart';
import '../repositories/study_session_repository.dart';
import '../repositories/user_repository.dart';
import '../services/firestore_service.dart';

class ProgressViewModel extends ChangeNotifier {
  final StudySessionRepository _sessionRepository;
  final ReviewItemRepository _reviewItemRepository;
  final UserRepository _userRepository;

  // Weekly goal
  int weeklyGoalMinutes = 600;
  int weeklyStudiedSeconds = 0;

  // Review progress
  int weeklyReviewsNeeded = 0;
  int weeklyReviewsCompleted = 0;

  // Forgetting risk
  List<ReviewItem> dangerItems = [];
  List<ReviewItem> warningItems = [];
  List<ReviewItem> safeItems = [];

  // Heatmap
  Map<String, int> heatmapData = {};
  int currentStreak = 0;

  bool isLoading = false;

  ProgressViewModel(
    this._sessionRepository,
    this._reviewItemRepository,
    this._userRepository,
  );

  Future<void> loadProgress(String userId) async {
    isLoading = true;
    notifyListeners();

    await Future.wait([
      _loadWeeklyGoal(userId),
      _loadReviewProgress(userId),
      _loadHeatmap(userId),
    ]);

    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadWeeklyGoal(String userId) async {
    final user = await _userRepository.getUser(userId);
    if (user != null) {
      weeklyGoalMinutes = user.weeklyGoalMinutes;
    }

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek =
        DateTime(weekStart.year, weekStart.month, weekStart.day);
    final sessions =
        await _sessionRepository.getSessionsByDateRange(userId, startOfWeek, now);
    weeklyStudiedSeconds =
        sessions.fold(0, (sum, s) => sum + s.duration);
  }

  Future<void> _loadReviewProgress(String userId) async {
    final allItems = await _reviewItemRepository.getAllReviewItems(userId);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final twoDaysLater = today.add(const Duration(days: 2));

    // Forgetting risk classification
    dangerItems = [];
    warningItems = [];
    safeItems = [];

    for (final item in allItems) {
      final reviewDate = DateTime(
        item.nextReviewDate.year,
        item.nextReviewDate.month,
        item.nextReviewDate.day,
      );
      if (reviewDate.isBefore(today)) {
        dangerItems.add(item);
      } else if (reviewDate.isBefore(twoDaysLater) ||
          reviewDate.isAtSameMomentAs(today)) {
        warningItems.add(item);
      } else {
        safeItems.add(item);
      }
    }

    // Weekly review progress: items due this week
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek =
        DateTime(weekStart.year, weekStart.month, weekStart.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    weeklyReviewsNeeded = 0;
    weeklyReviewsCompleted = 0;

    for (final item in allItems) {
      final reviewDate = DateTime(
        item.nextReviewDate.year,
        item.nextReviewDate.month,
        item.nextReviewDate.day,
      );
      // Items that were due this week (before end of week)
      if (reviewDate.isBefore(endOfWeek) &&
          (reviewDate.isAfter(startOfWeek) ||
              reviewDate.isAtSameMomentAs(startOfWeek))) {
        weeklyReviewsNeeded++;
      }
    }

    // Overdue items are also "needed" this week
    weeklyReviewsNeeded += dangerItems.length;

    // Completed = items whose nextReviewDate has been pushed past this week
    // (reviewed and rescheduled), approximated by items with repetitions > 0
    // and nextReviewDate beyond this week, that were originally due this week.
    // Since we can't track exact review dates, use: needed - still pending
    final stillPending =
        dangerItems.length + warningItems.where((item) {
          final reviewDate = DateTime(
            item.nextReviewDate.year,
            item.nextReviewDate.month,
            item.nextReviewDate.day,
          );
          return reviewDate.isBefore(endOfWeek) &&
              (reviewDate.isAfter(startOfWeek) ||
                  reviewDate.isAtSameMomentAs(startOfWeek));
        }).length;
    weeklyReviewsCompleted =
        (weeklyReviewsNeeded - stillPending).clamp(0, weeklyReviewsNeeded);
  }

  Future<void> _loadHeatmap(String userId) async {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 365));
    final sessions =
        await _sessionRepository.getSessionsByDateRange(userId, from, now);

    heatmapData = {};
    for (final session in sessions) {
      heatmapData[session.date] =
          (heatmapData[session.date] ?? 0) + session.duration;
    }

    // Calculate streak
    currentStreak = 0;
    final fmt = DateFormat('yyyy-MM-dd');
    var checkDate = DateTime(now.year, now.month, now.day);

    // If no study today, start checking from yesterday
    if (!heatmapData.containsKey(fmt.format(checkDate))) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (heatmapData.containsKey(fmt.format(checkDate))) {
      currentStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
  }

  Future<void> updateWeeklyGoal(String userId, int minutes) async {
    weeklyGoalMinutes = minutes;
    notifyListeners();
    await _userRepository.updateWeeklyGoal(userId, minutes);
  }
}

final progressViewModelProvider =
    ChangeNotifierProvider<ProgressViewModel>((ref) {
  final firestore = FirestoreService();
  return ProgressViewModel(
    StudySessionRepository(firestore),
    ReviewItemRepository(firestore),
    UserRepository(firestore),
  );
});
