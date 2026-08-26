import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/role_home_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/reception/screens/reception_dashboard_screen.dart';
import 'features/reception/providers/reception_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ReceptionProvider()),
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

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    switch (authProvider.currentUser?.role) {
      case 'admin':
        return const AdminDashboardScreen();
      case 'reception':
        return const ReceptionDashboardScreen();
      default:
        return const RoleHomeScreen();
    }
  }
}
