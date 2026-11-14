import 'package:flutter/material.dart';

import 'area_controller.dart';
import 'status_style.dart';

// 整桩速览：每台一格，颜色与位置图同义；点按只滚动到对应卡片，不发请求。
class StationOverview extends StatelessWidget {
  const StationOverview({
    super.key,
    required this.results,
    required this.onTap,
  });
  final List<StationResult> results;
  final ValueChanged<StationResult> onTap;

  static const _tagStyle = TextStyle(
    fontSize: 10,
    height: 1.2,
    color: Colors.white,
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 3.0;
      // 普通字号一排10格；取桩号与状态短标签中实测最宽者判断，
      // 大字号放不下时才减少列数换行，不缩小文字。
      final scaler = MediaQuery.textScalerOf(context);
      final minCellWidth =
          [
            measureTextWidth('88', AppText.label, scaler),
            for (final tag in const ['空10', '待查', '失败', '未知'])
              measureTextWidth(tag, _tagStyle, scaler),
          ].reduce((a, b) => a > b ? a : b) +
          4;
      final columns = fitColumns(constraints.maxWidth, gap, minCellWidth);
      final width = (constraints.maxWidth - (columns - 1) * gap) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final r in results) SizedBox(width: width, child: _cell(r)),
        ],
      );
    },
  );

  Widget _cell(StationResult r) {
    final number = r.station.number;
    final tag = stationTagOf(r);
    return Semantics(
      label: '$number号桩，$tag',
      button: true,
      excludeSemantics: true,
      child: Material(
        color: stationLevelOf(r).color,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          key: ValueKey('overview-$number'),
          borderRadius: BorderRadius.circular(6),
          onTap: () => onTap(r),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Column(
              children: [
                Text(
                  '$number',
                  style: AppText.label.copyWith(color: Colors.white),
                ),
                Text(tag, style: _tagStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
