import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/nurse_provider.dart';
import '../models/nurse_queue_item.dart';
import 'vitals_entry_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/theme_toggle_button.dart';

class NurseDashboardScreen extends StatefulWidget {
  const NurseDashboardScreen({super.key});

  @override
  State<NurseDashboardScreen> createState() => _NurseDashboardScreenState();
}

class _NurseDashboardScreenState extends State<NurseDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NurseProvider>().loadQueue();
    });
  }

  Future<void> _openVitalsEntry(NurseQueueItem patient) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => VitalsEntryScreen(patient: patient)));
    if (mounted) {
      context.read<NurseProvider>().loadQueue();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nurse = context.watch<NurseProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nurse'),
        actions: [
          if (nurse.isLoadingQueue)
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
        onRefresh: () => context.read<NurseProvider>().loadQueue(),
        child: nurse.isLoadingQueue && nurse.queue.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : nurse.queue.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 100),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        const Text('No patients waiting for vitals'),
                      ],
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: nurse.queue.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final patient = nurse.queue[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                        child: Text(
                          patient.fullName.isNotEmpty ? patient.fullName[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(patient.fullName),
                      subtitle: Text(
                        '${patient.patientNumber}'
                        '${patient.age != null ? ' · ${patient.age} yrs' : ''}'
                        '${patient.gender != null ? ' · ${patient.gender}' : ''}'
                        ' · ${patient.visitType.toUpperCase()}',
                      ),
                      trailing: FilledButton.icon(
                        icon: const Icon(Icons.monitor_heart_outlined, size: 18),
                        label: const Text('Vitals'),
                        onPressed: () => _openVitalsEntry(patient),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
