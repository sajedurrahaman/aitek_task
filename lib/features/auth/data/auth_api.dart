import '../../../core/config/api_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../domain/credential_rules.dart';

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<String> requestPeanutToken({
    required int login,
    required String password,
  }) async {
    final response = await _client.postJson(
      ApiConfig.peanutAuth,
      body: {'login': login, 'password': password},
    );
    final parsed = ParsedPeanutAuth.tryParse(response.data);
    if (response.isSuccess && parsed != null && parsed.isSuccess) {
      return parsed.token;
    }
    if (response.statusCode == 401 ||
        response.statusCode == 400 ||
        (parsed != null && !parsed.isSuccess)) {
      throw const InvalidCredentialsException();
    }
    throw const AuthFailedException();
  }

  Future<String> requestPartnerToken({
    required int login,
    required String password,
  }) async {
    final response = await _client.postJson(
      ApiConfig.partnerAuth,
      body: {'login': login, 'password': password},
    );
    if (response.isSuccess) {
      final token = parsePartnerToken(response.data);
      if (token.isEmpty) throw const InvalidCredentialsException();
      return token;
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const InvalidCredentialsException();
    }
    throw const AuthFailedException();
  }
}
