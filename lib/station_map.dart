import 'package:flutter/material.dart';

import 'area_controller.dart';

// 位置只表达现场相对关系，不是GPS地图；横向滑动保持编号可读。
class StationMap extends StatelessWidget {
  const StationMap({
    super.key,
    required this.results,
    required this.selected,
    required this.onSelected,
  });
  final List<StationResult> results;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    Widget block(
      double x,
      double y,
      double w,
      double h,
      Color color,
      String label,
    ) => Positioned(
      left: x,
      top: y,
      width: w,
      height: h,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
    final road = Colors.blueGrey.shade100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('北 ↑  · 左西右东 · 非比例图', style: TextStyle(fontSize: 12)),
        const Text('左右滑动查看全图；点击桩号查看下方插口详情。', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          key: const Key('map-scroll'),
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 800,
            height: 360,
            child: Stack(
              children: [
                block(0, 0, 620, 110, const Color(0xFFDDEBDD), '草坪'),
                block(175, 0, 18, 110, road, '小\n路'),
                block(630, 0, 36, 344, road, ''),
                block(680, 15, 115, 270, const Color(0xFFD9DFE7), '创新大厦'),
                block(0, 120, 666, 36, road, '← 北侧东西向主路 →'),
                block(0, 308, 800, 36, road, '← 南侧东西向主路 →'),
                for (var g = 0; g < 5; g++) ...[
                  block(g * 128.0, 164, 108, 136, const Color(0xFFE3E6E8), ''),
                  Positioned(
                    left: g * 128.0,
                    top: 221,
                    width: 108,
                    child: Center(
                      child: Text(
                        '第${g + 1}组',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                  if (g < 4) block(g * 128.0 + 108, 156, 20, 152, road, '↕'),
                  for (var i = 0; i < 4; i++)
                    Positioned(
                      left: g * 128.0 + (i % 2) * 54,
                      top: i < 2 ? 166 : 244,
                      width: 54,
                      height: 54,
                      child: stationButton(
                        context,
                        i < 2 ? g * 2 + i + 1 : 20 - g * 2 - (i - 2),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '桩色：绿=有空口，红=无空口，橙=状态不全，灰=未更新/失败。',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget stationButton(BuildContext context, int number) {
    final r = results.firstWhere((r) => r.station.number == number);
    final ready = r.phase == QueryPhase.success;
    final ports = r.ports ?? [];
    final free = ports.where((p) => p.state == 1).length;
    final uncertain = ports.any(
      (p) => p.state != 1 && p.state != 2 && p.state != 3,
    );
    final color = !ready
        ? const Color(0xFF596273)
        : free > 0
        ? const Color(0xFF176B61)
        : uncertain
        ? const Color(0xFF966000)
        : const Color(0xFFB83A32);
    final status = ready
        ? (uncertain && free == 0 ? '未知' : '空$free')
        : switch (r.phase) {
            QueryPhase.waiting => '待查',
            QueryPhase.loading => '查询',
            QueryPhase.failed => '失败',
            QueryPhase.success => '',
          };
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Semantics(
        label: '$number号桩，$status',
        selected: selected == number,
        child: OutlinedButton(
          key: ValueKey('map-station-$number'),
          onPressed: () => onSelected(number),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: color,
            foregroundColor: Colors.white,
            side: BorderSide(
              color: selected == number ? Colors.black : color,
              width: selected == number ? 3 : 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$number号', style: const TextStyle(fontSize: 13)),
                Text(status, style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
