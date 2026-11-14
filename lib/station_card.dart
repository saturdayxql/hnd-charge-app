import 'package:flutter/material.dart';

import 'area_controller.dart';
import 'station_service.dart';
import 'status_style.dart';

// 默认只展示找空位所需的信息；点击整张卡片展开设备与时间详情。
// 左侧色条与位置图、整桩速览同义；错误和旧数据提示始终在折叠层可见。
class StationCard extends StatefulWidget {
  const StationCard({
    super.key,
    required this.result,
    this.initiallyExpanded = false,
  });
  final StationResult result;
  final bool initiallyExpanded;
  @override
  State<StationCard> createState() => _StationCardState();
}

class _StationCardState extends State<StationCard> {
  late bool expanded = widget.initiallyExpanded;
  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final ports = r.ports;
    final stale = r.phase != QueryPhase.success && ports != null;
    final freeNumbers = [
      for (final p in ports ?? <PortInfo>[])
        if (p.state == 1) p.number,
    ];
    final error = Theme.of(context).colorScheme.error;
    final Widget phaseBadge = switch (r.phase) {
      QueryPhase.waiting => const Text('等待查询', style: AppText.caption),
      QueryPhase.loading => const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 5),
          Text('查询中…', style: AppText.caption),
        ],
      ),
      // 有空口时实心绿色胶囊，扫视即可发现。
      QueryPhase.success => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: freeNumbers.isNotEmpty
              ? PortStatus.available.color
              : lineColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '可用 ${freeNumbers.length}/${ports!.length}',
          style: AppText.label.copyWith(
            color: freeNumbers.isNotEmpty ? Colors.white : subtleColor,
          ),
        ),
      ),
      QueryPhase.failed => Text(
        '查询失败',
        style: AppText.label.copyWith(color: error),
      ),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => expanded = !expanded),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: stationLevelOf(r).color, width: 4),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('${r.station.number}号桩', style: AppText.title),
                  ),
                  phaseBadge,
                  const SizedBox(width: 2),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: subtleColor,
                  ),
                ],
              ),
              if (r.phase == QueryPhase.failed || stale)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: warnBackground,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (r.phase == QueryPhase.failed)
                        Text(
                          r.error ?? '请稍后重试',
                          style: AppText.label.copyWith(
                            fontSize: 12,
                            color: error,
                          ),
                        ),
                      if (stale)
                        const Text(
                          '以下为上次结果，当前状态未确认。',
                          style: TextStyle(fontSize: 12, color: warnColor),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              if (ports == null) const Text('尚无插口数据', style: AppText.caption),
              if (ports != null)
                LayoutBuilder(
                  builder: (context, constraints) {
                    // 普通字号一排10口；按两位编号的实测宽度判断，
                    // 大字号放不下时才减少列数换行，不缩小系统文字。
                    const spacing = 3.0;
                    final minCellWidth =
                        measureTextWidth(
                          '88',
                          AppText.label,
                          MediaQuery.textScalerOf(context),
                        ) +
                        6;
                    final columns = fitColumns(
                      constraints.maxWidth,
                      spacing,
                      minCellWidth,
                    );
                    final width =
                        (constraints.maxWidth - spacing * (columns - 1)) /
                        columns;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: 4,
                      children: [
                        for (final p in ports)
                          SizedBox(
                            key: ValueKey('port-${p.number}'),
                            width: width,
                            child: Semantics(
                              label:
                                  '${p.number}号插口，${statusOf(p.state).label}${stale ? "，上次结果" : ""}',
                              excludeSemantics: true,
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: statusOf(p.state).color,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  '${p.number}',
                                  style: AppText.label.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              if (expanded)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: pageColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ports != null)
                        Text(
                          '可用插口：${freeNumbers.isEmpty ? "无" : freeNumbers.join('、')}${stale ? "（上次结果）" : ""}',
                          style: AppText.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      Text('设备编号：${r.station.code}', style: AppText.caption),
                      Text(
                        r.receivedAt == null
                            ? '尚无成功查询记录'
                            : '上次成功接收：${receivedLabel(r.receivedAt!)}（北京时间）',
                        style: AppText.caption,
                      ),
                      const Text(
                        '接收时间不等于设备采集时间；编号按现场清单排列。',
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
