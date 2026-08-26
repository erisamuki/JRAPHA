import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/doctor_provider.dart';
import 'patient_visit_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/theme_toggle_button.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorProvider>().loadQueue();
    });
  }

  @override
  Widget build(BuildContext context) {
    final doctor = context.watch<DoctorProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor'),
        actions: [
          if (doctor.isLoadingQueue)
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
        onRefresh: () => context.read<DoctorProvider>().loadQueue(),
        child: doctor.isLoadingQueue && doctor.queue.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : doctor.queue.isEmpty
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
                        const Text('No patients waiting'),
                      ],
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: doctor.queue.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final patient = doctor.queue[index];
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
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => PatientVisitScreen(patient: patient)),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
