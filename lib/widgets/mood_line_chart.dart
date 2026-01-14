import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MoodBarChart extends StatelessWidget {
  final String userId;
  const MoodBarChart({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.grey[400] : Colors.grey;
    final gridColor = isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.1);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('mood_logs')
          .orderBy('timestamp', descending: true)
          .limit(20) 
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final Map<int, List<int>> dailyValues = {1: [], 2: [], 3: [], 4: [], 5: [], 6: [], 7: []};
        
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final timestamp = data['timestamp'] as Timestamp?;
          if (timestamp != null) {
            final date = timestamp.toDate();
            dailyValues[date.weekday]?.add(data['mood_value'] as int);
          }
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
            ],
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 10,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value == 2) return const Text('😢', style: TextStyle(fontSize: 20));
                      if (value == 4) return const Text('😡', style: TextStyle(fontSize: 20));
                      if (value == 6) return const Text('😐', style: TextStyle(fontSize: 20));
                      if (value == 8) return const Text('😊', style: TextStyle(fontSize: 20));
                      if (value == 10) return const Text('😃', style: TextStyle(fontSize: 20));
                      return const SizedBox();
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
                      return Text(days[value.toInt()], style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold));
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: dailyValues.entries.map((entry) {
                double avg = entry.value.isEmpty ? 0 : entry.value.reduce((a, b) => a + b) / entry.value.length;
                return BarChartGroupData(
                  x: entry.key - 1,
                  barRods: [
                    BarChartRodData(
                      toY: avg == 0 ? 0.5 : avg, 
                      color: _getColorForValue(avg),
                      width: 18,
                      borderRadius: BorderRadius.circular(10),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: 10,
                        color: gridColor,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Color _getColorForValue(double value) {
    if (value >= 8) return Colors.amberAccent;
    if (value >= 6) return Colors.greenAccent;
    if (value >= 4) return Colors.orangeAccent;
    if (value >= 2) return Colors.blueAccent;
    return Colors.pinkAccent;
  }
}
