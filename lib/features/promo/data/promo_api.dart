import 'package:xml/xml.dart';

import '../../../core/config/api_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../domain/promo_material.dart';

class PromoApi {
  PromoApi(this._client);

  final ApiClient _client;

  static const _actions = <String>[
    'http://tempuri.org/ICabinetMicroService/GetCCPromo',
    'http://tempuri.org/CabinetMicroService/GetCCPromo',
    'http://tempuri.org/GetCCPromo',
  ];

  Future<List<PromoMaterial>> load() async {
    AppException? lastError;
    for (final action in _actions) {
      final response = await _client.postXml(
        '${ApiConfig.promoEndpoint}?lang=${ApiConfig.promoLanguage}',
        body: _envelope(ApiConfig.promoLanguage),
        headers: {
          'SOAPAction': '"$action"',
          'Accept': 'text/xml, application/xml',
        },
      );
      if (response.raw.trim().isEmpty) {
        lastError = const ServerException(
          'Promo materials are temporarily unavailable.',
        );
        continue;
      }
      final PromoEnvelope envelope;
      try {
        envelope = parsePromoEnvelope(response.raw);
      } on XmlException {
        throw const ServerException(
          'Promo materials came back in an unexpected format.',
        );
      }
      if (envelope.hasFault) {
        lastError = const ServerException(
          'Promo materials are temporarily unavailable.',
        );
        final fault = envelope.fault!.toLowerCase();
        final wrongAction =
            fault.contains('action') ||
            fault.contains('contract') ||
            fault.contains('not supported');
        if (wrongAction && action != _actions.last) continue;
        throw lastError;
      }
      if (response.isSuccess) return envelope.items;
      lastError = const ServerException(
        'Promo materials are temporarily unavailable.',
      );
    }
    throw lastError ??
        const ServerException('Promo materials are temporarily unavailable.');
  }

  String _envelope(String language) {
    final lang = language
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    return '''
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">
  <soap:Body>
    <tem:GetCCPromo>
      <tem:lang>$lang</tem:lang>
    </tem:GetCCPromo>
  </soap:Body>
</soap:Envelope>''';
  }
}
