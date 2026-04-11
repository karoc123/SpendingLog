import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/icon_map.dart';
import '../../domain/usecases/get_spending_by_category.dart';

class SpendingChart extends StatelessWidget {
  final List<CategorySpending> spending;
  final int? selectedCategoryId;
  final ValueChanged<int?> onCategoryTap;

  const SpendingChart({
    super.key,
    required this.spending,
    required this.selectedCategoryId,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (spending.isEmpty) {
      return SizedBox(height: 200, child: Center(child: Text('Keine Daten')));
    }

    final totalAbs = spending.fold<int>(0, (s, c) => s + c.totalCents.abs());

    // Build sections.
    final sections = spending.map((cs) {
      final percentage = totalAbs > 0
          ? (cs.totalCents.abs() / totalAbs * 100)
          : 0.0;
      final isSelected = cs.categoryId == selectedCategoryId;

      return PieChartSectionData(
        value: cs.totalCents.abs().toDouble(),
        title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        color: Color(cs.colorValue),
        radius: isSelected ? 70 : 60,
        titleStyle: TextStyle(
          fontSize: isSelected ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: percentage >= 10
            ? CircleAvatar(
                radius: 10,
                backgroundColor: Colors.white,
                child: Icon(
                  iconFromName(cs.iconName),
                  size: 14,
                  color: Color(cs.colorValue),
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.15,
      );
    }).toList();

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
          pieTouchData: PieTouchData(
            touchCallback: (event, response) {
              if (event.isInterestedForInteractions &&
                  response != null &&
                  response.touchedSection != null) {
                final index = response.touchedSection!.touchedSectionIndex;
                if (index >= 0 && index < spending.length) {
                  final catId = spending[index].categoryId;
                  onCategoryTap(catId == selectedCategoryId ? null : catId);
                }
              }
            },
          ),
        ),
      ),
    );
  }
}
