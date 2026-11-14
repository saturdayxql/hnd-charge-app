import 'package:flutter/material.dart';

import 'area_bar.dart';
import 'area_controller.dart';
import 'station_card.dart';
import 'station_config.dart';
import 'station_map.dart';
import 'station_overview.dart';
import 'station_service.dart';
import 'status_style.dart';
import 'summary_header.dart';

void main() => runApp(const ChargeApp());

class ChargeApp extends StatelessWidget {
  const ChargeApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '校园充电桩',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: PortStatus.available.color),
      scaffoldBackgroundColor: pageColor,
      cardTheme: const CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      useMaterial3: true,
    ),
    home: const StationPage(),
  );
}

class StationPage extends StatefulWidget {
  const StationPage({super.key, this.loader = fetchStation});
  final Future<List<PortInfo>> Function(String) loader;
  @override
  State<StationPage> createState() => _StationPageState();
}

class _StationPageState extends State<StationPage>
    with SingleTickerProviderStateMixin {
  final areas = stationAreas.keys.toList();
  late final controller = AreaController(loader: widget.loader);
  late final tabs = TabController(length: areas.length, vsync: this);
  final cardKeys = <String, GlobalKey>{};
  final showMap = ValueNotifier(false);
  final selectedNumber = ValueNotifier(1);
  // 页面内容直接监听这些状态：TabBarView切换动画期间会冻结子页面，
  // 只靠父级重建会让新区域短暂显示旧内容。
  late final state = Listenable.merge([controller, showMap, selectedNumber]);

  @override
  void initState() {
    super.initState();
    tabs.addListener(_onTabChanged);
    controller.refresh();
  }

  // 点标签立即切换；左右滑动在页面停稳后才切换并查询。切换后回到列表。
  void _onTabChanged() {
    final area = areas[tabs.index];
    if (area == controller.area) return;
    showMap.value = false;
    selectedNumber.value = 1;
    controller.selectArea(area);
  }

  @override
  void dispose() {
    tabs.removeListener(_onTabChanged);
    tabs.dispose();
    showMap.dispose();
    selectedNumber.dispose();
    controller.dispose();
    super.dispose();
  }

  // 速览格只滚动到对应卡片，不触发查询。
  void _jumpTo(StationResult r) {
    final context = cardKeys[r.station.code]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) => Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Material(
              color: Colors.white,
              child: AreaBar(areas: areas, tabs: tabs),
            ),
            Expanded(
              child: TabBarView(
                controller: tabs,
                // 位置图需要左右拖动，此时只能点标签切换区域，避免手势冲突。
                physics: null,
                children: [
                  for (final area in areas)
                    ListenableBuilder(
                      listenable: state,
                      builder: (context, _) => area != controller.area
                          ? _pendingPage(area)
                          : showMap.value
                          ? _mapPage()
                          : _listPage(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomBar(),
    ),
  );

  // 滑动途中露出的相邻区域：控制器只保存当前区域结果，松手后才开始查询。
  Widget _pendingPage(String area) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(area, style: AppText.title),
        const Text('停稳后开始查询', style: AppText.caption),
      ],
    ),
  );

  Widget _listPage() => SingleChildScrollView(
    key: const Key('station-list'),
    padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SummaryHeader(
          controller: controller,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('整桩速览 · 点按跳到该桩', style: AppText.caption),
              const SizedBox(height: 4),
              StationOverview(results: controller.results, onTap: _jumpTo),
            ],
          ),
        ),
        const SizedBox(height: 10),
        for (final r in controller.results)
          StationCard(
            key: cardKeys.putIfAbsent(r.station.code, GlobalKey.new),
            result: r,
          ),
      ],
    ),
  );

  Widget _mapPage() => SingleChildScrollView(
    key: const Key('map-page'),
    padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SummaryHeader(controller: controller, showLegend: false),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: StationMap(
              results: controller.results,
              selected: selectedNumber.value,
              onSelected: (number) => selectedNumber.value = number,
            ),
          ),
        ),
        const SizedBox(height: 8),
        StationCard(
          key: ValueKey('map-detail-${selectedNumber.value}'),
          initiallyExpanded: true,
          result: controller.results.firstWhere(
            (r) => r.station.number == selectedNumber.value,
          ),
        ),
      ],
    ),
  );

  Widget _bottomBar() => Material(
    color: Colors.white,
    child: SafeArea(
      top: false,
      child: Container(
        key: const Key('bottom-bar'),
        width: double.infinity,
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: lineColor)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        // 一行放不下（大字号）时自动换成两行，不裁切文字。
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                const ButtonSegment(value: false, label: Text('列表')),
                ButtonSegment(
                  value: true,
                  label: const Text('位置图'),
                  enabled: controller.area == '创新大厦旁',
                ),
              ],
              selected: {showMap.value},
              onSelectionChanged: (value) => showMap.value = value.first,
            ),
            FilledButton.icon(
              key: const Key('refresh-all'),
              onPressed: controller.busy ? null : controller.refresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(
                controller.busy
                    ? '查询中 ${controller.completed}/${controller.results.length}'
                    : '刷新状态',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
