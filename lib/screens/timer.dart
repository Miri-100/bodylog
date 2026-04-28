import 'package:flutter/material.dart';
import 'package:bodylog/models/timer_model.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  final TimerModel _timerModel = TimerModel();

  @override
  void initState() {
    super.initState();
    _timerModel.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _timerModel.dispose();
    super.dispose();
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Time's Up!"),
        content: const Text("Rest finished. Ready for the next set?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Let's Go!", style: TextStyle(color: Color(0xFF8B51E5), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimerDisplay(),
                const SizedBox(height: 40),
                _buildPresets(),
                const SizedBox(height: 60),
                _buildControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 25),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF5A72EA), Color(0xFF8B51E5)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
    ),
    child: Row(
      children: [
        if (Navigator.canPop(context))
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        if (Navigator.canPop(context)) const SizedBox(width: 15),
        const Text('Rest/Warmup Timer', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Widget _buildTimerDisplay() => Stack(
    alignment: Alignment.center,
    children: [
      SizedBox(
        width: 260, height: 260,
        child: CircularProgressIndicator(
          value: _timerModel.progress,
          strokeWidth: 10,
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B51E5)),
        ),
      ),
      Text(
        _timerModel.formattedTime,
        style: const TextStyle(fontSize: 65, fontWeight: FontWeight.bold, letterSpacing: 2),
      ),
    ],
  );

  Widget _buildPresets() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      children: [30, 60, 90, 120, 300].map((sec) {
        String label;
        if (sec < 60) {
          label = '${sec}s';
        } else {
          int m = sec ~/ 60;
          int s = sec % 60;
          label = s == 0 ? '${m}m' : '${m}m${s}s';
        }

        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ChoiceChip(
            label: Text(label),
            selected: _timerModel.secondsRemaining == sec,
            onSelected: (_) => _timerModel.setPreset(sec),
            selectedColor: const Color(0xFF8B51E5).withOpacity(0.2),
            labelStyle: TextStyle(
                color: _timerModel.secondsRemaining == sec ? const Color(0xFF8B51E5) : Colors.black54,
                fontWeight: FontWeight.bold
            ),
          ),
        );
      }).toList(),
    ),
  );

  Widget _buildControls() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _actionBtn(Icons.refresh, Colors.grey, _timerModel.reset),
      const SizedBox(width: 30),
      _actionBtn(
        _timerModel.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
        const Color(0xFF8B51E5),
            () => _timerModel.toggleTimer(onFinished: _showTimeUpDialog),
        isLarge: true,
      ),
      const SizedBox(width: 30),
      _actionBtn(Icons.stop_rounded, Colors.redAccent, () => _timerModel.setPreset(0)),
    ],
  );

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap, {bool isLarge = false}) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.all(isLarge ? 20 : 15),
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: isLarge ? 45 : 28),
    ),
  );
}
