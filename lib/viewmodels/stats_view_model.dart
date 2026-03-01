import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_stats.dart';
import '../models/time_period.dart';
import '../repositories/study_session_repository.dart';
import '../services/firestore_service.dart';

class StatsViewModel extends ChangeNotifier {
  final StudySessionRepository _sessionRepository;

  List<DailyStats> dailyStats = [];
  TimePeriod selectedPeriod = TimePeriod.week;
  bool isLoading = false;
  int totalSeconds = 0;
  double reviewCompletionRate = 0.0;

  StatsViewModel(this._sessionRepository);

  Future<void> loadStats(String userId, TimePeriod period) async {
    isLoading = true;
    selectedPeriod = period;
    notifyListeners();

    dailyStats = await _sessionRepository.getDailyStats(userId, period);
    totalSeconds = dailyStats.fold(0, (sum, s) => sum + s.totalDuration);

    final totalReviews = dailyStats.fold(0, (sum, s) => sum + s.reviewCount);
    final totalSessions = dailyStats.fold(0, (sum, s) => sum + s.sessionCount);
    reviewCompletionRate =
        totalSessions > 0 ? totalReviews / totalSessions : 0.0;

    isLoading = false;
    notifyListeners();
  }

  void changePeriod(String userId, TimePeriod period) {
    loadStats(userId, period);
  }
}

final statsViewModelProvider = ChangeNotifierProvider<StatsViewModel>((ref) {
  final firestore = FirestoreService();
  return StatsViewModel(
    StudySessionRepository(firestore),
  );
});
