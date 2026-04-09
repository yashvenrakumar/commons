import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/db/app_database.dart';
import '../data/user_repository.dart';
import '../data/reqres_api.dart';

class UsersController extends ChangeNotifier {
  UsersController({required UserRepository repo}) : _repo = repo;

  final UserRepository _repo;

  final List<ReqresUser> _remoteUsers = [];
  List<ReqresUser> get remoteUsers => List.unmodifiable(_remoteUsers);

  Stream<List<AppUser>> get localUsersStream => _repo.watchLocalUsers();

  int _page = 0;
  int _totalPages = 1;
  bool _loading = false;
  bool get loading => _loading;

  bool _reconnecting = false;
  bool get reconnecting => _reconnecting;

  int _retryAttempt = 0;
  Timer? _retryTimer;

  bool get hasMore => _page < _totalPages;

  Future<void> refresh() async {
    _remoteUsers.clear();
    _page = 0;
    _totalPages = 1;
    _retryAttempt = 0;
    _retryTimer?.cancel();
    _reconnecting = false;
    notifyListeners();
    await loadNextPage();
  }

  Future<void> loadNextPage() async {
    if (_loading || !hasMore) return;
    _loading = true;
    notifyListeners();
    final next = _page + 1;
    try {
      final page = await _repo.fetchRemoteUsers(
        page: next,
        onRetry: (attempt, _) {
          if (!_reconnecting) {
            _reconnecting = true;
            notifyListeners();
          }
        },
      );
      _page = page.page;
      _totalPages = page.totalPages;
      _remoteUsers.addAll(page.data);
      _reconnecting = false;
      _retryAttempt = 0;
    } catch (e) {
      // Assignment expects silent background retries and non-blocking UI.
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

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }
}

