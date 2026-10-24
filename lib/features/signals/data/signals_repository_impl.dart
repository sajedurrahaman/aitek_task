import '../../../core/network/network_status.dart';
import '../domain/signals_repository.dart';
import '../domain/trading_signal.dart';
import 'signals_api.dart';

class SignalsRepositoryImpl implements SignalsRepository {
  SignalsRepositoryImpl({
    required SignalsApi api,
    required NetworkStatus network,
  }) : _api = api,
       _network = network;

  final SignalsApi _api;
  final NetworkStatus _network;

  @override
  Future<List<TradingSignal>> load({
    required int login,
    required String partnerToken,
    required List<String> pairs,
    required DateTime from,
    required DateTime to,
  }) async {
    await ensureOnline(_network);
    return _api.load(
      login: login,
      partnerToken: partnerToken,
      pairs: pairs,
      from: from,
      to: to,
    );
  }
}
