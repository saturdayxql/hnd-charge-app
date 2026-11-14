import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hnd_charge_app/area_controller.dart';
import 'package:hnd_charge_app/main.dart';
import 'package:hnd_charge_app/station_service.dart';

void main() {
  test('Legacy 0-9 and new 1-10 numbering are retained exactly', () {
    for (final start in [0, 1]) {
      final result = parsePorts({
        'code': 200,
        'data': List.generate(10, (i) => {'num': i + start, 'state': 2}),
      });
      expect(result.map((p) => p.number), List.generate(10, (i) => i + start));
    }
    for (final nums in [
      [-1, 0],
      [0, 0],
    ]) {
      expect(
        () => parsePorts({
          'code': 200,
          'data': nums.map((n) => {'num': n, 'state': 1}).toList(),
        }),
        throwsA(isA<StationException>()),
      );
    }
  });
  test(
    'Rapid switching retains global concurrency and drops stale success/error',
    () async {
      final pending = <Completer<List<PortInfo>>>[];
      var active = 0, peak = 0;
      final c = AreaController(
        loader: (_) async {
          active++;
          if (active > peak) peak = active;
          final p = Completer<List<PortInfo>>();
          pending.add(p);
          try {
            return await p.future;
          } finally {
            active--;
          }
        },
      );
      final first = c.refresh();
      final second = c.selectArea('兰亭');
      final third = c.selectArea('创新大厦旁');
      final fourth = c.selectArea('兰亭');
      expect(pending.length, 5);
      pending[0].completeError(const StationException('旧区域失败'));
      for (final p in pending.skip(1).toList()) {
        p.complete([const PortInfo(99, 1)]);
      }
      await Future<void>.delayed(Duration.zero);
      expect(c.completed, 0);
      expect(
        c.results.every((r) => r.ports == null && r.error == null),
        isTrue,
      );
      while (c.busy) {
        for (final p in pending.toList()) {
          if (!p.isCompleted) p.complete([const PortInfo(0, 2)]);
        }
        await Future<void>.delayed(Duration.zero);
      }
      await Future.wait([first, second, third, fourth]);
      expect(peak, 5);
      expect(pending.length, 17);
      expect(c.completed, 12);
      expect(c.available, 0);
      expect(c.failed, 0);
      c.dispose();
    },
  );
  testWidgets(
    'Picker remains usable during requests and clears old view immediately',
    (tester) async {
      final pending = Completer<List<PortInfo>>();
      await tester.pumpWidget(
        MaterialApp(home: StationPage(loader: (_) => pending.future)),
      );
      // Tap while the first area is still loading; let the tab animation end.
      await tester.tap(find.byKey(const ValueKey('area-兰亭')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('已完成 0/12 · 成功 0 · 失败 0'), findsOneWidget);
      expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 1);
      pending.complete(List.generate(10, (i) => PortInfo(i, 2)));
      await tester.pumpAndSettle();
      expect(find.text('已完成 12/12 · 成功 12 · 失败 0'), findsOneWidget);
      expect(find.text('0'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
