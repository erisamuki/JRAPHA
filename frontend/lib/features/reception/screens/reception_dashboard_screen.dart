import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/reception_provider.dart';
import '../services/reception_service.dart';
import '../models/visit_model.dart';
import 'patient_search_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/theme_toggle_button.dart';

class ReceptionDashboardScreen extends StatefulWidget {
  const ReceptionDashboardScreen({super.key});

  @override
  State<ReceptionDashboardScreen> createState() => _ReceptionDashboardScreenState();
}

class _ReceptionDashboardScreenState extends State<ReceptionDashboardScreen> {
  final _appointmentService = ReceptionService();
  List<dynamic> _appointments = [];
  bool _loadingAppointments = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReceptionProvider>().loadQueues();
    });
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _loadingAppointments = true);
    try {
      final appts = await _appointmentService.getAppointments();
      if (mounted) setState(() => _appointments = appts);
    } catch (_) {
      // Non-fatal for the dashboard; the tab will just show empty.
    } finally {
      if (mounted) setState(() => _loadingAppointments = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reception = context.watch<ReceptionProvider>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reception'),
          actions: [
            const ThemeToggleButton(),
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => context.read<AuthProvider>().logout(),
            ),
            const SizedBox(width: 4),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'OPD', icon: Icon(Icons.groups_rounded, size: 20)),
              Tab(text: 'In-Patients', icon: Icon(Icons.bed_rounded, size: 20)),
              Tab(text: 'Appointments', icon: Icon(Icons.event_rounded, size: 20)),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PatientSearchScreen()));
            if (context.mounted) {
              context.read<ReceptionProvider>().loadQueues();
            }
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Visit'),
        ),
        body: TabBarView(
          children: [
            _VisitList(
              visits: reception.opdQueue,
              isLoading: reception.isLoadingQueues,
              emptyLabel: 'No patients in the OPD queue',
              onRefresh: () => context.read<ReceptionProvider>().loadQueues(),
            ),
            _VisitList(
              visits: reception.inpatients,
              isLoading: reception.isLoadingQueues,
              emptyLabel: 'No admitted in-patients',
              onRefresh: () => context.read<ReceptionProvider>().loadQueues(),
              showWard: true,
            ),
            _AppointmentsList(
              appointments: _appointments,
              isLoading: _loadingAppointments,
              onRefresh: _loadAppointments,
            ),
          ],
        ),
      ),
    );
  }
}

class _VisitList extends StatelessWidget {
  final List<VisitModel> visits;
  final bool isLoading;
  final String emptyLabel;
  final Future<void> Function() onRefresh;
  final bool showWard;

  const _VisitList({
    required this.visits,
    required this.isLoading,
    required this.emptyLabel,
    required this.onRefresh,
    this.showWard = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && visits.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: visits.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 100),
                Center(child: Text(emptyLabel)),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: visits.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final v = visits[index];
                return Card(
                  child: ListTile(
                    leading: Icon(showWard ? Icons.bed_outlined : Icons.person_outline_rounded),
                    title: Text(v.fullName ?? 'Unknown'),
                    subtitle: Text(
                      '${v.patientNumber ?? ''} · ${v.status.replaceAll('_', ' ')}'
                      '${showWard && v.ward != null ? ' · Ward ${v.ward}' : ''}'
                      '${showWard && v.bedNumber != null ? ' · Bed ${v.bedNumber}' : ''}',
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _AppointmentsList extends StatelessWidget {
  final List<dynamic> appointments;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  const _AppointmentsList({
    required this.appointments,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && appointments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: appointments.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 100),
                Center(child: Text('No upcoming appointments')),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: appointments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final a = appointments[index] as Map<String, dynamic>;
                final scheduledAt = DateTime.tryParse(a['scheduled_at'] as String? ?? '');
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.event_outlined),
                    title: Text(a['full_name'] as String? ?? 'Unknown'),
                    subtitle: Text(
                      scheduledAt != null
                          ? '${scheduledAt.day}/${scheduledAt.month}/${scheduledAt.year} '
                                '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}'
                          : 'Time not set',
                    ),
                    trailing: Chip(
                      label: Text(
                        a['status'] as String? ?? '',
                        style: const TextStyle(fontSize: 11),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
