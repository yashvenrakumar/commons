import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

enum SyncStatus {
  pending,
  synced,
  failed,
}

class AppUsers extends Table {
  TextColumn get localId => text()(); // uuid
  IntColumn get remoteId => integer().nullable()();
  TextColumn get name => text()();
  TextColumn get job => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get syncStatus => intEnum<SyncStatus>()();

  @override
  Set<Column> get primaryKey => {localId};
}

class MovieBookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userLocalId =>
      text().references(AppUsers, #localId, onDelete: KeyAction.cascade)();
  TextColumn get imdbId => text()();
  TextColumn get title => text()();
  TextColumn get posterUrl => text().nullable()();
  TextColumn get year => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get syncStatus => intEnum<SyncStatus>()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {userLocalId, imdbId},
      ];
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [AppUsers, MovieBookmarks, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Users
  Stream<List<AppUser>> watchLocalUsers() =>
      (select(appUsers)..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<void> upsertUser(AppUsersCompanion user) =>
      into(appUsers).insertOnConflictUpdate(user);

  Future<int> markUserSynced(String localId, int remoteId) {
    return (update(appUsers)..where((t) => t.localId.equals(localId))).write(
      AppUsersCompanion(
        remoteId: Value(remoteId),
        syncStatus: Value(SyncStatus.synced),
      ),
    );
  }

  Future<int> markUserFailed(String localId) {
    return (update(appUsers)..where((t) => t.localId.equals(localId))).write(
      AppUsersCompanion(syncStatus: Value(SyncStatus.failed)),
    );
  }

  // Bookmarks
  Stream<List<MovieBookmark>> watchBookmarksForUser(String userLocalId) {
    return (select(movieBookmarks)
          ..where((t) => t.userLocalId.equals(userLocalId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<void> addBookmark(MovieBookmarksCompanion b) =>
      into(movieBookmarks).insertOnConflictUpdate(b);

  Future<int> removeBookmark(String userLocalId, String imdbId) {
    return (delete(movieBookmarks)
          ..where((t) => t.userLocalId.equals(userLocalId) & t.imdbId.equals(imdbId)))
        .go();
  }

  Future<int> markBookmarksSyncedForUser(String userLocalId) {
    return (update(movieBookmarks)..where((t) => t.userLocalId.equals(userLocalId)))
        .write(MovieBookmarksCompanion(syncStatus: Value(SyncStatus.synced)));
  }

  // Settings
  Future<String?> getSetting(String k) async {
    final row = await (select(appSettings)..where((t) => t.key.equals(k)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String k, String v) async {
    await into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion(key: Value(k), value: Value(v)),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // drift_flutter's helper returns a DatabaseConnection already configured,
    // but we want a stable file path for Workmanager isolates too.
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'app.db'));
    return NativeDatabase.createInBackground(file);
  });
}

