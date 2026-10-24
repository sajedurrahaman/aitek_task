import 'package:equatable/equatable.dart';

class AccountProfile extends Equatable {
  const AccountProfile({
    this.name,
    this.address,
    this.city,
    this.country,
    this.zipCode,
    this.currencyCode,
    this.balance,
    this.equity,
    this.freeMargin,
    this.leverage,
    this.currentTradesCount,
    this.currentTradesVolume,
    this.totalTradesCount,
    this.totalTradesVolume,
    this.isAnyOpenTrades,
    this.isSwapFree,
    this.type,
    this.verificationLevel,
  });

  final String? name;
  final String? address;
  final String? city;
  final String? country;
  final String? zipCode;
  final int? currencyCode;
  final double? balance;
  final double? equity;
  final double? freeMargin;
  final int? leverage;
  final int? currentTradesCount;
  final double? currentTradesVolume;
  final int? totalTradesCount;
  final double? totalTradesVolume;
  final bool? isAnyOpenTrades;
  final bool? isSwapFree;
  final int? type;
  final int? verificationLevel;

  /// The OpenAPI enum is numeric only. These labels follow that order,
  /// with `0` shown as USD to match the documented sample account.
  String get currencyLabel {
    const labels = {0: 'USD', 1: 'EUR', 2: 'RUB', 3: 'GBP', 4: 'JPY'};
    final code = currencyCode;
    if (code == null) return '';
    return labels[code] ?? 'Code $code';
  }

  static AccountProfile? tryParse(Object? data) {
    if (data is! Map) return null;
    final json = <String, dynamic>{
      for (final entry in data.entries) '${entry.key}': entry.value,
    };
    if (!json.keys.any(
      (key) =>
          key.toLowerCase() == 'balance' ||
          key.toLowerCase() == 'name' ||
          key.toLowerCase() == 'equity',
    )) {
      return null;
    }
    String? text(String key) {
      final value = _read(json, key);
      if (value == null) return null;
      final asText = '$value'.trim();
      return asText.isEmpty ? null : asText;
    }

    return AccountProfile(
      name: text('name'),
      address: text('address'),
      city: text('city'),
      country: text('country'),
      zipCode: text('zipCode'),
      currencyCode: _asInt(_read(json, 'currency')),
      balance: _asDouble(_read(json, 'balance')),
      equity: _asDouble(_read(json, 'equity')),
      freeMargin: _asDouble(_read(json, 'freeMargin')),
      leverage: _asInt(_read(json, 'leverage')),
      currentTradesCount: _asInt(_read(json, 'currentTradesCount')),
      currentTradesVolume: _asDouble(_read(json, 'currentTradesVolume')),
      totalTradesCount: _asInt(_read(json, 'totalTradesCount')),
      totalTradesVolume: _asDouble(_read(json, 'totalTradesVolume')),
      isAnyOpenTrades: _asBool(_read(json, 'isAnyOpenTrades')),
      isSwapFree: _asBool(_read(json, 'isSwapFree')),
      type: _asInt(_read(json, 'type')),
      verificationLevel: _asInt(_read(json, 'verificationLevel')),
    );
  }

  @override
  List<Object?> get props => [
    name,
    address,
    city,
    country,
    zipCode,
    currencyCode,
    balance,
    equity,
    freeMargin,
    leverage,
    currentTradesCount,
    currentTradesVolume,
    totalTradesCount,
    totalTradesVolume,
    isAnyOpenTrades,
    isSwapFree,
    type,
    verificationLevel,
  ];
}

String parsePhoneBody(Object? data) {
  if (data is String) return data.trim().replaceAll('"', '');
  if (data is num) return '$data';
  if (data is Map) {
    for (final entry in data.entries) {
      final key = '${entry.key}'.toLowerCase();
      if (key.contains('phone') || key == 'result' || key == 'value') {
        final text = '${entry.value}'.trim();
        if (text.isNotEmpty && text != 'null') return text;
      }
    }
  }
  return '';
}

Object? _read(Map<String, dynamic> json, String key) {
  for (final entry in json.entries) {
    if (entry.key.toLowerCase() == key.toLowerCase()) return entry.value;
  }
  return null;
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

bool? _asBool(Object? value) {
  if (value is bool) return value;
  if (value is String) {
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
  }
  return null;
}
