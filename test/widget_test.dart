import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hnd_charge_app/main.dart';
import 'package:hnd_charge_app/area_controller.dart';
import 'package:hnd_charge_app/station_config.dart';
import 'package:hnd_charge_app/station_service.dart';

void main() {
  test('Parser retains actual numbers and rejects invalid data', () {
    expect(
      parsePorts({
        'code': 200,
        'data': [
          {'num': 8, 'state': 3},
          {'num': 2, 'state': 99},
        ],
      }).map((p) => p.number),
      [2, 8],
    );
    expect(
      () => parsePorts({'code': 200, 'data': []}),
      throwsA(isA<StationException>()),
    );
    expect(
      () => parsePorts({'code': 500, 'msg': '设备不在线'}),
      throwsA(isA<StationException>()),
    );
  });
  testWidgets('Overview loads 20 devices and scrolls to the last card', (
    tester,
  ) async {
    final calls = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: StationPage(
          loader: (code) async {
            calls.add(code);
            return List.generate(10, (i) => PortInfo(i + 1, i == 0 ? 1 : 2));
          },
        ),
      ),
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('refresh-all')))
          .onPressed,
      isNull,
    );
    await tester.pumpAndSettle();
    expect(calls.length, 20);
    expect(find.text('已完成 20/20 · 成功 20 · 失败 0'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('20号桩'),
      600,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 30,
    );
    await tester.tap(find.text('20号桩'));
    await tester.pumpAndSettle();
    expect(find.text('设备编号：2TH00016905'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Narrow large-text stale failure card stays readable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final r = StationResult(knownStations.first)
      ..phase = QueryPhase.failed
      ..error = '设备不在线'
      ..ports = List.generate(10, (i) => PortInfo(i + 1, 3))
      ..receivedAt = DateTime.now();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(child: StationCard(result: r)),
          ),
        ),
      ),
    );
    expect(find.textContaining('以下为上次结果'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
