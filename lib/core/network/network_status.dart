import 'package:connectivity_plus/connectivity_plus.dart';

import '../error/app_exception.dart';

abstract class NetworkStatus {
  Future<bool> get isOnline;
}

class ConnectivityNetworkStatus implements NetworkStatus {
  ConnectivityNetworkStatus(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<bool> get isOnline async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((result) => result != ConnectivityResult.none);
    } catch (_) {
      // A plugin failure should not block a request that may still succeed.
      return true;
    }
  }
}

Future<void> ensureOnline(NetworkStatus network) async {
  if (!await network.isOnline) throw const NetworkException();
}
