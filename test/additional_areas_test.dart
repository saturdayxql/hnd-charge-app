import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hnd_charge_app/area_controller.dart';
import 'package:hnd_charge_app/main.dart';
import 'package:hnd_charge_app/station_config.dart';
import 'package:hnd_charge_app/station_service.dart';

void main() {
  test('New configurations match source and all 40 devices are unique', () {
    expect(diningStations.map((s) => s.code), [
      '4GR00009820',
      '4GR00009377',
      '4GR00009460',
      '4GR00009456',
      '4GR00009381',
      '4GR00009366',
    ]);
    expect(administrationStations.map((s) => s.code), [
      '4GR00009364',
      '4GR00009822',
    ]);
    final all = stationAreas.values.expand((s) => s).toList();
    expect(all.length, 40);
    expect(all.map((s) => s.code).toSet().length, 40);
  });
  test(
    'Small regions complete correctly and refresh only the current area',
    () async {
      final calls = <String>[];
      final c = AreaController(
        loader: (code) async {
          calls.add(code);
          return List.generate(10, (i) => PortInfo(i, 1));
        },
      );
      for (final name in ['二餐', '行政楼']) {
        calls.clear();
        await c.selectArea(name);
        final expected = stationAreas[name]!;
        expect(calls, expected.map((s) => s.code));
        expect(c.completed, expected.length);
        expect(c.available, expected.length * 10);
        calls.clear();
        await c.refresh();
        expect(calls, expected.map((s) => s.code));
      }
      c.dispose();
    },
  );
  testWidgets('Picker supports dining and administration with correct totals', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StationPage(loader: (_) async => [const PortInfo(0, 1)]),
      ),
    );
    await tester.pumpAndSettle();
    for (final name in ['二餐', '行政楼']) {
      await tester.tap(find.byKey(ValueKey('area-$name')));
      await tester.pumpAndSettle();
      final count = stationAreas[name]!.length;
      expect(find.text('已完成 $count/$count · 成功 $count · 失败 0'), findsOneWidget);
      expect(
        tester
            .widget<SegmentedButton<bool>>(find.byType(SegmentedButton<bool>))
            .segments
            .last
            .enabled,
        isFalse,
      );
      expect(find.text('0'), findsWidgets);
      expect(tester.takeException(), isNull);
    }
  });
}
