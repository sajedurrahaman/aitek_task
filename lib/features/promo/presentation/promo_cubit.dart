import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../domain/promo_material.dart';
import '../domain/promo_repository.dart';

enum PromoStatus { loading, ready, empty, failure }

class PromoState extends Equatable {
  const PromoState({
    this.status = PromoStatus.loading,
    this.materials = const [],
    this.error,
  });

  final PromoStatus status;
  final List<PromoMaterial> materials;
  final String? error;

  @override
  List<Object?> get props => [status, materials, error];
}

class PromoCubit extends Cubit<PromoState> {
  PromoCubit(this._repository) : super(const PromoState());

  final PromoRepository _repository;

  Future<void> load() async {
    emit(const PromoState());
    try {
      final materials = await _repository.load();
      if (isClosed) return;
      emit(
        PromoState(
          status: materials.isEmpty ? PromoStatus.empty : PromoStatus.ready,
          materials: materials,
        ),
      );
    } on AppException catch (error) {
      if (!isClosed) {
        emit(PromoState(status: PromoStatus.failure, error: error.message));
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          const PromoState(
            status: PromoStatus.failure,
            error: 'Promo materials could not be loaded. Please try again.',
          ),
        );
      }
    }
  }
}
