import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/lab_provider.dart';
import '../models/lab_queue_item.dart';
import 'lab_result_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/theme_toggle_button.dart';

class LabDashboardScreen extends StatefulWidget {
  const LabDashboardScreen({super.key});

  @override
  State<LabDashboardScreen> createState() => _LabDashboardScreenState();
}

class _LabDashboardScreenState extends State<LabDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LabProvider>().loadQueue();
    });
  }

  Future<void> _advanceStatus(LabQueueItem order) async {
    final nextStatus = switch (order.status) {
      'ordered' => 'sample_collected',
      'sample_collected' => 'in_progress',
      _ => null,
    };
    if (nextStatus == null) return;

    final provider = context.read<LabProvider>();
    await provider.updateStatus(order.id, nextStatus);
  }

  void _openResultEntry(LabQueueItem order) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => LabResultScreen(order: order)));
  }

  @override
  Widget build(BuildContext context) {
    final lab = context.watch<LabProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laboratory'),
        actions: [
          if (lab.isLoadingQueue)
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
        onRefresh: () => context.read<LabProvider>().loadQueue(),
        child: lab.isLoadingQueue && lab.queue.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : lab.queue.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 100),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.science_outlined, size: 48, color: theme.colorScheme.primary),
                        const SizedBox(height: 12),
                        const Text('No lab orders waiting'),
                      ],
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: lab.queue.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final order = lab.queue[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.science_outlined),
                      title: Text(order.testName),
                      subtitle: Text(
                        '${order.fullName} · ${order.patientNumber} · ${order.status.replaceAll('_', ' ')}',
                      ),
                      trailing:
                          order.status == 'in_progress' ||
                              order.status == 'ordered' ||
                              order.status == 'sample_collected'
                          ? _ActionButton(
                              order: order,
                              onAdvance: () => _advanceStatus(order),
                              onResult: () => _openResultEntry(order),
                            )
                          : null,
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final LabQueueItem order;
  final VoidCallback onAdvance;
  final VoidCallback onResult;

  const _ActionButton({required this.order, required this.onAdvance, required this.onResult});

  @override
  Widget build(BuildContext context) {
    if (order.status == 'in_progress') {
      return FilledButton.icon(
        icon: const Icon(Icons.edit_note_rounded, size: 18),
        label: const Text('Result'),
        onPressed: onResult,
      );
    }
    final label = order.status == 'ordered' ? 'Collect Sample' : 'Start Test';
    return OutlinedButton(onPressed: onAdvance, child: Text(label));
  }
}
