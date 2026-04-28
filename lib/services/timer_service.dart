import 'dart:async';
import 'package:flutter/material.dart';

class TimerModel extends ChangeNotifier {
  Timer? _timer;

  int _memorySeconds = 60; 
  int secondsRemaining = 60;
  bool isRunning = false;
  final int maxSeconds = 300;

  void toggleTimer({required VoidCallback onFinished}) {
    if (isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (secondsRemaining > 0) {
          secondsRemaining--;
          notifyListeners();
        } else {
          _timer?.cancel();
          isRunning = false;
          notifyListeners();
          onFinished();
        }
      });
    }
    isRunning = !isRunning;
    notifyListeners();
  }

 

  void reset() {
    _timer?.cancel();
    isRunning = false;
  
    secondsRemaining = _memorySeconds;
    notifyListeners();
    debugPrint("Timer Reset to: $_memorySeconds");
  }

  void setPreset(int seconds) {
    _timer?.cancel();
    isRunning = false;
    _memorySeconds = seconds; 
    secondsRemaining = seconds; 
    notifyListeners();
    debugPrint("New Preset Set: $seconds");
  }

  void jumpToZero() {
    _timer?.cancel();
    isRunning = false;
    secondsRemaining = 0; 
    notifyListeners();
  }

  String get formattedTime {
    int minutes = secondsRemaining ~/ 60;
    int seconds = secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get progress => secondsRemaining / maxSeconds;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
