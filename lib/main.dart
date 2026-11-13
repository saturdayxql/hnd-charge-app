import 'package:flutter/material.dart';

import 'area_controller.dart';
import 'station_service.dart';
import 'station_map.dart';
import 'station_config.dart';

void main() => runApp(const ChargeApp());

class ChargeApp extends StatelessWidget {
  const ChargeApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '校园充电桩',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B61)),
      scaffoldBackgroundColor: const Color(0xFFF4F6F8),
      useMaterial3: true,
    ),
    home: const StationPage(),
  );
}

enum PortStatus {
  available('可用', Color(0xFF176B61), Icons.check_circle_outline),
  charging('充电中', Color(0xFFB83A32), Icons.bolt),
  unavailable('不可用', Color(0xFF966000), Icons.block),
  unknown('未知', Color(0xFF596273), Icons.help_outline);

  const PortStatus(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;
}

PortStatus statusOf(int? code) => switch (code) {
  1 => PortStatus.available,
  2 => PortStatus.charging,
  3 => PortStatus.unavailable,
  _ => PortStatus.unknown,
};
String receivedLabel(DateTime time) => time
    .toUtc()
    .add(const Duration(hours: 8))
    .toIso8601String()
    .substring(0, 19)
    .replaceFirst('T', ' ');

class StationPage extends StatefulWidget {
  const StationPage({super.key, this.loader = fetchStation});
  final Future<List<PortInfo>> Function(String) loader;
  @override
  State<StationPage> createState() => _StationPageState();
}

class _StationPageState extends State<StationPage> {
  late final AreaController controller;
  bool showMap = false;
  int selectedNumber = 1;
  @override
  void initState() {
    super.initState();
    controller = AreaController(loader: widget.loader);
    controller.refresh();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            key: const Key('area-picker'),
            value: controller.area,
            isExpanded: true,
            items: stationAreas.keys
                .map(
                  (area) =>
                      DropdownMenuItem(value: area, child: Text('$area · 充电桩')),
                )
                .toList(),
            onChanged: (area) {
              if (area == null || area == controller.area) return;
              setState(() {
                showMap = false;
                selectedNumber = 1;
              });
              controller.selectArea(area);
            },
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text('列表')),
                ButtonSegment(
                  value: true,
                  label: Text('位置图'),
                  enabled: controller.area == '创新大厦旁',
                ),
              ],
              selected: {showMap},
              onSelectionChanged: (value) =>
                  setState(() => showMap = value.first),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          itemCount: showMap ? 3 : controller.results.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) return SummaryHeader(controller: controller);
            if (showMap && index == 1) {
              return StationMap(
                results: controller.results,
                selected: selectedNumber,
                onSelected: (number) => setState(() => selectedNumber = number),
              );
            }
            if (showMap) {
              return StationCard(
                key: ValueKey('map-detail-$selectedNumber'),
                initiallyExpanded: true,
                result: controller.results.firstWhere(
                  (r) => r.station.number == selectedNumber,
                ),
              );
            }
            return StationCard(
              key: ValueKey(controller.results[index - 1].station.code),
              result: controller.results[index - 1],
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            key: const Key('refresh-all'),
            onPressed: controller.busy ? null : controller.refresh,
            icon: const Icon(Icons.refresh),
            label: Text(
              controller.busy
                  ? '正在查询 ${controller.completed}/${controller.results.length}'
                  : '刷新全部状态',
            ),
          ),
        ),
      ),
    ),
  );
}

// 大号数字只汇总本轮成功的设备；没有成功结果时显示未知而不是0。
class SummaryHeader extends StatelessWidget {
  const SummaryHeader({super.key, required this.controller});
  final AreaController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final total = c.results.length;
    final theme = Theme.of(context);
    final known = c.succeeded > 0;
    final note = !known
        ? (c.busy ? '等待首批结果…' : '本轮没有成功结果，无法判断空位')
        : c.succeeded < total
        ? '仅汇总本轮成功的 ${c.succeeded}/$total 台'
        : '本轮 $total 台全部查询成功';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MergeSemantics(
              child: Row(
                children: [
                  Text(
                    known ? '${c.available}' : '—',
                    semanticsLabel: known ? null : '未知',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: known && c.available > 0
                          ? PortStatus.available.color
                          : PortStatus.unknown.color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          known ? '个可用插口' : '本轮空闲数量未知',
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(note, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : c.completed / total,
                minHeight: 4,
                backgroundColor: const Color(0xFFE3E6E8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '已完成 ${c.completed}/$total · 成功 ${c.succeeded} · 失败 ${c.failed}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: PortStatus.unknown.color,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                for (final s in PortStatus.values)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: s.color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(s.label, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
              ],
            ),
            if (c.area != '创新大厦旁')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '插口按平台编号显示 · 位置图待补充',
                  style: TextStyle(fontSize: 12, color: PortStatus.unknown.color),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// 默认只展示找空位所需的信息；点击整张卡片展开设备与时间详情。
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
    const muted = TextStyle(fontSize: 13, color: Color(0xFF596273));
    // 只有本轮成功才显示数量胶囊；有空口时实心绿色，扫视即可发现。
    final Widget phaseBadge = switch (r.phase) {
      QueryPhase.waiting => const Text('等待查询', style: muted),
      QueryPhase.loading => const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 5),
          Text('查询中…', style: muted),
        ],
      ),
      QueryPhase.success => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: freeNumbers.isNotEmpty
              ? PortStatus.available.color
              : const Color(0xFFE3E6E8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '可用 ${freeNumbers.length}/${ports!.length}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: freeNumbers.isNotEmpty
                ? Colors.white
                : PortStatus.unknown.color,
          ),
        ),
      ),
      QueryPhase.failed => Text(
        '查询失败',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: error,
        ),
      ),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => expanded = !expanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${r.station.number}号桩',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  phaseBadge,
                  const SizedBox(width: 2),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: const Color(0xFF596273),
                  ),
                ],
              ),
              // 错误与旧数据警告始终在折叠层可见，不藏进展开详情。
              if (r.phase == QueryPhase.failed || stale)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (r.phase == QueryPhase.failed)
                        Text(
                          r.error ?? '请稍后重试',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: error,
                          ),
                        ),
                      if (stale)
                        const Text(
                          '以下为上次结果，当前状态未确认。',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A4B00),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              if (ports == null)
                const Text('尚无插口数据', style: TextStyle(fontSize: 12)),
              if (ports != null)
                LayoutBuilder(
                  builder: (context, constraints) {
                    // 普通字号下一排10口；窄屏或大字号自动换行，不缩小系统文字。
                    final minimumWidth =
                        MediaQuery.textScalerOf(context).scale(12) * 2 + 4;
                    final columns =
                        ((constraints.maxWidth + 3) / (minimumWidth + 3))
                            .floor()
                            .clamp(1, 10);
                    final width =
                        (constraints.maxWidth - (columns - 1) * 3) / columns;
                    return Wrap(
                      spacing: 3,
                      runSpacing: 4,
                      children: ports.map((p) {
                        final s = statusOf(p.state);

                        return SizedBox(
                          width: width,
                          child: Semantics(
                            label:
                                '${p.number}号插口，${s.label}${stale ? "，上次结果" : ""}',
                            excludeSemantics: true,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: s.color,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${p.number}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              if (expanded)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6F8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(fontSize: 12, height: 1.4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (ports != null)
                          Text(
                            '可用插口：${freeNumbers.isEmpty ? "无" : freeNumbers.join('、')}${stale ? "（上次结果）" : ""}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        Text('设备编号：${r.station.code}'),
                        Text(
                          r.receivedAt == null
                              ? '尚无成功查询记录'
                              : '上次成功接收：${receivedLabel(r.receivedAt!)}（北京时间）',
                        ),
                        const Text(
                          '接收时间不等于设备采集时间；编号按现场清单排列。',
                          style: TextStyle(color: Color(0xFF596273)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
