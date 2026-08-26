import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../theme/theme_toggle_button.dart';

/// Temporary landing screen for roles that don't have a real dashboard
/// yet (reception, nurse, doctor, laboratory, pharmacy). Admin now
/// bypasses this entirely and goes straight to AdminDashboardScreen -
/// see main.dart's _AuthGate.
class RoleHomeScreen extends StatelessWidget {
  const RoleHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(user != null ? _roleLabel(user.role) : 'JRapha'),
        actions: [
          const Padding(padding: EdgeInsets.only(right: 4), child: ThemeToggleButton()),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dashboard_customize_rounded, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('Welcome, ${user?.fullName ?? ''}', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              '${_roleLabel(user?.role ?? '')} dashboard coming next',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'reception':
        return 'Reception';
      case 'nurse':
        return 'Nurse';
      case 'doctor':
        return 'Doctor';
      case 'laboratory':
        return 'Laboratory';
      case 'pharmacy':
        return 'Pharmacy';
      default:
        return role;
    }
  }
}
