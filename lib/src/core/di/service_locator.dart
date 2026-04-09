import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../db/app_database.dart';
import '../network/flaky_http_client.dart';
import '../../features/movies/data/omdb_api.dart';
import '../../features/users/data/reqres_api.dart';
import '../../features/users/data/user_repository.dart';
import '../../features/movies/data/movie_repository.dart';
import '../sync/sync_service.dart';
import '../sync/workmanager_setup.dart';
import '../system/connectivity_service.dart';
import '../system/theme_settings_repository.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());

  sl.registerLazySingleton<http.Client>(
    () => FlakyHttpClient(http.Client()),
  );

  sl.registerLazySingleton<ReqresApi>(() => ReqresApi(sl()));
  sl.registerLazySingleton<OmdbApi>(() => OmdbApi(sl()));

  sl.registerLazySingleton<UserRepository>(
    () => UserRepository(api: sl(), db: sl()),
  );
  sl.registerLazySingleton<MovieRepository>(
    () => MovieRepository(api: sl(), db: sl()),
  );

  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  sl.registerLazySingleton<ThemeSettingsRepository>(
    () => ThemeSettingsRepository(db: sl()),
  );

  sl.registerLazySingleton<SyncService>(
    () => SyncService(db: sl(), userRepo: sl()),
  );

  // Workmanager is set up at runtime (main isolate).
  sl.registerLazySingleton<WorkmanagerSetup>(
    () => WorkmanagerSetup(syncService: sl(), connectivity: sl()),
  );
}

