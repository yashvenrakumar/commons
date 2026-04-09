import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/db/app_database.dart';
import '../data/movie_repository.dart';
import '../data/omdb_api.dart';

class MovieListController extends ChangeNotifier {
  MovieListController({
    required MovieRepository repo,
    required String userLocalId,
    String? initialQuery,
  })  : _repo = repo,
        _userLocalId = userLocalId,
        _query = (initialQuery?.trim().isNotEmpty ?? false)
            ? initialQuery!.trim()
            : AppConstants.defaultMovieSearchQuery {
    _bookmarksSub = _repo.watchBookmarks(_userLocalId).listen((rows) {
      _bookmarkedIds = rows.map((e) => e.imdbId).toSet();
      notifyListeners();
    });
  }

  final MovieRepository _repo;
  final String _userLocalId;

  late StreamSubscription<List<MovieBookmark>> _bookmarksSub;
  Set<String> _bookmarkedIds = <String>{};
  bool isBookmarked(String imdbId) => _bookmarkedIds.contains(imdbId);

  final List<OmdbMovieLite> _items = [];
  List<OmdbMovieLite> get items => List.unmodifiable(_items);

  String _query;
  String get query => _query;

  int _page = 0;
  bool _loading = false;
  bool get loading => _loading;

  bool _reconnecting = false;
  bool get reconnecting => _reconnecting;

  int _retryAttempt = 0;
  Timer? _retryTimer;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  String? _error;
  String? get error => _error;

  Future<void> setQuery(String q) async {
    final next = q.trim();
    if (next.isEmpty || next == _query) return;
    _query = next;
    await refresh();
  }

  Future<void> refresh() async {
    _items.clear();
    _page = 0;
    _hasMore = true;
    _error = null;
    _retryAttempt = 0;
    _retryTimer?.cancel();
    _reconnecting = false;
    notifyListeners();
    await loadNextPage();
  }

  Future<void> loadNextPage() async {
    if (_loading || !_hasMore) return;
    _loading = true;
    _error = null;
    notifyListeners();
    final nextPage = _page + 1;
    try {
      final page = await _repo.searchMovies(
        query: _query,
        page: nextPage,
        onRetry: (attempt, _) {
          if (!_reconnecting) {
            _reconnecting = true;
            notifyListeners();
          }
        },
      );
      if (!page.ok) {
        _items.clear();
        _hasMore = false;
        _error = page.error;
      } else {
        _page = nextPage;
        _items.addAll(page.items);
        _hasMore = page.items.isNotEmpty;
        _reconnecting = false;
        _retryAttempt = 0;
      }
    } catch (e) {
      // Silent retry loop for transient network failures.
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
      loadNextPage();
    });
  }

  Future<void> toggleBookmark(OmdbMovieLite m) async {
    if (isBookmarked(m.imdbId)) {
      await _repo.removeBookmark(userLocalId: _userLocalId, imdbId: m.imdbId);
    } else {
      await _repo.addBookmark(
        userLocalId: _userLocalId,
        imdbId: m.imdbId,
        title: m.title,
        posterUrl: m.poster,
        year: m.year,
      );
    }
  }

  @override
  void dispose() {
    _bookmarksSub.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }
}

