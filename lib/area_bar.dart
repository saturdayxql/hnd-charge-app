import 'dart:math';

import 'package:flutter/material.dart';

import 'status_style.dart';

// 正常字号四个区域一排，指示条随主页面左右滑动；
// 大字号放不下时改为2×2按钮，任何时候都不需要横向滚动选择区域。
class AreaBar extends StatelessWidget {
  const AreaBar({super.key, required this.areas, required this.tabs});
  final List<String> areas;
  final TabController tabs;

  static const _style = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scaler = MediaQuery.textScalerOf(context);
      var widest = 0.0;
      for (final area in areas) {
        final painter = TextPainter(
          text: TextSpan(text: area, style: _style),
          textScaler: scaler,
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();
        widest = max(widest, painter.width);
        painter.dispose();
      }
      if (widest + 8 <= constraints.maxWidth / areas.length) {
        return TabBar(
          controller: tabs,
          labelStyle: _style,
          unselectedLabelStyle: _style.copyWith(fontWeight: FontWeight.w400),
          labelColor: PortStatus.available.color,
          unselectedLabelColor: subtleColor,
          indicatorColor: PortStatus.available.color,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          dividerColor: lineColor,
          tabs: [
            for (final area in areas)
              Tab(key: ValueKey('area-$area'), height: 46, text: area),
          ],
        );
      }
      return ListenableBuilder(
        listenable: tabs,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Column(
            children: [
              for (var row = 0; row < areas.length; row += 2)
                Padding(
                  padding: EdgeInsets.only(top: row == 0 ? 0 : 6),
                  child: Row(
                    children: [
                      for (var i = row; i < row + 2; i++) ...[
                        if (i > row) const SizedBox(width: 6),
                        Expanded(
                          child: i < areas.length
                              ? _button(i)
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );

  Widget _button(int i) {
    final selected = tabs.index == i;
    final style = ButtonStyle(
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      textStyle: WidgetStatePropertyAll(
        _style.copyWith(fontWeight: selected ? FontWeight.w600 : null),
      ),
    );
    final label = Text(areas[i], textAlign: TextAlign.center);
    return Semantics(
      selected: selected,
      child: selected
          ? FilledButton(
              key: ValueKey('area-${areas[i]}'),
              style: style,
              onPressed: () => tabs.animateTo(i),
              child: label,
            )
          : OutlinedButton(
              key: ValueKey('area-${areas[i]}'),
              style: style,
              onPressed: () => tabs.animateTo(i),
              child: label,
            ),
    );
  }
}
