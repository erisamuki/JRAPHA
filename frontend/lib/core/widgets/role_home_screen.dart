import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/admin/screens/user_approvals_screen.dart';
import '../theme/theme_toggle_button.dart';

/// Temporary landing screen shown right after login, before role-specific
/// dashboards (reception, nurse, doctor, etc.) are built. Replace the
/// body's switch with real dashboard widgets as each one is completed.
class RoleHomeScreen extends StatelessWidget {
  const RoleHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final theme = Theme.of(context);
    final isAdmin = user?.role == 'admin';

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
            if (isAdmin) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.how_to_reg_rounded),
                label: const Text('Manage User Approvals'),
                onPressed: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const UserApprovalsScreen()));
                },
              ),
            ],
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
