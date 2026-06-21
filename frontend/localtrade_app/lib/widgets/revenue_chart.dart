import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme/app_theme.dart';

class RevenueChart extends StatelessWidget {
  final List<dynamic> recentOrders;
  
  const RevenueChart({super.key, required this.recentOrders});

  @override
  Widget build(BuildContext context) {
    if (recentOrders.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('No data for chart')),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _generateSpots(),
              isCurved: true,
              color: AppTheme.primaryColor,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primaryColor.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _generateSpots() {
    // Very simple conversion of recent orders to chart spots
    // In a real app, this would be grouped by date
    List<FlSpot> spots = [];
    for (int i = 0; i < recentOrders.length; i++) {
      final amount = recentOrders[i]['totalAmount'].toDouble();
      spots.add(FlSpot(i.toDouble(), amount));
    }
    // Reverse to show chronological order if needed, but here we just show the trend
    return spots.reversed.toList();
  }
}
