import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConnectivityCubit extends Cubit<bool> {
  ConnectivityCubit(this._connectivity) : super(true) {
    _subscription = _connectivity.onConnectivityChanged.listen(_emit);
    refresh();
  }

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> refresh() async {
    try {
      _emit(await _connectivity.checkConnectivity());
    } catch (_) {
      // Keep the last known value when the platform check fails.
    }
  }

  void _emit(List<ConnectivityResult> results) {
    if (isClosed) return;
    emit(results.any((result) => result != ConnectivityResult.none));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
