import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../network/flaky_http_client.dart';
import '../../features/users/data/user_repository.dart';
import '../../features/users/data/reqres_api.dart';

class SyncService {
  SyncService({
    required AppDatabase db,
    required UserRepository userRepo,
    http.Client? ownedHttpClient,
  })  : _db = db,
        _userRepo = userRepo,
        _ownedHttpClient = ownedHttpClient;

  final AppDatabase _db;
  final UserRepository _userRepo;
  final http.Client? _ownedHttpClient;

  static Future<SyncService> createForBackground() async {
    final db = AppDatabase();
    final client = FlakyHttpClient(http.Client());
    final api = ReqresApi(client);
    final userRepo = UserRepository(api: api, db: db);
    return SyncService(db: db, userRepo: userRepo, ownedHttpClient: client);
  }

  Future<void> syncAllPending() async {
    // 1) Sync users first (bookmarks depend on remote ids for stable identity).
    final pendingUsers = await _userRepo.getPendingLocalUsers();
    for (final u in pendingUsers) {
      try {
        final remoteId = await _userRepo.syncUserToServer(u);
        await _db.markUserSynced(u.localId, remoteId);
      } catch (_) {
        await _db.markUserFailed(u.localId);
      }
    }

    // 2) Sync bookmarks (no server API in assignment; we treat sync as "durably persisted locally"
    // and relationship integrity maintained after user sync).
    // Mark as synced once user's remoteId exists.
    final usersNowSynced = await _userRepo.getUsersWithRemoteId();
    for (final u in usersNowSynced) {
      await _db.markBookmarksSyncedForUser(u.localId);
    }
  }

  Future<void> dispose() async {
    await _db.close();
    _ownedHttpClient?.close();
  }
}

// Local helper for creating IDs consistently.
String newLocalId() => const Uuid().v4();

