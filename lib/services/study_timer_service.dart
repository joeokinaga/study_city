import 'dart:async';

class StudyTimerService {
  DateTime? _startTime;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  final _controller = StreamController<Duration>.broadcast();

  bool get isRunning => _timer != null;

  Duration get elapsed {
    if (_startTime != null) {
      return DateTime.now().difference(_startTime!);
    }
    return _elapsed;
  }

  Stream<Duration> get timerStream => _controller.stream;

  void start() {
    if (isRunning) return;
    _startTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _controller.add(elapsed);
    });
  }

  Duration stop() {
    _elapsed = elapsed;
    _timer?.cancel();
    _timer = null;
    _startTime = null;
    return _elapsed;
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
