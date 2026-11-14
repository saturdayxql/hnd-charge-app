import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hnd_charge_app/area_controller.dart';
import 'package:hnd_charge_app/main.dart';
import 'package:hnd_charge_app/station_card.dart';
import 'package:hnd_charge_app/station_config.dart';
import 'package:hnd_charge_app/station_service.dart';
import 'package:hnd_charge_app/status_style.dart';

// Group widgets by their top edge: each distinct dy is one visual row.
List<int> rowSizes(WidgetTester tester, Iterable<Key> keys) {
  final rows = <double, int>{};
  for (final key in keys) {
    final dy = tester.getTopLeft(find.byKey(key)).dy;
    rows[dy] = (rows[dy] ?? 0) + 1;
  }
  final sorted = rows.keys.toList()..sort();
  return [for (final dy in sorted) rows[dy]!];
}

Future<void> setView(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget cardApp(StationResult r, double scale) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: Scaffold(
      body: SingleChildScrollView(child: StationCard(result: r)),
    ),
  ),
);

void main() {
  test('fitColumns prefers 10 and only drops when cells get too narrow', () {
    expect(fitColumns(316, 3, 22), 10);
    expect(fitColumns(316, 3, 28.8), 10);
    expect(fitColumns(316, 3, 29), 9);
    expect(fitColumns(316, 3, 40), 7);
    expect(fitColumns(10, 3, 40), 1);
  });

  for (final start in [0, 1]) {
    testWidgets('Ten ports numbered from $start stay in one row', (
      tester,
    ) async {
      await setView(tester, 440);
      final r = StationResult(knownStations.first)
        ..phase = QueryPhase.success
        ..ports = List.generate(
          10,
          (i) => PortInfo(i + start, i.isEven ? 1 : 2),
        )
        ..receivedAt = DateTime.now();
      await tester.pumpWidget(cardApp(r, 1));
      expect(
        rowSizes(tester, [
          for (var i = 0; i < 10; i++) ValueKey('port-${i + start}'),
        ]),
        [10],
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Large text wraps ports instead of shrinking them', (
    tester,
  ) async {
    await setView(tester, 320);
    final r = StationResult(knownStations.first)
      ..phase = QueryPhase.success
      ..ports = List.generate(10, (i) => PortInfo(i, 2))
      ..receivedAt = DateTime.now();
    await tester.pumpWidget(cardApp(r, 2));
    final rows = rowSizes(tester, [
      for (var i = 0; i < 10; i++) ValueKey('port-$i'),
    ]);
    expect(rows.length, greaterThan(1));
    expect(rows.reduce((a, b) => a + b), 10);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Overview shows 20 stations as two rows of ten', (tester) async {
    await setView(tester, 440);
    await tester.pumpWidget(
      MaterialApp(
        home: StationPage(
          // Ten free ports produces the widest tag, 空10.
          loader: (_) async => List.generate(10, (i) => PortInfo(i, 1)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('空10'), findsWidgets);
    expect(
      rowSizes(tester, [for (var n = 1; n <= 20; n++) ValueKey('overview-$n')]),
      [10, 10],
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Overview of 12 stations uses ten then two', (tester) async {
    await setView(tester, 440);
    await tester.pumpWidget(
      MaterialApp(
        home: StationPage(loader: (_) async => [const PortInfo(1, 1)]),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('area-兰亭')));
    await tester.pumpAndSettle();
    expect(
      rowSizes(tester, [for (var n = 1; n <= 12; n++) ValueKey('overview-$n')]),
      [10, 2],
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Large text overview wraps to fewer columns without overflow', (
    tester,
  ) async {
    await setView(tester, 360);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 900),
            textScaler: TextScaler.linear(2),
          ),
          child: StationPage(
            loader: (_) async => List.generate(10, (i) => PortInfo(i, 1)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final rows = rowSizes(tester, [
      for (var n = 1; n <= 20; n++) ValueKey('overview-$n'),
    ]);
    expect(rows.length, greaterThan(2));
    expect(rows.every((size) => size < 10), isTrue);
    expect(tester.takeException(), isNull);
  });
}
