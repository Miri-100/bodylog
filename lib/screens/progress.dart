import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProgressTrackingPage extends StatefulWidget {
  const ProgressTrackingPage({super.key});

  @override
  State<ProgressTrackingPage> createState() => _ProgressTrackingPageState();
}

class _ProgressTrackingPageState extends State<ProgressTrackingPage> {
  final SupabaseClient _client = Supabase.instance.client;
  bool _isLoading = false;
  List<Map<String, dynamic>> _last7DaysData = [];
  double _totalCalories = 0;
  double _averageCalories = 0;

  @override
  void initState() {
    super.initState();
    _fetchLast7DaysWorkouts();
  }

  /// Fetch workouts from the last 7 days
  Future<void> _fetchLast7DaysWorkouts() async {
    setState(() => _isLoading = true);

    try {
      // Get date from 7 days ago
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 6));
      final formattedDate = sevenDaysAgo.toIso8601String().split('T')[0];

      // Fetch workouts from Supabase
      final response = await _client
          .from('workouts')
          .select()
          .gte('created_at', formattedDate)
          .order('created_at', ascending: true);

      // Group by day
      final Map<String, double> dailyCalories = {};

      // Initialize last 7 days with 0 calories
      for (int i = 0; i < 7; i++) {
        final date = DateTime.now().subtract(Duration(days: 6 - i));
        final dayKey = '${date.weekday} ${date.day}'; // Mon 21, etc
        dailyCalories[dayKey] = 0;
      }

      // Add actual data
      for (var workout in response) {
        final date = DateTime.parse(workout['created_at'] as String);
        final dayKey = '${date.weekday} ${date.day}';
        dailyCalories[dayKey] =
            (dailyCalories[dayKey] ?? 0) + (workout['calories'] as num).toDouble();
      }

      final totalCals = dailyCalories.values.reduce((a, b) => a + b);
      final avgCals = totalCals / 7;

      setState(() {
        _last7DaysData = dailyCalories.entries
            .map((e) => {'day': e.key, 'calories': e.value})
            .toList();
        _totalCalories = totalCals;
        _averageCalories = avgCals;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Get day abbreviation from weekday number
  String _getDayAbbr(int weekday) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Tracking'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            onPressed: _fetchLast7DaysWorkouts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchLast7DaysWorkouts,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  // Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  'Total Calories',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_totalCalories.toStringAsFixed(0)} kcal',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  'Daily Average',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_averageCalories.toStringAsFixed(0)} kcal',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Line Chart
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Calories Burned (Last 7 Days)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 300,
                            child: _last7DaysData.isEmpty
                                ? Center(
                                    child: Text(
                                      'No data available',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  )
                                : LineChart(
                                    LineChartData(
                                      gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: false,
                                        horizontalInterval: 100,
                                        getDrawingHorizontalLine: (value) {
                                          return FlLine(
                                            color: Colors.grey[300],
                                            strokeWidth: 0.5,
                                          );
                                        },
                                      ),
                                      titlesData: FlTitlesData(
                                        topTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                        rightTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) {
                                              if (value.toInt() <
                                                  _last7DaysData.length) {
                                                final day = _last7DaysData[
                                                        value.toInt()]['day']
                                                    .toString()
                                                    .split(' ')[1]; // Get date
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                    top: 8,
                                                  ),
                                                  child: Text(
                                                    day,
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                );
                                              }
                                              return const Text('');
                                            },
                                            reservedSize: 30,
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) {
                                              return Text(
                                                '${value.toInt()}',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              );
                                            },
                                            reservedSize: 40,
                                          ),
                                        ),
                                      ),
                                      borderData: FlBorderData(
                                        show: true,
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey[300]!,
                                          ),
                                          left: BorderSide(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                      ),
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: _last7DaysData
                                              .asMap()
                                              .entries
                                              .map(
                                                (e) => FlSpot(
                                                  e.key.toDouble(),
                                                  (e.value['calories']
                                                      as num)
                                                    .toDouble(),
                                                ),
                                              )
                                              .toList(),
                                          isCurved: true,
                                          color: Colors.deepPurple,
                                          barWidth: 3,
                                          isStrokeCapRound: true,
                                          dotData: FlDotData(
                                            show: true,
                                            getDotPainter:
                                                (spot, percent, barData, index) {
                                              return FlDotCirclePainter(
                                                radius: 5,
                                                color: Colors.deepPurple,
                                                strokeWidth: 2,
                                                strokeColor: Colors.white,
                                              );
                                            },
                                          ),
                                          belowBarData: BarAreaData(
                                            show: true,
                                            color: Colors.deepPurple
                                                .withOpacity(0.2),
                                          ),
                                        ),
                                      ],
                                      minX: 0,
                                      maxX: (_last7DaysData.length - 1)
                                          .toDouble(),
                                      minY: 0,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Daily Breakdown
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Daily Breakdown',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._last7DaysData.map(
                            (day) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.deepPurple.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      day['day']
                                          .toString()
                                          .split(' ')[0], // Day name
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: (_totalCalories > 0
                                            ? (day['calories'] as num) /
                                                (_totalCalories / 7)
                                            : 0),
                                        minHeight: 8,
                                        backgroundColor:
                                            Colors.grey.withOpacity(0.3),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                          Colors.deepPurple,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 50,
                                    child: Text(
                                      '${(day['calories'] as num).toStringAsFixed(0)} kcal',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
