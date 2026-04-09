import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

/// Intercepts GET requests and randomly fails ~30% to test resilience.
class FlakyHttpClient extends http.BaseClient {
  final http.Client _inner;
  final Random _random;
  final double failRate;

  FlakyHttpClient(
    this._inner, {
    Random? random,
    this.failRate = 0.30,
  }) : _random = random ?? Random();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.method.toUpperCase() == 'GET') {
      final r = _random.nextDouble();
      if (r < failRate) {
        // Half socket, half 500.
        if (_random.nextBool()) {
          throw const SocketException('Simulated flaky network');
        }
        return http.StreamedResponse(
          const Stream<List<int>>.empty(),
          500,
          reasonPhrase: 'Simulated 500',
          request: request,
        );
      }
    }
    return _inner.send(request);
  }
}

