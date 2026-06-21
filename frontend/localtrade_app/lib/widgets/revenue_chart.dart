import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

class RevenueChart extends StatelessWidget {
  final List<dynamic> recentOrders;

  const RevenueChart({super.key, required this.recentOrders});

  @override
  Widget build(BuildContext context) {
    if (recentOrders.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: const Center(
          child: Text('No data for chart', style: TextStyle(color: AppColors.muted, fontSize: 14)),
        ),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
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
              color: AppColors.coral,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.coralLight.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _generateSpots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < recentOrders.length; i++) {
      final amount = recentOrders[i]['totalAmount'].toDouble();
      spots.add(FlSpot(i.toDouble(), amount));
    }
    return spots.reversed.toList();
  }
}
