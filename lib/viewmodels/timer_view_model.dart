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
    _subjectRepository.streamSubjects(userId).listen((list) {
      subjects = list;
      notifyListeners();
    });
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
    notifyListeners();

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

    await _sessionRepository.saveSession(session);

    if (selectedSubject != null) {
      await _subjectRepository.addStudyTime(
        userId,
        selectedSubject!.id,
        duration.inSeconds,
      );
    }

    final reward = _rewardService.calculateStudyReward(duration);
    await _userRepository.addExpAndCoins(userId, reward.exp, reward.coins);

    lastReward = reward;
    notifyListeners();
    return reward;
  }

  Stream<Duration> get timerStream => _timerService.timerStream;

  @override
  void dispose() {
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
