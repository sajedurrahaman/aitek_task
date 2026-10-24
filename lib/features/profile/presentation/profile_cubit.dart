import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../domain/account_profile.dart';
import '../domain/profile_repository.dart';

enum ProfileStatus { loading, ready, failure }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.loading,
    this.profile,
    this.phone,
    this.accountError,
    this.phoneError,
    this.error,
  });

  final ProfileStatus status;
  final AccountProfile? profile;
  final String? phone;
  final String? accountError;
  final String? phoneError;
  final String? error;

  @override
  List<Object?> get props => [
    status,
    profile,
    phone,
    accountError,
    phoneError,
    error,
  ];
}

class _Guarded<T> {
  const _Guarded.value(this.value) : error = null;
  const _Guarded.error(this.error) : value = null;

  final T? value;
  final AppException? error;
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository, this._auth) : super(const ProfileState());

  final ProfileRepository _repository;
  final AuthCubit _auth;

  Future<void> load() async {
    final session = _auth.currentSession;
    if (session == null) return;
    emit(const ProfileState());
    final account = await _guard(() => _repository.getAccount(session));
    final phone = await _guard(() => _repository.getPhone(session));
    if (isClosed) return;
    if (account.error is UnauthorizedException ||
        phone.error is UnauthorizedException) {
      await _auth.sessionExpired();
      return;
    }
    final phoneText = phone.value;
    final hasPhone = phoneText != null && phoneText.isNotEmpty;
    final hasAccount = account.value != null;
    if (!hasAccount && !hasPhone) {
      emit(
        ProfileState(
          status: ProfileStatus.failure,
          error:
              account.error?.message ??
              phone.error?.message ??
              'Profile details are unavailable right now.',
        ),
      );
      return;
    }
    emit(
      ProfileState(
        status: ProfileStatus.ready,
        profile: account.value,
        phone: hasPhone ? phoneText : null,
        accountError: account.error?.message,
        phoneError: phone.error?.message,
      ),
    );
  }

  Future<_Guarded<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return _Guarded.value(await action());
    } on AppException catch (error) {
      return _Guarded.error(error);
    } catch (_) {
      return const _Guarded.error(
        ServerException('Something went wrong while loading your profile.'),
      );
    }
  }
}
