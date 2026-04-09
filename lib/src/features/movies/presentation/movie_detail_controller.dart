import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/db/app_database.dart';
import '../data/movie_repository.dart';
import '../data/omdb_api.dart';

class MovieDetailController extends ChangeNotifier {
  MovieDetailController({
    required MovieRepository repo,
    required String userLocalId,
    required String imdbId,
  })  : _repo = repo,
        _userLocalId = userLocalId,
        _imdbId = imdbId {
    _bookmarkSub = _repo.watchBookmarks(_userLocalId).listen((rows) {
      final next = rows.any((e) => e.imdbId == _imdbId);
      if (next == _bookmarked) return;
      _bookmarked = next;
      notifyListeners();
    });
  }

  final MovieRepository _repo;
  final String _userLocalId;
  final String _imdbId;
  late final StreamSubscription<List<MovieBookmark>> _bookmarkSub;

  OmdbMovieDetail? _detail;
  OmdbMovieDetail? get detail => _detail;

  bool _loading = false;
  bool get loading => _loading;

  bool _reconnecting = false;
  bool get reconnecting => _reconnecting;

  String? _error;
  String? get error => _error;

  int _retryAttempt = 0;
  Timer? _retryTimer;

  bool _bookmarked = false;
  bool get bookmarked => _bookmarked;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _detail = await _repo.fetchMovieDetail(
        imdbId: _imdbId,
        onRetry: (attempt, _) {
          if (!_reconnecting) {
            _reconnecting = true;
            notifyListeners();
          }
        },
      );
      _reconnecting = false;
      _retryAttempt = 0;
    } catch (e) {
      _reconnecting = true;
      _scheduleRetry();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    final delayMs = switch (_retryAttempt) {
      0 => 600,
      1 => 1200,
      2 => 2000,
      3 => 3000,
      _ => 4000,
    };
    _retryAttempt = (_retryAttempt + 1).clamp(0, 12);
    _retryTimer = Timer(Duration(milliseconds: delayMs), () {
      load();
    });
  }

  Future<void> toggleBookmark({
    required String title,
    required String? posterUrl,
    required String? year,
  }) async {
    if (_bookmarked) {
      await _repo.removeBookmark(userLocalId: _userLocalId, imdbId: _imdbId);
    } else {
      await _repo.addBookmark(
        userLocalId: _userLocalId,
        imdbId: _imdbId,
        title: title,
        posterUrl: posterUrl,
        year: year,
      );
    }
  }

  @override
  void dispose() {
    _bookmarkSub.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }
}

