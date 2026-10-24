import '../../features/auth/domain/auth_session.dart';
import 'key_value_store.dart';

class SessionStore {
  SessionStore(this._store);

  static const loginKey = 'session_login';
  static const peanutTokenKey = 'session_peanut_token';
  static const partnerTokenKey = 'session_partner_token';

  final KeyValueStore _store;

  Future<AuthSession?> read() async {
    try {
      final login = int.tryParse((await _store.read(loginKey)) ?? '');
      final peanut = await _store.read(peanutTokenKey);
      final partner = await _store.read(partnerTokenKey);
      if (login == null ||
          peanut == null ||
          partner == null ||
          peanut.isEmpty ||
          partner.isEmpty) {
        return null;
      }
      return AuthSession(
        login: login,
        peanutToken: peanut,
        partnerToken: partner,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(AuthSession session) async {
    await _store.write(loginKey, '${session.login}');
    await _store.write(peanutTokenKey, session.peanutToken);
    await _store.write(partnerTokenKey, session.partnerToken);
  }

  Future<void> clear() async {
    await _store.delete(loginKey);
    await _store.delete(peanutTokenKey);
    await _store.delete(partnerTokenKey);
  }
}
