import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hnd_charge_app/area_controller.dart';
import 'package:hnd_charge_app/station_config.dart';
import 'package:hnd_charge_app/station_service.dart';

Future<void> tick() => Future<void>.delayed(Duration.zero);
void main() {
  test('Configuration matches the 20 supplied station numbers', () {
    const suffixes = [
      '6899',
      '6900',
      '6902',
      '6934',
      '6933',
      '6906',
      '6893',
      '6904',
      '6894',
      '6897',
      '6903',
      '6895',
      '6898',
      '6907',
      '6909',
      '6890',
      '6896',
      '6901',
      '6908',
      '6905',
    ];
    expect(knownStations.map((s) => s.code), suffixes.map((s) => '2TH0001$s'));
    expect(knownStations.map((s) => s.number), List.generate(20, (i) => i + 1));
  });
  test('Five workers refill immediately; preserve order; suppress duplicate refresh', () async {
    final pending = <String, Completer<List<PortInfo>>>{};
    var active = 0;
    var peak = 0;
    final c = AreaController(
      loader: (code) async {
        active++;
        if (active > peak) peak = active;
        final p = Completer<List<PortInfo>>();
        pending[code] = p;
        try {
          return await p.future;
        } finally {
          active--;
        }
      },
    );
    final run = c.refresh();
    await c.refresh();
    expect(pending.length, 5);
    pending[knownStations[2].code]!.complete([const PortInfo(1, 1)]);
    await tick();
    expect(pending.length, 6);
    expect(c.completed, 1);
    expect(c.results[2].phase, QueryPhase.success);
    expect(c.results[0].phase, QueryPhase.loading);
    // One failed station must not prevent the remaining queue from finishing.
    pending[knownStations[0].code]!.completeError(
      const StationException('设备不在线'),
    );
    await tick();
    while (c.busy) {
      for (final p in pending.values.toList()) {
        if (!p.isCompleted) p.complete([const PortInfo(1, 2)]);
      }
      await tick();
    }
    await run;
    expect(peak, 5);
    expect(pending.length, 20);
    expect(c.completed, 20);
    expect(c.failed, 1);
    expect(c.succeeded, 19);
    expect(c.available, 1);
    expect(
      c.results.map((r) => r.station.number),
      List.generate(20, (i) => i + 1),
    );
    c.dispose();
  });
  test(
    'Refresh failure retains old ports and time but excludes them from totals',
    () async {
      var fail = false;
      final c = AreaController(
        loader: (_) async {
          if (fail) throw const StationException('超时');
          return [const PortInfo(1, 1)];
        },
      );
      await c.refresh();
      final previous = c.results.first.receivedAt;
      expect(c.available, 20);
      fail = true;
      await c.refresh();
      expect(c.failed, 20);
      expect(c.available, 0);
      expect(c.succeeded, 0);
      expect(c.results.first.ports!.first.state, 1);
      expect(c.results.first.receivedAt, previous);
      c.dispose();
    },
  );
  test('Dispose prevents queued dispatch and later notifications', () async {
    final pending = Completer<List<PortInfo>>();
    var calls = 0;
    final c = AreaController(
      loader: (_) {
        calls++;
        return pending.future;
      },
    );
    final run = c.refresh();
    c.dispose();
    pending.complete([const PortInfo(1, 1)]);
    await run;
    expect(calls, 5);
  });
}
