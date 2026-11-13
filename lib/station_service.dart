import 'dart:async';
import 'dart:convert';
import 'dart:io';

class StationException implements Exception {
  const StationException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PortInfo {
  const PortInfo(this.number, this.state);
  final int number;
  final int? state;
}

// 校验业务结果并使用真实 num 排序，不用列表下标替代插口编号。
List<PortInfo> parsePorts(dynamic result) {
  if (result is! Map<String, dynamic>) {
    throw const StationException('平台返回的数据格式异常');
  }
  if (result['code'] != 200) {
    throw StationException('平台提示：${result['msg'] ?? '查询失败'}');
  }
  final data = result['data'];
  if (data is! List || data.isEmpty) {
    throw const StationException('平台没有返回有效的插口列表');
  }
  final seen = <int>{};
  final ports = <PortInfo>[];
  for (final item in data) {
    if (item is! Map<String, dynamic>) {
      throw const StationException('插口记录格式异常');
    }
    final num = item['num'];
    if (num is! int || num < 0 || !seen.add(num)) {
      throw const StationException('插口编号缺失、重复或不合法');
    }
    ports.add(
      PortInfo(num, item['state'] is int ? item['state'] as int : null),
    );
  }
  ports.sort((a, b) => a.number.compareTo(b.number));
  return ports;
}

// 使用 Dart 自带网络库，当前针对 Android，不是网页实现。
Future<List<PortInfo>> fetchStation(String stationCode) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    return await (() async {
      final request = await client.postUrl(
        Uri.parse('https://wx.isfdz.com/api/equi/afterProtocol/getLineInfo'),
      );
      request.followRedirects = false;
      request.headers.contentType = ContentType(
        'application',
        'json',
        charset: 'utf-8',
      );
      request.headers.set('Origin', 'https://wx.isfdz.com');
      request.headers.set('Referer', 'https://wx.isfdz.com/');
      request.headers.set('User-Agent', 'Mozilla/5.0');
      request.write(
        jsonEncode({
          'code': stationCode,
          'parentCode': null,
          'timestamp': (DateTime.now().millisecondsSinceEpoch ~/ 1000)
              .toString(),
        }),
      );
      final response = await request.close();
      if (response.statusCode != 200) {
        throw StationException('服务器返回 HTTP ${response.statusCode}');
      }
      final text = await utf8.decoder.bind(response).join();
      return parsePorts(jsonDecode(text));
    })().timeout(const Duration(seconds: 15));
  } on TimeoutException {
    throw const StationException('查询超时，请稍后重试');
  } on HandshakeException {
    throw const StationException('安全连接验证失败，请检查网络');
  } on SocketException {
    throw const StationException('无法连接平台，请检查网络');
  } on HttpException {
    throw const StationException('网络响应中断，请重试');
  } on FormatException {
    throw const StationException('平台返回内容无法解析');
  } finally {
    // 成功、失败和总超时都释放连接；不自动重试。
    client.close(force: true);
  }
}
