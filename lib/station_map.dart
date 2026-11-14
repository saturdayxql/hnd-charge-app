import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'area_controller.dart';
import 'status_style.dart';

// 创新大厦相对位置示意图：内部水平滚动，尺寸随系统字号调整。
// 地图拖动优先由内部滚动区域处理，避免与区域页面的横滑手势竞争。
class StationMap extends StatefulWidget {
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
  State<StationMap> createState() => _StationMapState();
}

class _StationMapState extends State<StationMap> {
  static const _numberStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
  );
  static const _tagStyle = TextStyle(
    fontSize: 10,
    color: Colors.white,
    height: 1.1,
  );
  static const _roadStyle = TextStyle(
    fontSize: 10,
    height: 1.1,
    color: subtleColor,
  );

  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _select(int number, double centerX) {
    widget.onSelected(number);
    if (!_scroll.hasClients) return;
    final vp = _scroll.position.viewportDimension;
    final target = (centerX - vp / 2).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  // 按实际字体和字号测量，保留最小触控尺寸，不缩小系统文字。
  _MapLayout _layoutFor(BuildContext context) {
    Size measure(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: DefaultTextStyle.of(context).style.merge(style),
        ),
        textScaler: MediaQuery.textScalerOf(context),
        textDirection: Directionality.of(context),
      )..layout();
      final size = painter.size;
      painter.dispose();
      return size;
    }

    final number = measure('88号', _numberStyle);
    var tagWidth = 0.0;
    var tagHeight = 0.0;
    // 所有加载状态预留同样的空间，避免查询结果更新时地图来回跳动。
    for (final tag in [
      '空10',
      '待查',
      '查询',
      '失败',
      '未知',
      ...widget.results.map(stationTagOf),
    ]) {
      final size = measure(tag, _tagStyle);
      tagWidth = math.max(tagWidth, size.width);
      tagHeight = math.max(tagHeight, size.height);
    }
    final road = measure('← 北侧主路 →', _roadStyle);
    final building = measure('创新\n大厦', _roadStyle);
    return _MapLayout(
      buttonWidth: math
          .max(52.0, math.max(number.width, tagWidth) + 8)
          .ceilToDouble(),
      buttonHeight: math
          .max(44.0, number.height + tagHeight + 8)
          .ceilToDouble(),
      roadHeight: math.max(18.0, road.height + 4).ceilToDouble(),
      buildingWidth: math.max(64.0, building.width + 8).ceilToDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final layout = _layoutFor(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 4,
            children: [
              Text('北↑ 左西右东', style: AppText.caption),
              Text('← 拖动查看全图 →', style: AppText.caption),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          key: const Key('map-scroll'),
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: layout.mapWidth,
            height: layout.mapHeight,
            child: Stack(children: _buildMap(layout)),
          ),
        ),
        const SizedBox(height: 6),
        // 整桩图例；插口状态的图例由列表提供。
        Wrap(
          spacing: 10,
          runSpacing: 2,
          children: [
            const Text('整桩：', style: AppText.caption),
            for (final entry in const {
              '绿': Color(0xFF176B61),
              '红': Color(0xFFB83A32),
              '橙': Color(0xFF966000),
              '灰': Color(0xFF596273),
            }.entries)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: entry.value,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(entry.key, style: AppText.caption),
                ],
              ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildMap(_MapLayout layout) {
    const road = Color(0xFFCDD5DD);
    const grass = Color(0xFFDDEBDD);
    const building = Color(0xFFD9DFE7);

    Widget rect(
      double l,
      double t,
      double w,
      double h,
      Color c, {
      String label = '',
      Key? key,
    }) => Positioned(
      left: l,
      top: t,
      width: w,
      height: h,
      child: Container(
        key: key,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(3),
        ),
        child: label.isEmpty
            ? null
            : Text(label, textAlign: TextAlign.center, style: _roadStyle),
      ),
    );

    final widgets = <Widget>[
      rect(0, 0, layout.beltEnd, layout.northRoadY, grass),
      // 草坪中的南北小路（依据现场草图近似）。
      rect(140, 0, 14, layout.northRoadY, road),
      rect(
        0,
        layout.northRoadY,
        layout.eastRoadX + _MapLayout.eastRoadWidth,
        layout.roadHeight,
        road,
        label: '← 北侧主路 →',
        key: const Key('map-north-road'),
      ),
      rect(
        0,
        layout.southRoadY,
        layout.mapWidth,
        layout.roadHeight,
        road,
        label: '← 南侧主路 →',
        key: const Key('map-south-road'),
      ),
      // 设施带在两条主路之间，同组两排桩中间不是道路。
      rect(
        0,
        layout.beltTopY,
        layout.beltEnd,
        layout.southRoadY - layout.beltTopY,
        const Color(0xFFEEF0F2),
        key: const Key('map-belt'),
      ),
      rect(
        layout.eastRoadX,
        0,
        _MapLayout.eastRoadWidth,
        layout.mapHeight,
        road,
        key: const Key('map-east-road'),
      ),
      rect(
        layout.buildingX,
        4,
        layout.buildingWidth,
        layout.southRoadY - 8,
        building,
        label: '创新\n大厦',
      ),
    ];

    // 4条组间通道与南北主路首尾相接，不侵入相邻按钮。
    for (var g = 0; g < 4; g++) {
      widgets.add(
        rect(
          layout.groupWidth * g + layout.groupBodyWidth,
          layout.northRoadY + layout.roadHeight,
          _MapLayout.aisle,
          layout.southRoadY - layout.northRoadY - layout.roadHeight,
          road,
          key: ValueKey('map-aisle-$g'),
        ),
      );
    }

    for (var g = 0; g < 5; g++) {
      final groupX = layout.groupWidth * g;
      for (var i = 0; i < 2; i++) {
        final x = groupX + i * (layout.buttonWidth + _MapLayout.gap);
        widgets.add(_btn(g * 2 + i + 1, x, layout.buttonNorthY, layout));
        widgets.add(_btn(20 - g * 2 - i, x, layout.buttonSouthY, layout));
      }
    }
    return widgets;
  }

  Widget _btn(int number, double left, double top, _MapLayout layout) {
    final r = widget.results.firstWhere((r) => r.station.number == number);
    final color = stationLevelOf(r).color;
    final tag = stationTagOf(r);
    final selected = widget.selected == number;
    final centerX = left + layout.buttonWidth / 2;
    return Positioned(
      left: left,
      top: top,
      width: layout.buttonWidth,
      height: layout.buttonHeight,
      child: Semantics(
        label: '$number号桩，$tag',
        button: true,
        selected: selected,
        child: GestureDetector(
          key: ValueKey('map-station-$number'),
          onTap: () => _select(number, centerX),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: selected ? Colors.white : color,
                width: selected ? 2.5 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$number号', style: _numberStyle),
                Text(tag, style: _tagStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 从按钮尺寸统一推导地图坐标；任何字号下两排桩和设施带都不覆盖主路。
class _MapLayout {
  const _MapLayout({
    required this.buttonWidth,
    required this.buttonHeight,
    required this.roadHeight,
    required this.buildingWidth,
  });

  static const gap = 4.0;
  static const aisle = 16.0;
  static const eastRoadWidth = 20.0;
  final double buttonWidth;
  final double buttonHeight;
  final double roadHeight;
  final double buildingWidth;

  double get groupBodyWidth => buttonWidth * 2 + gap;
  double get groupWidth => groupBodyWidth + aisle;
  double get beltEnd => groupWidth * 4 + groupBodyWidth;
  double get northRoadY => 50.0;
  double get beltTopY => northRoadY + roadHeight + gap;
  double get buttonNorthY => beltTopY + gap;
  double get buttonSouthY => buttonNorthY + buttonHeight + gap * 2;
  double get southRoadY => buttonSouthY + buttonHeight + gap;
  double get eastRoadX => beltEnd + gap;
  double get buildingX => eastRoadX + eastRoadWidth + gap;
  double get mapWidth => math.max(660.0, buildingX + buildingWidth + gap);
  double get mapHeight => southRoadY + roadHeight;
}
