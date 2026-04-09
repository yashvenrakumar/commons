import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import 'reqres_api.dart';

class UserRepository {
  UserRepository({required ReqresApi? api, required AppDatabase db})
      : _api = api,
        _db = db;

  final ReqresApi? _api;
  final AppDatabase _db;

  Future<ReqresUsersPage> fetchRemoteUsers({
    required int page,
    void Function(int attempt, Duration nextDelay)? onRetry,
  }) async {
    final api = _api;
    if (api == null) {
      throw StateError('API not available in background isolate');
    }
    return api.fetchUsers(page: page, onRetry: onRetry);
  }

  Stream<List<AppUser>> watchLocalUsers() => _db.watchLocalUsers();

  Future<void> createLocalUser({
    required String localId,
    int? remoteId,
    required String name,
    required String job,
    required DateTime createdAt,
    required SyncStatus status,
  }) async {
    await _db.upsertUser(
      AppUsersCompanion.insert(
        localId: localId,
        remoteId: Value(remoteId),
        name: name,
        job: Value(job),
        createdAt: createdAt,
        syncStatus: status,
      ),
    );
  }

  Future<int> syncUserToServer(AppUser user) async {
    final api = _api;
    if (api == null) throw StateError('API not available in background isolate');
    return api.createUser(name: user.name, job: user.job ?? '');
  }

  Future<String> ensureLocalUserForRemote(ReqresUser remote) async {
    final localId = 'reqres-${remote.id}';
    await _db.upsertUser(
      AppUsersCompanion.insert(
        localId: localId,
        remoteId: Value(remote.id),
        name: remote.fullName,
        job: const Value(null),
        createdAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
      ),
    );
    return localId;
  }

  Future<List<AppUser>> getPendingLocalUsers() async {
    return (_db.select(_db.appUsers)
          ..where((t) => t.syncStatus.equalsValue(SyncStatus.pending))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<List<AppUser>> getUsersWithRemoteId() async {
    return (_db.select(_db.appUsers)..where((t) => t.remoteId.isNotNull())).get();
  }
}

