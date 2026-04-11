import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/login.dart';
import 'screens/main_shell.dart';

import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

final ThemeController themeController = ThemeController();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await themeController.loadTheme();

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  runApp(NlwmsApp(initialToken: token));
}

class NlwmsApp extends StatelessWidget {
  final String? initialToken;

  const NlwmsApp({
    super.key,
    required this.initialToken,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn =
        initialToken != null && initialToken!.trim().isNotEmpty;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'NLWMS',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: isLoggedIn ? const MainShell() : const LoginScreen(),
        );
      },
    );
  }
}