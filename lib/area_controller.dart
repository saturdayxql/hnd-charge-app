import 'dart:async';

import 'package:flutter/foundation.dart';

import 'station_config.dart';
import 'station_service.dart';

enum QueryPhase { waiting, loading, success, failed }

class StationResult {
  StationResult(this.station);
  final StationConfig station;
  List<PortInfo>? ports;
  DateTime? receivedAt;
  String? error;
  QueryPhase phase = QueryPhase.waiting;
}

class AreaController extends ChangeNotifier {
  AreaController({this.loader = fetchStation});
  final Future<List<PortInfo>> Function(String) loader;
  static const concurrency = 5;
  String area = '创新大厦旁';
  List<StationResult> results = knownStations.map(StationResult.new).toList();
  bool busy = false;
  bool _closed = false;
  int completed = 0;
  int _generation = 0;
  int _active = 0;
  int _next = 0;
  Completer<void>? _done;
  int get succeeded =>
      results.where((r) => r.phase == QueryPhase.success).length;
  int get failed => results.where((r) => r.phase == QueryPhase.failed).length;
  int get available => results
      .where((r) => r.phase == QueryPhase.success)
      .expand((r) => r.ports ?? <PortInfo>[])
      .where((p) => p.state == 1)
      .length;

  Future<void> selectArea(String name) {
    if (_closed || name == area || !stationAreas.containsKey(name)) {
      return Future.value();
    }
    area = name;
    results = stationAreas[name]!.map(StationResult.new).toList();
    return _start();
  }

  Future<void> refresh() {
    if (busy || _closed) return Future.value();
    return _start();
  }

  Future<void> _start() {
    if (_done != null && !_done!.isCompleted) _done!.complete();
    final done = Completer<void>();
    _done = done;
    _generation++;
    _next = 0;
    completed = 0;
    busy = true;
    for (final r in results) {
      r.phase = QueryPhase.waiting;
      r.error = null;
    }
    notifyListeners();
    _pump();
    return done.future;
  }

  // 不同批次共用活动请求计数，切换后停止旧队列，空出的槽位用于新区域。
  void _pump() {
    if (_closed) return;
    while (_active < concurrency && _next < results.length) {
      final r = results[_next++];
      final generation = _generation;
      _active++;
      r.phase = QueryPhase.loading;
      notifyListeners();
      _query(r, generation);
    }
  }

  Future<void> _query(StationResult r, int generation) async {
    try {
      final ports = await loader(r.station.code);
      if (_closed || generation != _generation) return;
      r.ports = ports;
      r.receivedAt = DateTime.now();
      r.phase = QueryPhase.success;
    } catch (e) {
      if (_closed || generation != _generation) return;
      r.error = e is StationException ? e.message : '查询失败，请稍后重试';
      r.phase = QueryPhase.failed;
    } finally {
      _active--;
      if (!_closed) {
        if (generation == _generation) {
          completed++;
          if (completed == results.length) {
            busy = false;
            if (!_done!.isCompleted) _done!.complete();
          }
          notifyListeners();
        }
        _pump();
      }
    }
  }

  @override
  void dispose() {
    _closed = true;
    if (_done != null && !_done!.isCompleted) _done!.complete();
    super.dispose();
  }
}
