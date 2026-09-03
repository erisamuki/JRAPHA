import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/admin_provider.dart';
import '../models/pending_user_model.dart';

class UserApprovalsScreen extends StatefulWidget {
  const UserApprovalsScreen({super.key});

  @override
  State<UserApprovalsScreen> createState() => _UserApprovalsScreenState();
}

class _UserApprovalsScreenState extends State<UserApprovalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadPendingUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Approvals'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<AdminProvider>().loadPendingUsers(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AdminProvider>().loadPendingUsers(),
        child: _buildBody(context, adminProvider, theme),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AdminProvider provider, ThemeData theme) {
    if (provider.isLoadingPending && provider.pendingUsers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.pendingUsers.isEmpty) {
      return _CenteredMessage(
        icon: Icons.error_outline_rounded,
        title: 'Something went wrong',
        subtitle: provider.errorMessage!,
        color: theme.colorScheme.error,
      );
    }

    if (provider.pendingUsers.isEmpty) {
      return _CenteredMessage(
        icon: Icons.check_circle_outline_rounded,
        title: 'All caught up',
        subtitle: 'No accounts are waiting for approval right now.',
        color: theme.colorScheme.primary,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: provider.pendingUsers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = provider.pendingUsers[index];
        return _PendingUserCard(user: user, isProcessing: provider.processingUserId == user.id);
      },
    );
  }
}

class _PendingUserCard extends StatelessWidget {
  final PendingUserModel user;
  final bool isProcessing;

  const _PendingUserCard({required this.user, required this.isProcessing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                  child: Text(
                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName, style: theme.textTheme.titleMedium),
                      Text(user.email, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Chip(label: Text(_roleLabel(user.role))),
              ],
            ),
            if (user.phone != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(user.phone!, style: theme.textTheme.bodySmall),
                ],
              ),
            ],
            const SizedBox(height: 16),
            if (isProcessing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
                      onPressed: () => _handleReject(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Approve'),
                      onPressed: () => _handleApprove(context),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleApprove(BuildContext context) async {
    final provider = context.read<AdminProvider>();
    final success = await provider.approveUser(user.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? '${user.fullName} approved' : (provider.errorMessage ?? 'Failed to approve'),
          ),
        ),
      );
    }
  }

  Future<void> _handleReject(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject this account?'),
        content: Text('${user.fullName} will not be able to sign in.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reject')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final provider = context.read<AdminProvider>();
    final success = await provider.rejectUser(user.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? '${user.fullName} rejected' : (provider.errorMessage ?? 'Failed to reject'),
          ),
        ),
      );
    }
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

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ListView(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(subtitle, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
