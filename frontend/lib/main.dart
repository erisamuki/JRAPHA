import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/role_home_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Add more app-wide providers here as features are built
      ],
      child: const JRaphaApp(),
    ),
  );
}

class JRaphaApp extends StatelessWidget {
  const JRaphaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'JRapha',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      home: const _AuthGate(),
    );
  }
}

/// Decides which screen to show based on current auth state.
/// Not authenticated -> LoginScreen. Authenticated -> RoleHomeScreen
/// (temporary; will route to per-role dashboards once they're built).
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isAuthenticated) {
      return const RoleHomeScreen();
    }
    return const LoginScreen();
  }
}
