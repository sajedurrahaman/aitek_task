import 'trading_signal.dart';

abstract class SignalsRepository {
  Future<List<TradingSignal>> load({
    required int login,
    required String partnerToken,
    required List<String> pairs,
    required DateTime from,
    required DateTime to,
  });
}
