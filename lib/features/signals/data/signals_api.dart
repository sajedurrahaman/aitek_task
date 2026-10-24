import '../../../core/error/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../domain/trading_signal.dart';

class SignalsApi {
  SignalsApi(this._client);

  final ApiClient _client;

  Future<List<TradingSignal>> load({
    required int login,
    required String partnerToken,
    required List<String> pairs,
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await _client.get(
      buildSignalsUri(login: login, pairs: pairs, from: from, to: to),
      headers: {'passkey': partnerToken},
    );
    if (response.isSuccess) return parseSignals(response.data);
    if (responseDeniesAccess(response)) throw const UnauthorizedException();
    if (response.statusCode >= 500 && response.raw.trim().isEmpty) {
      throw const ServerException(
        'The signals service could not return this archive. Try fewer pairs or a shorter date range.',
      );
    }
    throw const ServerException(
      'Signals could not be loaded. Please try again.',
    );
  }
}
