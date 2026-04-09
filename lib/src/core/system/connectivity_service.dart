import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get onIsOnlineChanged => _controller.stream;

  Future<bool> isOnline() async {
    final res = await _connectivity.checkConnectivity();
    return _isOnline(res);
  }

  void start() {
    _sub ??= _connectivity.onConnectivityChanged.listen((res) {
      _controller.add(_isOnline(res));
    });
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _controller.close();
  }

  bool _isOnline(List<ConnectivityResult> res) {
    return res.any((r) => r != ConnectivityResult.none);
  }
}

