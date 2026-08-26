import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/admin_provider.dart';
import 'user_approvals_screen.dart';
import 'all_users_screen.dart';
import 'audit_log_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/theme_toggle_button.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminProvider()..startRealtime(),
      child: const _AdminDashboardView(),
    );
  }
}

class _AdminDashboardView extends StatelessWidget {
  const _AdminDashboardView();

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final dashboard = admin.dashboard;
    final theme = Theme.of(context);
    final currencyText = 'UGX ${dashboard.todayRevenueUgx.toStringAsFixed(0)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          if (admin.isLoadingDashboard)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          const ThemeToggleButton(),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AdminProvider>().loadDashboard(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth > 900 ? 900.0 : constraints.maxWidth;

            return ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Center(
                  child: SizedBox(
                    width: contentWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Live overview', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          'Updates automatically as reception, clinical, and pharmacy activity happens.',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),

                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 2.1,
                          ),
                          itemCount: 6,
                          itemBuilder: (context, index) {
                            final cards = [
                              _StatCard(
                                icon: Icons.groups_rounded,
                                label: 'OPD Queue',
                                value: '${dashboard.opdQueue.length}',
                                color: theme.colorScheme.primary,
                              ),
                              _StatCard(
                                icon: Icons.bed_rounded,
                                label: 'In-Patients',
                                value: '${dashboard.inpatients.length}',
                                color: theme.colorScheme.primary,
                              ),
                              _StatCard(
                                icon: Icons.pending_actions_rounded,
                                label: 'Pending Approvals',
                                value: '${dashboard.pendingUsers.length}',
                                color: Colors.orange,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const UserApprovalsScreen()),
                                ),
                              ),
                              _StatCard(
                                icon: Icons.payments_rounded,
                                label: "Today's Revenue",
                                value: currencyText,
                                color: Colors.green,
                              ),
                              _StatCard(
                                icon: Icons.receipt_long_rounded,
                                label: 'Outstanding Bills',
                                value: '${dashboard.outstandingBillsCount}',
                                color: Colors.red,
                              ),
                              _StatCard(
                                icon: Icons.inventory_2_rounded,
                                label: 'Low Stock Items',
                                value: '${dashboard.lowStockCount}',
                                color: Colors.amber.shade800,
                              ),
                            ];
                            return cards[index];
                          },
                        ),

                        const SizedBox(height: 28),
                        Text('Management', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 12),
                        _NavTile(
                          icon: Icons.how_to_reg_rounded,
                          title: 'User Approvals',
                          subtitle: 'Approve or reject pending staff accounts',
                          onTap: () => Navigator.of(
                            context,
                          ).push(MaterialPageRoute(builder: (_) => const UserApprovalsScreen())),
                        ),
                        const SizedBox(height: 8),
                        _NavTile(
                          icon: Icons.people_alt_rounded,
                          title: 'All Users',
                          subtitle: 'View every account and its status',
                          onTap: () => Navigator.of(
                            context,
                          ).push(MaterialPageRoute(builder: (_) => const AllUsersScreen())),
                        ),
                        const SizedBox(height: 8),
                        _NavTile(
                          icon: Icons.history_rounded,
                          title: 'Audit Log',
                          subtitle: 'Track approvals, rejections, and system actions',
                          onTap: () => Navigator.of(
                            context,
                          ).push(MaterialPageRoute(builder: (_) => const AuditLogScreen())),
                        ),

                        if (dashboard.opdQueue.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          Text('OPD Queue', style: theme.textTheme.titleLarge),
                          const SizedBox(height: 12),
                          ...dashboard.opdQueue
                              .take(5)
                              .map(
                                (v) => Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.person_outline_rounded, size: 20),
                                    title: Text(v.fullName),
                                    subtitle: Text(
                                      '${v.patientNumber} · ${v.status.replaceAll('_', ' ')}',
                                    ),
                                  ),
                                ),
                              ),
                        ],

                        if (dashboard.inpatients.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text('In-Patients', style: theme.textTheme.titleLarge),
                          const SizedBox(height: 12),
                          ...dashboard.inpatients
                              .take(5)
                              .map(
                                (v) => Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.bed_outlined, size: 20),
                                    title: Text(v.fullName),
                                    subtitle: Text(
                                      '${v.patientNumber}'
                                      '${v.ward != null ? ' · Ward ${v.ward}' : ''}'
                                      '${v.bedNumber != null ? ' · Bed ${v.bedNumber}' : ''}',
                                    ),
                                  ),
                                ),
                              ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
