import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../viewmodels/todo_viewmodel.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<TodoViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ===== SUMMARY CARDS =====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statCard('Total', vm.totalTodos, Colors.blue),
                _statCard('Done', vm.completedTodos, Colors.green),
                _statCard('Pending', vm.pendingTodos, Colors.orange),
              ],
            ),
            const SizedBox(height: 30),

            // ===== PIE CHART =====
            Expanded(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 50,
                  sections: [
                    PieChartSectionData(
                      value: vm.completedTodos.toDouble(),
                      title: 'Done',
                      color: Colors.green,
                      radius: 80,
                    ),
                    PieChartSectionData(
                      value: vm.pendingTodos.toDouble(),
                      title: 'Pending',
                      color: Colors.orange,
                      radius: 80,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ===== COMPLETION RATE =====
            Text(
              'Completion Rate: ${vm.completionRate.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, int value, Color color) {
    return Card(
      color: color.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
