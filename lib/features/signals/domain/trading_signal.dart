import 'package:equatable/equatable.dart';

import '../../../core/config/api_config.dart';

class TradingSignal extends Equatable {
  const TradingSignal({
    required this.pair,
    required this.direction,
    this.price,
    this.takeProfit,
    this.stopLoss,
    this.openedAt,
    this.period,
    this.comment,
    this.id,
  });

  final String pair;
  final String direction;
  final double? price;
  final double? takeProfit;
  final double? stopLoss;
  final DateTime? openedAt;
  final String? period;
  final String? comment;
  final String? id;

  factory TradingSignal.fromJson(Map<dynamic, dynamic> json) {
    final data = <String, dynamic>{
      for (final entry in json.entries)
        '${entry.key}'.toLowerCase(): entry.value,
    };
    final command =
        data['cmd'] ?? data['command'] ?? data['action'] ?? data['type'];
    return TradingSignal(
      id: _text(data['id'] ?? data['signalid']),
      pair: _text(data['pair'] ?? data['symbol'] ?? data['pairs']) ?? 'Pair',
      direction: _direction(command),
      price: _double(data['openprice'] ?? data['price'] ?? data['priceopen']),
      takeProfit: _double(data['tp'] ?? data['takeprofit']),
      stopLoss: _double(data['sl'] ?? data['stoploss']),
      openedAt: _time(
        data['opentime'] ?? data['actualtime'] ?? data['time'] ?? data['date'],
      ),
      period: _text(data['period'] ?? data['timeframe']),
      comment: _text(data['comment'] ?? data['description'] ?? data['text']),
    );
  }

  @override
  List<Object?> get props => [
    pair,
    direction,
    price,
    takeProfit,
    stopLoss,
    openedAt,
    period,
    comment,
    id,
  ];
}

List<TradingSignal> parseSignals(Object? data) {
  final list = switch (data) {
    List<dynamic> values => values,
    Map<dynamic, dynamic> map => _listFromMap(map) ?? _single(map),
    _ => const <dynamic>[],
  };
  return [
    for (final item in list)
      if (item is Map) TradingSignal.fromJson(item),
  ];
}

Uri buildSignalsUri({
  required int login,
  required List<String> pairs,
  required DateTime from,
  required DateTime to,
}) {
  return Uri.parse('${ApiConfig.signalsRoot}/$login').replace(
    queryParameters: {
      'tradingsystem': '${ApiConfig.tradingSystem}',
      'pairs': pairs.join(','),
      'from': '${from.toUtc().millisecondsSinceEpoch ~/ 1000}',
      'to': '${to.toUtc().millisecondsSinceEpoch ~/ 1000}',
    },
  );
}

List<dynamic>? _listFromMap(Map<dynamic, dynamic> map) {
  for (final value in map.values) {
    if (value is List) return value;
  }
  return null;
}

List<dynamic> _single(Map<dynamic, dynamic> map) {
  final keys = map.keys.map((key) => '$key'.toLowerCase());
  if (keys.contains('pair') ||
      keys.contains('symbol') ||
      keys.contains('cmd')) {
    return [map];
  }
  return const [];
}

String _direction(Object? command) {
  final number = command is num
      ? command.toInt()
      : int.tryParse('${command ?? ''}');
  if (number == 0) return 'Buy';
  if (number == 1) return 'Sell';
  final text = _text(command);
  if (text == null) return 'Signal';
  final lower = text.toLowerCase();
  if (lower == 'buy' || lower == 'sell') {
    return '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
  }
  return text;
}

String? _text(Object? value) {
  if (value == null) return null;
  final text = '$value'.trim();
  if (text.isEmpty || text == 'null') return null;
  return text;
}

double? _double(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

DateTime? _time(Object? value) {
  if (value == null) return null;
  if (value is num) return _fromEpoch(value.toInt());
  final text = '$value'.trim();
  final dotted = RegExp(r'/Date\((-?\d+)').firstMatch(text);
  if (dotted != null) {
    return DateTime.fromMillisecondsSinceEpoch(
      int.parse(dotted.group(1)!),
      isUtc: true,
    ).toLocal();
  }
  final asInt = int.tryParse(text);
  if (asInt != null) return _fromEpoch(asInt);
  return DateTime.tryParse(text)?.toLocal();
}

DateTime? _fromEpoch(int value) {
  if (value <= 0) return null;
  final millis = value > 100000000000 ? value : value * 1000;
  return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal();
}
