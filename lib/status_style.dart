import 'package:flutter/material.dart';

import 'area_controller.dart';

const inkColor = Color(0xFF1B2328);
const subtleColor = Color(0xFF596273);
const lineColor = Color(0xFFE3E6E8);
const pageColor = Color(0xFFF4F6F8);
const warnBackground = Color(0xFFFFF4E5);
const warnColor = Color(0xFF8A4B00);

// 文字层级：主数字 > 桩号/区域 > 状态标签 > 灰色说明；数字等宽，刷新时不跳动。
abstract final class AppText {
  static const _tabular = [FontFeature.tabularFigures()];
  static const hero = TextStyle(
    fontSize: 34,
    height: 1.1,
    fontWeight: FontWeight.w700,
    fontFeatures: _tabular,
  );
  static const title = TextStyle(
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: inkColor,
  );
  static const label = TextStyle(
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w600,
    fontFeatures: _tabular,
  );
  static const body = TextStyle(fontSize: 13, height: 1.4, color: inkColor);
  static const caption = TextStyle(
    fontSize: 12,
    height: 1.35,
    color: subtleColor,
    fontFeatures: _tabular,
  );
}

// 单插口状态：格子只显示编号，用颜色和语义标签表达状态。
enum PortStatus {
  available('可用', Color(0xFF176B61)),
  charging('充电中', Color(0xFFB83A32)),
  unavailable('不可用', Color(0xFF966000)),
  unknown('未知', Color(0xFF596273));

  const PortStatus(this.label, this.color);
  final String label;
  final Color color;
}

PortStatus statusOf(int? code) => switch (code) {
  1 => PortStatus.available,
  2 => PortStatus.charging,
  3 => PortStatus.unavailable,
  _ => PortStatus.unknown,
};

// 整桩汇总只看本轮成功结果；full 表示无空口，不代表每个口都在充电。
enum StationLevel {
  pending(Color(0xFF596273)),
  free(Color(0xFF176B61)),
  uncertain(Color(0xFF966000)),
  full(Color(0xFFB83A32));

  const StationLevel(this.color);
  final Color color;
}

StationLevel stationLevelOf(StationResult r) {
  if (r.phase != QueryPhase.success) return StationLevel.pending;
  final ports = r.ports ?? [];
  if (ports.any((p) => p.state == 1)) return StationLevel.free;
  if (ports.any((p) => p.state != 1 && p.state != 2 && p.state != 3)) {
    return StationLevel.uncertain;
  }
  return StationLevel.full;
}

// 位置图按钮与整桩速览共用的短标签。
String stationTagOf(StationResult r) => switch (stationLevelOf(r)) {
  StationLevel.uncertain => '未知',
  StationLevel.free ||
  StationLevel.full => '空${r.ports!.where((p) => p.state == 1).length}',
  StationLevel.pending => switch (r.phase) {
    QueryPhase.waiting => '待查',
    QueryPhase.loading => '查询',
    _ => '失败',
  },
};

// 实测文字在当前字号缩放下的宽度，用来判断格子放不放得下，不按字号粗估。
double measureTextWidth(String text, TextStyle style, TextScaler scaler) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textScaler: scaler,
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

// 优先排满 maxColumns 列；放不下时逐列减少，宁可换行也不缩小文字。
int fitColumns(
  double available,
  double gap,
  double minCellWidth, {
  int maxColumns = 10,
}) {
  for (var columns = maxColumns; columns > 1; columns--) {
    if ((available - gap * (columns - 1)) / columns >= minCellWidth) {
      return columns;
    }
  }
  return 1;
}

String receivedLabel(DateTime time) => time
    .toUtc()
    .add(const Duration(hours: 8))
    .toIso8601String()
    .substring(0, 19)
    .replaceFirst('T', ' ');
