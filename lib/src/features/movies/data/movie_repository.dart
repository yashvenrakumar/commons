import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import 'omdb_api.dart';

class MovieRepository {
  MovieRepository({required OmdbApi? api, required AppDatabase db})
      : _api = api,
        _db = db;

  final OmdbApi? _api;
  final AppDatabase _db;

  Future<OmdbSearchPage> searchMovies({
    required String query,
    required int page,
    void Function(int attempt, Duration nextDelay)? onRetry,
  }) async {
    final api = _api;
    if (api == null) {
      throw StateError('API not available in background isolate');
    }
    return api.searchMovies(query: query, page: page, onRetry: onRetry);
  }

  Future<OmdbMovieDetail> fetchMovieDetail({
    required String imdbId,
    void Function(int attempt, Duration nextDelay)? onRetry,
  }) async {
    final api = _api;
    if (api == null) {
      throw StateError('API not available in background isolate');
    }
    return api.fetchMovieDetail(imdbId: imdbId, onRetry: onRetry);
  }

  Stream<List<MovieBookmark>> watchBookmarks(String userLocalId) =>
      _db.watchBookmarksForUser(userLocalId);

  Future<void> addBookmark({
    required String userLocalId,
    required String imdbId,
    required String title,
    required String? posterUrl,
    required String? year,
  }) {
    return _db.addBookmark(
      MovieBookmarksCompanion.insert(
        userLocalId: userLocalId,
        imdbId: imdbId,
        title: title,
        posterUrl: Value(posterUrl),
        year: Value(year),
        createdAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      ),
    );
  }

  Future<void> removeBookmark({
    required String userLocalId,
    required String imdbId,
  }) async {
    await _db.removeBookmark(userLocalId, imdbId);
  }
}

