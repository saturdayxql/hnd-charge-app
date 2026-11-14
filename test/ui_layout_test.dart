import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hnd_charge_app/area_controller.dart';
import 'package:hnd_charge_app/main.dart';
import 'package:hnd_charge_app/station_card.dart';
import 'package:hnd_charge_app/station_config.dart';
import 'package:hnd_charge_app/station_service.dart';
import 'package:hnd_charge_app/status_style.dart';

void main() {
  test('Station level uses only current success and keeps red as no-free', () {
    StationLevel level(QueryPhase phase, List<int?> states) => stationLevelOf(
      StationResult(knownStations.first)
        ..phase = phase
        ..ports = [
          for (var i = 0; i < states.length; i++) PortInfo(i, states[i]),
        ],
    );
    expect(level(QueryPhase.success, [2, 1, 3]), StationLevel.free);
    expect(level(QueryPhase.success, [2, null, 3]), StationLevel.uncertain);
    expect(level(QueryPhase.success, [2, 3, 2]), StationLevel.full);
    // Old free ports from a failed or pending refresh must not look current.
    expect(level(QueryPhase.failed, [1, 1]), StationLevel.pending);
    expect(level(QueryPhase.loading, [1, 1]), StationLevel.pending);
  });
  testWidgets('All failures show unknown summary instead of zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StationPage(
          loader: (_) async => throw const StationException('设备不在线'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('本轮空闲数量未知'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('个可用插口'), findsNothing);
    expect(find.text('已完成 20/20 · 成功 0 · 失败 20'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Narrow large-text success card with free ports stays readable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final r = StationResult(knownStations.first)
      ..phase = QueryPhase.success
      ..ports = List.generate(10, (i) => PortInfo(i, i < 3 ? 1 : 2))
      ..receivedAt = DateTime.now();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: StationCard(result: r, initiallyExpanded: true),
            ),
          ),
        ),
      ),
    );
    expect(find.text('可用 3/10'), findsOneWidget);
    expect(find.text('可用插口：0、1、2'), findsOneWidget);
    expect(find.textContaining('以下为上次结果'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Swiping the page switches area once after it settles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final calls = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: StationPage(
          loader: (code) async {
            calls.add(code);
            return [const PortInfo(1, 1)];
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls.length, 20);
    // A drag that is still in progress must not start a new area query.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(TabBarView)),
    );
    await gesture.moveBy(const Offset(-50, 0));
    await gesture.moveBy(const Offset(-150, 0));
    await tester.pump();
    expect(find.text('停稳后开始查询'), findsOneWidget);
    expect(calls.length, 20);
    await gesture.moveBy(const Offset(-150, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(calls.skip(20), lantingStations.map((s) => s.code));
    expect(find.text('已完成 12/12 · 成功 12 · 失败 0'), findsOneWidget);
    expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Large text turns the area bar into buttons without overflow', (
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
              return List.generate(10, (i) => PortInfo(i, i < 2 ? 1 : 2));
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TabBar), findsNothing);
    for (final area in stationAreas.keys) {
      expect(find.byKey(ValueKey('area-$area')), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('area-二餐')));
    await tester.pumpAndSettle();
    expect(calls, 26);
    expect(find.text('已完成 6/6 · 成功 6 · 失败 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Normal text keeps all four areas in one row', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: StationPage(loader: (_) async => [const PortInfo(1, 1)]),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TabBar), findsOneWidget);
    final first = tester.getRect(find.byKey(const ValueKey('area-创新大厦旁')));
    final last = tester.getRect(find.byKey(const ValueKey('area-行政楼')));
    expect(first.top, last.top);
    expect(last.right, lessThanOrEqualTo(360));
    expect(tester.takeException(), isNull);
  });
  testWidgets('Overview cell scrolls to its card without new requests', (
    tester,
  ) async {
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
    final card = find.text('18号桩');
    expect(tester.getRect(card).top, greaterThan(780));
    await tester.tap(find.byKey(const ValueKey('overview-18')));
    await tester.pumpAndSettle();
    final rect = tester.getRect(card);
    expect(rect.top, greaterThan(0));
    expect(
      rect.bottom,
      lessThan(tester.getTopLeft(find.byKey(const Key('bottom-bar'))).dy),
    );
    expect(calls, 20);
    expect(tester.takeException(), isNull);
  });
}
