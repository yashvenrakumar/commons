import 'package:workmanager/workmanager.dart';

import 'sync_service.dart';
import '../system/connectivity_service.dart';

const String kSyncTaskName = 'sync_offline_data';
const String kSyncUniqueTaskName = 'sync_offline_data_unique';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Minimal local instantiation (Workmanager isolate can't rely on GetIt state).
    final sync = await SyncService.createForBackground();
    await sync.syncAllPending();
    await sync.dispose();
    return Future.value(true);
  });
}

class WorkmanagerSetup {
  WorkmanagerSetup({required SyncService syncService, required ConnectivityService connectivity})
      : _syncService = syncService,
        _connectivity = connectivity;

  final SyncService _syncService;
  final ConnectivityService _connectivity;

  Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher);

    _connectivity.start();
    _connectivity.onIsOnlineChanged.listen((isOnline) async {
      if (isOnline) {
        await scheduleOneOffSync();
      }
    });

    // Also attempt an eager sync on app start (non-blocking).
    scheduleOneOffSync();
  }

  Future<void> scheduleOneOffSync() async {
    await Workmanager().registerOneOffTask(
      kSyncUniqueTaskName,
      kSyncTaskName,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 5),
    );

    // And attempt immediately in-app as well (for fast feedback).
    await _syncService.syncAllPending();
  }
}

