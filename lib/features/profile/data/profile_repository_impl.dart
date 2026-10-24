import '../../../core/network/network_status.dart';
import '../../auth/domain/auth_session.dart';
import '../domain/account_profile.dart';
import '../domain/profile_repository.dart';
import 'profile_api.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({
    required ProfileApi api,
    required NetworkStatus network,
  }) : _api = api,
       _network = network;

  final ProfileApi _api;
  final NetworkStatus _network;

  @override
  Future<AccountProfile> getAccount(AuthSession session) async {
    await ensureOnline(_network);
    return _api.getAccount(session);
  }

  @override
  Future<String> getPhone(AuthSession session) async {
    await ensureOnline(_network);
    return _api.getPhone(session);
  }
}
