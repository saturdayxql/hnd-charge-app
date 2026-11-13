import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hnd_charge_app/area_controller.dart';
import 'package:hnd_charge_app/main.dart';
import 'package:hnd_charge_app/station_config.dart';
import 'package:hnd_charge_app/station_service.dart';

void main() {
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
}
