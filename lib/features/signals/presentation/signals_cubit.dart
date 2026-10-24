import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/api_config.dart';
import '../../../core/error/app_exception.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../domain/signals_repository.dart';
import '../domain/trading_signal.dart';

enum SignalsStatus { idle, loading, ready, empty, failure }

class SignalsState extends Equatable {
  const SignalsState({
    required this.from,
    required this.to,
    this.selectedPairs = const {'EURUSD'},
    this.status = SignalsStatus.idle,
    this.signals = const [],
    this.error,
  });

  factory SignalsState.initial() {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    return SignalsState(
      from: start,
      to: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  final Set<String> selectedPairs;
  final DateTime from;
  final DateTime to;
  final SignalsStatus status;
  final List<TradingSignal> signals;
  final String? error;

  SignalsState copyWith({
    Set<String>? selectedPairs,
    DateTime? from,
    DateTime? to,
    SignalsStatus? status,
    List<TradingSignal>? signals,
    String? error,
    bool clearError = false,
  }) {
    return SignalsState(
      selectedPairs: selectedPairs ?? this.selectedPairs,
      from: from ?? this.from,
      to: to ?? this.to,
      status: status ?? this.status,
      signals: signals ?? this.signals,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [selectedPairs, from, to, status, signals, error];
}

class SignalsCubit extends Cubit<SignalsState> {
  SignalsCubit(this._repository, this._auth) : super(SignalsState.initial());

  final SignalsRepository _repository;
  final AuthCubit _auth;

  void togglePair(String pair) {
    if (!ApiConfig.currencyPairs.contains(pair)) return;
    final next = Set<String>.from(state.selectedPairs);
    if (!next.add(pair)) next.remove(pair);
    emit(state.copyWith(selectedPairs: next));
  }

  void selectAll() {
    emit(state.copyWith(selectedPairs: ApiConfig.currencyPairs.toSet()));
  }

  void clearPairs() {
    emit(state.copyWith(selectedPairs: {}));
  }

  void setRange(DateTime from, DateTime to) {
    emit(state.copyWith(from: from, to: to, clearError: true));
  }

  Future<void> load() async {
    final session = _auth.currentSession;
    if (session == null) return;
    if (state.selectedPairs.isEmpty) {
      emit(
        state.copyWith(
          status: SignalsStatus.failure,
          error: 'Select at least one currency pair.',
          signals: const [],
        ),
      );
      return;
    }
    if (!state.from.isBefore(state.to)) {
      emit(
        state.copyWith(
          status: SignalsStatus.failure,
          error: 'The start date has to be before the end date.',
          signals: const [],
        ),
      );
      return;
    }
    emit(state.copyWith(status: SignalsStatus.loading, clearError: true));
    try {
      final signals = await _repository.load(
        login: session.login,
        partnerToken: session.partnerToken,
        pairs: state.selectedPairs.toList()..sort(),
        from: state.from,
        to: state.to,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          status: signals.isEmpty ? SignalsStatus.empty : SignalsStatus.ready,
          signals: signals,
        ),
      );
    } on UnauthorizedException {
      await _auth.sessionExpired();
    } on AppException catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(status: SignalsStatus.failure, error: error.message),
        );
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: SignalsStatus.failure,
            error: 'Signals could not be loaded. Please try again.',
          ),
        );
      }
    }
  }
}
