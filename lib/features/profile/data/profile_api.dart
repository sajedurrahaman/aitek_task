import '../../../core/config/api_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../../auth/domain/auth_session.dart';
import '../domain/account_profile.dart';

class ProfileApi {
  ProfileApi(this._client);

  final ApiClient _client;

  Future<AccountProfile> getAccount(AuthSession session) async {
    final response = await _post(ApiConfig.peanutAccount, session);
    final profile = AccountProfile.tryParse(response.data);
    if (profile == null) {
      throw const ServerException(
        'Account details came back in an unexpected format.',
      );
    }
    return profile;
  }

  Future<String> getPhone(AuthSession session) async {
    final response = await _post(ApiConfig.peanutPhone, session);
    final phone = parsePhoneBody(response.data);
    if (phone.isEmpty) {
      throw const ServerException(
        'The phone service returned an empty response.',
      );
    }
    return phone;
  }

  Future<ApiResponse> _post(String url, AuthSession session) async {
    final response = await _client.postJson(
      url,
      body: {'login': session.login, 'token': session.peanutToken},
    );
    throwIfRejected(response);
    return response;
  }
}
