import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/core/di/service_locator.dart';
import 'src/core/sync/workmanager_setup.dart';
import 'src/core/theme/app_theme.dart';
import 'src/features/app/app_controller.dart';
import 'src/features/users/presentation/users_controller.dart';
import 'src/features/users/presentation/users_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator();
  await sl<WorkmanagerSetup>().init();

  final appController = AppController(themeRepo: sl());
  await appController.init();
  runApp(MyApp(appController: appController));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.appController});

  final AppController appController;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appController),
        ChangeNotifierProvider(
          create: (_) => UsersController(repo: sl()),
        ),
      ],
      child: Consumer<AppController>(
        builder: (context, app, _) {
          return MaterialApp(
            title: 'Assignment App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: app.themeMode,
            home: const UsersListScreen(),
          );
        },
      ),
    );
  }
}
