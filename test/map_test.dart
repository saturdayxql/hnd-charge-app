import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hnd_charge_app/main.dart';
import 'package:hnd_charge_app/station_map.dart';
import 'package:hnd_charge_app/station_service.dart';

void main() {
  testWidgets(
    'Map switches without requests and selects correct station detail',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: StationPage(
            loader: (_) async {
              calls++;
              return List.generate(10, (i) => PortInfo(i + 1, i == 0 ? 1 : 2));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, 20);
      await tester.tap(find.text('位置图'));
      await tester.pumpAndSettle();
      expect(find.byType(StationMap), findsOneWidget);
      expect(calls, 20);
      final map = find.byType(StationMap);
      final a = tester.getTopLeft(find.byKey(const ValueKey('map-station-1')));
      final b = tester.getTopLeft(find.byKey(const ValueKey('map-station-20')));
      final c = tester.getTopLeft(find.byKey(const ValueKey('map-station-2')));
      expect(a.dx, b.dx);
      expect(a.dy, lessThan(b.dy));
      expect(a.dx, lessThan(c.dx));
      await tester.tap(find.byKey(const ValueKey('map-station-20')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('设备编号：2TH00016905'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('设备编号：2TH00016905'), findsOneWidget);
      expect(calls, 20);
      await tester.tap(find.text('列表'));
      await tester.pumpAndSettle();
      expect(map, findsNothing);
      expect(calls, 20);
      expect(tester.takeException(), isNull);
    },
  );
}
