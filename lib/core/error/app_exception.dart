sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([
    super.message = 'No internet connection. Check your network and try again.',
  ]);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([
    super.message = 'Your session has expired. Please sign in again.',
  ]);
}

class InvalidCredentialsException extends AppException {
  const InvalidCredentialsException([
    super.message = 'The login or password is incorrect.',
  ]);
}

class AuthFailedException extends AppException {
  const AuthFailedException([
    super.message = "We couldn't sign you in. Check your login and password, then try again.",
  ]);
}

class ServerException extends AppException {
  const ServerException([
    super.message = 'The service is temporarily unavailable. Please try again.',
  ]);
}
