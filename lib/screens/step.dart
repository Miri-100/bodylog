import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:bodylog/models/step_model.dart';

class StepsPage extends StatefulWidget {
  const StepsPage({super.key});

  @override
  State<StepsPage> createState() => _StepsPageState();
}

class _StepsPageState extends State<StepsPage> {
  final StepService _stepService = StepService();
  StreamSubscription<StepCount>? _subscription;

  int _todaySteps = 0;
  int _lastSyncedSteps = 0;
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initPedometer();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _initPedometer() async {
    if (await Permission.activityRecognition.request().isGranted) {
      final initialSteps = await _stepService.getTodaySteps();
      setState(() {
        _todaySteps = initialSteps;
        _lastSyncedSteps = initialSteps;
      });

      _subscription = Pedometer.stepCountStream.listen(_onStepCount);
    } else {
      setState(() => _status = 'Permission Denied');
    }
  }

  void _onStepCount(StepCount event) {
    setState(() {
      _todaySteps = event.steps;
      _status = 'Tracking...';
    });

    // Sync to Supabase every 5 steps
    if ((_todaySteps - _lastSyncedSteps).abs() >= 5) {
      _syncSteps();
    }
  }

  Future<void> _syncSteps() async {
    try {
      await _stepService.updateTodaySteps(_todaySteps);
      _lastSyncedSteps = _todaySteps;
      debugPrint("✅ Cloud Sync: $_todaySteps steps");
    } catch (e) {
      debugPrint("❌ Sync Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Tracker'), backgroundColor: Colors.orange),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_run, size: 80, color: Colors.orange),
            Text('$_todaySteps', style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold)),
            Text('Status: $_status'),
          ],
        ),
      ),
    );
  }
}
