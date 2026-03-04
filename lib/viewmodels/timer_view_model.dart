import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/reward.dart';
import '../models/study_session.dart';
import '../models/subject.dart';
import '../repositories/study_session_repository.dart';
import '../repositories/subject_repository.dart';
import '../repositories/user_repository.dart';
import '../services/firestore_service.dart';
import '../services/reward_service.dart';
import '../services/study_timer_service.dart';

class TimerViewModel extends ChangeNotifier {
  final StudyTimerService _timerService;
  final StudySessionRepository _sessionRepository;
  final SubjectRepository _subjectRepository;
  final RewardService _rewardService;
  final UserRepository _userRepository;
  StreamSubscription<List<Subject>>? _subjectsSub;

  bool get isRunning => _timerService.isRunning;
  Duration get elapsed => _timerService.elapsed;
  Subject? selectedSubject;
  List<Subject> subjects = [];
  Reward? lastReward;

  TimerViewModel(
    this._timerService,
    this._sessionRepository,
    this._subjectRepository,
    this._rewardService,
    this._userRepository,
  );

  Future<void> loadSubjects(String userId) async {
    // Cancel existing subscription to prevent duplicates
    await _subjectsSub?.cancel();
    _subjectsSub = _subjectRepository.streamSubjects(userId).listen(
      (list) {
        subjects = list;
        // Keep selectedSubject in sync with the updated list
        if (selectedSubject != null) {
          final match = list.where((s) => s.id == selectedSubject!.id).firstOrNull;
          selectedSubject = match;
        }
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error loading subjects: $error');
      },
    );
  }

  void selectSubject(Subject subject) {
    selectedSubject = subject;
    notifyListeners();
  }

  void startTimer() {
    _timerService.start();
    notifyListeners();
  }

  Future<Reward> stopTimer(String userId) async {
    final duration = _timerService.stop();

    // Calculate reward immediately (sync) — no Firestore needed.
    final reward = _rewardService.calculateStudyReward(duration);
    lastReward = reward;
    notifyListeners();

    // Fire all Firestore writes in parallel for speed.
    final now = DateTime.now();
    final session = StudySession(
      id: '${userId}_${now.millisecondsSinceEpoch}',
      userId: userId,
      subjectId: selectedSubject?.id ?? '',
      subjectName: selectedSubject?.name ?? '',
      startTime: now.subtract(duration),
      endTime: now,
      duration: duration.inSeconds,
      date: DateFormat('yyyy-MM-dd').format(now),
    );

    await Future.wait([
      _sessionRepository.saveSession(session),
      if (selectedSubject != null)
        _subjectRepository.addStudyTime(
          userId,
          selectedSubject!.id,
          duration.inSeconds,
        ),
      _userRepository.addExpAndCoins(userId, reward.exp, reward.coins),
    ]);

    return reward;
  }

  Stream<Duration> get timerStream => _timerService.timerStream;

  @override
  void dispose() {
    _subjectsSub?.cancel();
    _timerService.dispose();
    super.dispose();
  }
}

final timerViewModelProvider = ChangeNotifierProvider<TimerViewModel>((ref) {
  final firestore = FirestoreService();
  return TimerViewModel(
    StudyTimerService(),
    StudySessionRepository(firestore),
    SubjectRepository(firestore),
    RewardService(),
    UserRepository(firestore),
  );
});
