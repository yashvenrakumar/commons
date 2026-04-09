import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../../../core/network/retry.dart';

class OmdbApi {
  OmdbApi(this._client);
  final http.Client _client;

  Uri _base(Map<String, String> q) {
    return Uri.https('www.omdbapi.com', '/', <String, String>{
      'apikey': AppConstants.omdbApiKey,
      ...q,
    });
  }

  Future<OmdbSearchPage> searchMovies({
    required String query,
    required int page,
    void Function(int attempt, Duration nextDelay)? onRetry,
  }) async {
    final uri = _base({'s': query, 'page': '$page'});
    final resp = await getWithRetry(_client, uri, onRetry: onRetry);
    if (resp.statusCode != 200) {
      throw http.ClientException('Failed to fetch movies', uri);
    }
    final jsonMap = json.decode(resp.body) as Map<String, dynamic>;
    return OmdbSearchPage.fromJson(jsonMap);
  }

  Future<OmdbMovieDetail> fetchMovieDetail({
    required String imdbId,
    void Function(int attempt, Duration nextDelay)? onRetry,
  }) async {
    final uri = _base({'i': imdbId, 'plot': 'full'});
    final resp = await getWithRetry(_client, uri, onRetry: onRetry);
    if (resp.statusCode != 200) {
      throw http.ClientException('Failed to fetch movie detail', uri);
    }
    final jsonMap = json.decode(resp.body) as Map<String, dynamic>;
    return OmdbMovieDetail.fromJson(jsonMap);
  }
}

class OmdbSearchPage {
  final List<OmdbMovieLite> items;
  final int totalResults;
  final String? error;

  OmdbSearchPage({required this.items, required this.totalResults, this.error});

  bool get ok => error == null;

  factory OmdbSearchPage.fromJson(Map<String, dynamic> json) {
    final resp = (json['Response'] ?? 'False').toString();
    if (resp.toLowerCase() != 'true') {
      return OmdbSearchPage(
        items: const [],
        totalResults: 0,
        error: (json['Error'] ?? 'Unknown error').toString(),
      );
    }
    final list = (json['Search'] as List<dynamic>? ?? const [])
        .map((e) => OmdbMovieLite.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return OmdbSearchPage(
      items: list,
      totalResults: int.tryParse((json['totalResults'] ?? '0').toString()) ?? 0,
    );
  }
}

class OmdbMovieLite {
  final String imdbId;
  final String title;
  final String year;
  final String? poster;

  OmdbMovieLite({
    required this.imdbId,
    required this.title,
    required this.year,
    required this.poster,
  });

  factory OmdbMovieLite.fromJson(Map<String, dynamic> json) {
    final poster = (json['Poster'] ?? '').toString();
    return OmdbMovieLite(
      imdbId: (json['imdbID'] ?? '').toString(),
      title: (json['Title'] ?? '').toString(),
      year: (json['Year'] ?? '').toString(),
      poster: poster.isEmpty || poster == 'N/A' ? null : poster,
    );
  }
}

class OmdbMovieDetail {
  final String imdbId;
  final String title;
  final String plot;
  final String year;
  final String released;
  final String? poster;

  OmdbMovieDetail({
    required this.imdbId,
    required this.title,
    required this.plot,
    required this.year,
    required this.released,
    required this.poster,
  });

  factory OmdbMovieDetail.fromJson(Map<String, dynamic> json) {
    final poster = (json['Poster'] ?? '').toString();
    return OmdbMovieDetail(
      imdbId: (json['imdbID'] ?? '').toString(),
      title: (json['Title'] ?? '').toString(),
      plot: (json['Plot'] ?? '').toString(),
      year: (json['Year'] ?? '').toString(),
      released: (json['Released'] ?? '').toString(),
      poster: poster.isEmpty || poster == 'N/A' ? null : poster,
    );
  }
}

