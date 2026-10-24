import 'promo_material.dart';

abstract class PromoRepository {
  Future<List<PromoMaterial>> load();
}
