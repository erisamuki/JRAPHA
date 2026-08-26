import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/admin_provider.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadAuditLog();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Log'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<AdminProvider>().loadAuditLog(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AdminProvider>().loadAuditLog(),
        child: admin.isLoadingAuditLog && admin.auditLog.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : admin.auditLog.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No activity recorded yet')),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: admin.auditLog.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final entry = admin.auditLog[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.history_rounded),
                      title: Text(_actionLabel(entry.action)),
                      subtitle: Text(
                        '${entry.actedBy ?? 'System'} · ${_formatDate(entry.createdAt)}',
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _actionLabel(String action) {
    return action
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1);
        })
        .join(' ');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
