import 'auth_session.dart';

abstract class AuthRepository {
  Future<AuthSession> login({required int login, required String password});
}
