import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hnd_charge_app/area_controller.dart';
import 'package:hnd_charge_app/main.dart';
import 'package:hnd_charge_app/station_config.dart';
import 'package:hnd_charge_app/station_map.dart';
import 'package:hnd_charge_app/station_service.dart';

void main() {
  testWidgets(
    'Map switches without requests and selects correct station detail',
    (tester) async {
      tester.view.physicalSize = const Size(390, 780);
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
      // Selected station usage must be on the same screen as the map.
      expect(find.text('设备编号：2TH00016905'), findsOneWidget);
      expect(
        tester.getRect(find.text('设备编号：2TH00016905')).bottom,
        lessThanOrEqualTo(
          tester.getTopLeft(find.byKey(const Key('bottom-bar'))).dy,
        ),
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('map-station-20'))).top,
        greaterThanOrEqualTo(0),
      );
      // Page swipe is disabled on the map so dragging it never switches area.
      await tester.drag(
        find.byKey(const Key('map-page')),
        const Offset(-300, 0),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 0);
      expect(calls, 20);
      await tester.tap(find.text('列表'));
      await tester.pumpAndSettle();
      expect(map, findsNothing);
      expect(calls, 20);
      expect(tester.takeException(), isNull);
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets('Map roads remain connected and clear at text scale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(660, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final results = knownStations
          .map(
            (station) => StationResult(station)
              ..phase = QueryPhase.success
              ..ports = [const PortInfo(0, 1)],
          )
          .toList();
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(660, 900),
              textScaler: TextScaler.linear(scale),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: StationMap(
                  results: results,
                  selected: 1,
                  onSelected: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Rect rect(String key) => tester.getRect(find.byKey(ValueKey(key)));
      final northRoad = rect('map-north-road');
      final southRoad = rect('map-south-road');
      final eastRoad = rect('map-east-road');
      final belt = rect('map-belt');
      expect(belt.bottom, lessThanOrEqualTo(southRoad.top));
      expect(belt.overlaps(southRoad), isFalse);
      expect(northRoad.right, greaterThanOrEqualTo(eastRoad.right));
      expect(southRoad.right, greaterThanOrEqualTo(eastRoad.right));
      for (var number = 1; number <= 10; number++) {
        final north = rect('map-station-$number');
        final south = rect('map-station-${21 - number}');
        expect(north.left, south.left);
        expect(north.top, greaterThanOrEqualTo(northRoad.bottom));
        expect(north.bottom, lessThan(south.top));
        expect(south.bottom, lessThanOrEqualTo(southRoad.top));
      }
      for (var group = 0; group < 4; group++) {
        final aisle = rect('map-aisle-$group');
        expect(aisle.top, closeTo(northRoad.bottom, 0.01));
        expect(aisle.bottom, closeTo(southRoad.top, 0.01));
        final leftStation = rect('map-station-${group * 2 + 2}');
        final rightStation = rect('map-station-${group * 2 + 3}');
        expect(leftStation.right, lessThanOrEqualTo(aisle.left));
        expect(aisle.right, lessThanOrEqualTo(rightStation.left));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Large-text map stays readable and selected details can scroll', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 780),
            textScaler: TextScaler.linear(2),
          ),
          child: StationPage(
            loader: (_) async {
              calls++;
              return List.generate(10, (i) => PortInfo(i, 1));
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 20);
    await tester.tap(find.text('位置图'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      MediaQuery.textScalerOf(tester.element(find.byType(StationMap)))
          .scale(12),
      24,
    );
    final mapScrollable = find
        .descendant(
          of: find.byKey(const Key('map-page')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('map-station-20')),
      150,
      scrollable: mapScrollable,
    );
    await tester.tap(find.byKey(const ValueKey('map-station-20')));
    await tester.pumpAndSettle();
    final detail = find.text('设备编号：2TH00016905');
    await tester.scrollUntilVisible(
      detail,
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('map-page')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(
      tester.getRect(detail).bottom,
      lessThanOrEqualTo(
        tester.getTopLeft(find.byKey(const Key('bottom-bar'))).dy,
      ),
    );
    expect(calls, 20);
    expect(tester.takeException(), isNull);
  });
}
