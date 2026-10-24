import '../../auth/domain/auth_session.dart';
import 'account_profile.dart';

abstract class ProfileRepository {
  Future<AccountProfile> getAccount(AuthSession session);
  Future<String> getPhone(AuthSession session);
}
