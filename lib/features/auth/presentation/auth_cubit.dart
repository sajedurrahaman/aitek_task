import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/storage/session_store.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthChecking extends AuthState {
  const AuthChecking();
}

class AuthSigningIn extends AuthState {
  const AuthSigningIn();
}

class AuthSignedOut extends AuthState {
  const AuthSignedOut({this.message});

  final String? message;

  @override
  List<Object?> get props => [message];
}

class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.session);

  final AuthSession session;

  @override
  List<Object?> get props => [session];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required AuthRepository repository, required SessionStore store})
    : _repository = repository,
      _store = store,
      super(const AuthChecking()) {
    restore();
  }

  final AuthRepository _repository;
  final SessionStore _store;
  bool _expiryInFlight = false;

  AuthSession? get currentSession {
    final state = this.state;
    return state is AuthSignedIn ? state.session : null;
  }

  Future<void> restore() async {
    final session = await _store.read();
    if (isClosed) return;
    emit(session == null ? const AuthSignedOut() : AuthSignedIn(session));
  }

  Future<void> login({required int login, required String password}) async {
    emit(const AuthSigningIn());
    try {
      final session = await _repository.login(login: login, password: password);
      await _store.save(session);
      _expiryInFlight = false;
      if (!isClosed) emit(AuthSignedIn(session));
    } on AppException catch (error) {
      if (!isClosed) emit(AuthSignedOut(message: error.message));
    } catch (_) {
      if (!isClosed) {
        emit(
          const AuthSignedOut(
            message: 'Something went wrong while signing in. Please try again.',
          ),
        );
      }
    }
  }

  Future<void> logout() async {
    await _store.clear();
    _expiryInFlight = false;
    if (!isClosed) emit(const AuthSignedOut());
  }

  Future<void> sessionExpired() async {
    if (_expiryInFlight) return;
    _expiryInFlight = true;
    await _store.clear();
    if (!isClosed) {
      emit(
        const AuthSignedOut(
          message: 'Your session has expired. Please sign in again.',
        ),
      );
    }
  }
}
