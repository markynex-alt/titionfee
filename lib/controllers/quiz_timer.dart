import 'dart:async';

class QuizTimer {
  int timeLeft = 8;
  Timer? _timer;

  Function(int)? onTick;
  Function()? onTimeUp;

  void start() {
    stop();
    timeLeft = 8;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      timeLeft--;

      if (onTick != null) onTick!(timeLeft);

      if (timeLeft <= 0) {
        stop();
        if (onTimeUp != null) onTimeUp!();
      }
    });
  }

  void stop() {
    _timer?.cancel();
  }

  void dispose() {
    _timer?.cancel();
  }
}
