import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

bool _isRetryableError(Object e) =>
    e is SocketException || e is TimeoutException || e is http.ClientException;

bool _isRetryableResponse(http.Response r) => r.statusCode >= 500;

Duration _backoff(int attempt) {
  // attempt: 0..n
  final ms = switch (attempt) {
    0 => 250,
    1 => 600,
    2 => 1200,
    3 => 2000,
    _ => 3000,
  };
  return Duration(milliseconds: ms);
}

Future<http.Response> getWithRetry(
  http.Client client,
  Uri uri, {
  Map<String, String>? headers,
  int maxAttempts = 6,
  void Function(int attempt, Duration nextDelay)? onRetry,
}) async {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      final resp = await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 12));
      if (_isRetryableResponse(resp) && attempt < maxAttempts - 1) {
        final delay = _backoff(attempt);
        onRetry?.call(attempt, delay);
        await Future<void>.delayed(delay);
        continue;
      }
      return resp;
    } catch (e) {
      if (!_isRetryableError(e) || attempt >= maxAttempts - 1) rethrow;
      final delay = _backoff(attempt);
      onRetry?.call(attempt, delay);
      await Future<void>.delayed(delay);
    }
  }
  // Unreachable
  throw StateError('Retry loop fell through');
}

