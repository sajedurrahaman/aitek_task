class CredentialRules {
  const CredentialRules._();

  static String? validateLogin(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return 'Enter your account login.';
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'Login should contain digits only.';
    }
    final login = int.tryParse(value);
    if (login == null || login <= 0) return 'Enter a valid account login.';
    return null;
  }

  static String? validatePassword(String? raw) {
    if (raw == null || raw.isEmpty) return 'Enter your password.';
    return null;
  }

  static int? parseLogin(String raw) {
    if (validateLogin(raw) != null) return null;
    return int.parse(raw.trim());
  }
}

class ParsedPeanutAuth {
  const ParsedPeanutAuth({required this.result, required this.token});

  final bool result;
  final String token;

  bool get isSuccess => result && token.isNotEmpty;

  static ParsedPeanutAuth? tryParse(Object? data) {
    if (data is! Map) return null;
    final result = data['result'] == true || data['Result'] == true;
    final token = '${data['token'] ?? data['Token'] ?? ''}'.trim();
    return ParsedPeanutAuth(result: result, token: token);
  }
}

String parsePartnerToken(Object? data) {
  if (data is String) return data.trim().replaceAll('"', '');
  if (data is Map) {
    final token = data['token'] ?? data['Token'] ?? data['result'];
    if (token is String) return token.trim().replaceAll('"', '');
  }
  return '';
}
