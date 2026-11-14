import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hnd_charge_app/area_controller.dart';
import 'package:hnd_charge_app/main.dart';
import 'package:hnd_charge_app/station_config.dart';
import 'package:hnd_charge_app/station_service.dart';

void main() {
  test('Area switches while loading, ignores old responses and queries only new queue', () async {
    final gate = Completer<List<PortInfo>>();
    var blocked = true;
    final calls = <String>[];
    final c = AreaController(
      loader: (code) {
        calls.add(code);
        return blocked ? gate.future : Future.value([const PortInfo(1, 1)]);
      },
    );
    final first = c.refresh();
    final switched = c.selectArea('兰亭');
    expect(c.area, '兰亭');
    expect(c.completed, 0);
    expect(calls.length, 5);
    blocked = false;
    gate.complete([const PortInfo(1, 2)]);
    await first;
    await switched;
    expect(calls.take(5), knownStations.take(5).map((s) => s.code));
    expect(calls.skip(5), lantingStations.map((s) => s.code));
    expect(c.completed, 12);
    expect(c.available, 12);
    expect(c.results.every((r) => r.station.area == '兰亭'), isTrue);
    calls.clear();
    await c.refresh();
    expect(calls.length, 12);
    expect(calls.toSet(), lantingStations.map((s) => s.code).toSet());
    await c.selectArea('创新大厦旁');
    expect(c.results.length, 20);
    c.dispose();
  });
  testWidgets(
    'Region picker shows 12-station progress and disables missing map',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: StationPage(
            loader: (_) async {
              calls++;
              return [const PortInfo(1, 1)];
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('area-兰亭')));
      await tester.pumpAndSettle();
      expect(calls, 32);
      expect(find.text('已完成 12/12 · 成功 12 · 失败 0'), findsOneWidget);
      expect(
        tester
            .widget<SegmentedButton<bool>>(find.byType(SegmentedButton<bool>))
            .segments
            .last
            .enabled,
        isFalse,
      );
      await tester.scrollUntilVisible(
        find.text('12号桩'),
        400,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('station-list')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('12号桩'));
      await tester.pumpAndSettle();
      expect(find.text('设备编号：4GR00007973'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
