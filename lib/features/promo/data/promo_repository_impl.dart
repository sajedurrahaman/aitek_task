import '../../../core/network/network_status.dart';
import '../domain/promo_material.dart';
import '../domain/promo_repository.dart';
import 'promo_api.dart';

class PromoRepositoryImpl implements PromoRepository {
  PromoRepositoryImpl({required PromoApi api, required NetworkStatus network})
    : _api = api,
      _network = network;

  final PromoApi _api;
  final NetworkStatus _network;

  @override
  Future<List<PromoMaterial>> load() async {
    await ensureOnline(_network);
    return _api.load();
  }
}
