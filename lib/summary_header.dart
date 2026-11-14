import 'package:flutter/material.dart';

import 'area_controller.dart';
import 'status_style.dart';

// 大号数字只汇总本轮成功的设备；没有成功结果时显示未知而不是0。
class SummaryHeader extends StatelessWidget {
  const SummaryHeader({
    super.key,
    required this.controller,
    this.showLegend = true,
    this.child,
  });
  final AreaController controller;
  final bool showLegend;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final total = c.results.length;
    final known = c.succeeded > 0;
    final note = !known
        ? (c.busy ? '等待首批结果…' : '本轮没有成功结果，无法判断空位')
        : c.succeeded < total
        ? '仅汇总本轮成功的 ${c.succeeded}/$total 台'
        : '本轮 $total 台全部查询成功';
    DateTime? last;
    for (final r in c.results) {
      final time = r.receivedAt;
      if (r.phase == QueryPhase.success && time != null) {
        if (last == null || time.isAfter(last)) last = time;
      }
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MergeSemantics(
              child: Row(
                children: [
                  Text(
                    known ? '${c.available}' : '—',
                    semanticsLabel: known ? null : '未知',
                    style: AppText.hero.copyWith(
                      color: known && c.available > 0
                          ? PortStatus.available.color
                          : subtleColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          known ? '个可用插口' : '本轮空闲数量未知',
                          style: AppText.title,
                        ),
                        Text(note, style: AppText.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : c.completed / total,
                minHeight: 3,
                color: PortStatus.available.color,
                backgroundColor: lineColor,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 10,
              children: [
                Text(
                  '已完成 ${c.completed}/$total · 成功 ${c.succeeded} · 失败 ${c.failed}',
                  style: AppText.caption,
                ),
                // 客户端收到响应的时间，不是设备采集时间。
                if (!c.busy && last != null)
                  Text(
                    '${receivedLabel(last).substring(11)} 接收（北京时间）',
                    style: AppText.caption,
                  ),
              ],
            ),
            if (child != null) ...[const SizedBox(height: 10), child!],
            if (showLegend) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('插口颜色', style: AppText.caption),
                  for (final s in PortStatus.values)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: s.color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(s.label, style: AppText.caption),
                      ],
                    ),
                ],
              ),
            ],
            if (c.area != '创新大厦旁')
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('插口按平台编号显示 · 位置图待补充', style: AppText.caption),
              ),
          ],
        ),
      ),
    );
  }
}
