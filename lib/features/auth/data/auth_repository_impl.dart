import '../../../core/network/network_status.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';
import 'auth_api.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required AuthApi api, required NetworkStatus network})
    : _api = api,
      _network = network;

  final AuthApi _api;
  final NetworkStatus _network;

  @override
  Future<AuthSession> login({
    required int login,
    required String password,
  }) async {
    await ensureOnline(_network);
    final tokens = await Future.wait<String>([
      _api.requestPeanutToken(login: login, password: password),
      _api.requestPartnerToken(login: login, password: password),
    ]);
    return AuthSession(
      login: login,
      peanutToken: tokens[0],
      partnerToken: tokens[1],
    );
  }
}
