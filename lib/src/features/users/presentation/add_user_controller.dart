import 'package:flutter/material.dart';

import '../../../core/db/app_database.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/system/connectivity_service.dart';
import '../data/user_repository.dart';

class AddUserController extends ChangeNotifier {
  AddUserController({
    required UserRepository repo,
    required ConnectivityService connectivity,
    required SyncService syncService,
  })  : _repo = repo,
        _connectivity = connectivity,
        _syncService = syncService;

  final UserRepository _repo;
  final ConnectivityService _connectivity;
  final SyncService _syncService;

  bool _saving = false;
  bool get saving => _saving;

  String? _error;
  String? get error => _error;

  Future<String?> createUser({required String name, required String job}) async {
    if (_saving) return null;
    _saving = true;
    _error = null;
    notifyListeners();

    final localId = newLocalId();
    final createdAt = DateTime.now();

    try {
      final online = await _connectivity.isOnline();
      if (online) {
        // Create on server first, then persist locally as synced.
        // If post fails due to flaky interceptor, fall back to pending local.
        try {
          final remoteId = await _repo.syncUserToServer(
            AppUser(
              localId: localId,
              remoteId: null,
              name: name,
              job: job,
              createdAt: createdAt,
              syncStatus: SyncStatus.pending,
            ),
          );
          await _repo.createLocalUser(
            localId: localId,
            remoteId: remoteId,
            name: name,
            job: job,
            createdAt: createdAt,
            status: SyncStatus.synced,
          );
          await _syncService.syncAllPending();
          return localId;
        } catch (_) {
          await _repo.createLocalUser(
            localId: localId,
            name: name,
            job: job,
            createdAt: createdAt,
            status: SyncStatus.pending,
          );
          return localId;
        }
      } else {
        await _repo.createLocalUser(
          localId: localId,
          name: name,
          job: job,
          createdAt: createdAt,
          status: SyncStatus.pending,
        );
        return localId;
      }
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}

