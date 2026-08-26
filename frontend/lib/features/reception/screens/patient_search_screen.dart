import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/reception_provider.dart';
import '../models/patient_model.dart';
import 'register_patient_screen.dart';

/// Lets reception search for an existing patient, or register a new one,
/// then pick a visit type (OPD/in-patient) to create a visit for them.
class PatientSearchScreen extends StatefulWidget {
  const PatientSearchScreen({super.key});

  @override
  State<PatientSearchScreen> createState() => _PatientSearchScreenState();
}

class _PatientSearchScreenState extends State<PatientSearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _runSearch(String query) {
    context.read<ReceptionProvider>().searchPatients(query);
  }

  Future<void> _openRegisterPatient() async {
    final newPatient = await Navigator.of(
      context,
    ).push<PatientModel>(MaterialPageRoute(builder: (_) => const RegisterPatientScreen()));
    if (newPatient != null && mounted) {
      _showVisitTypeSheet(newPatient);
    }
  }

  Future<void> _showVisitTypeSheet(PatientModel patient) async {
    final visitType = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Start a visit for ${patient.fullName}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.groups_rounded),
              title: const Text('OPD (Outpatient)'),
              onTap: () => Navigator.pop(context, 'opd'),
            ),
            ListTile(
              leading: const Icon(Icons.bed_rounded),
              title: const Text('In-Patient (Admission)'),
              onTap: () => Navigator.pop(context, 'inpatient'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (visitType == null || !mounted) return;

    final provider = context.read<ReceptionProvider>();
    final success = await provider.createVisit(patientId: patient.id, visitType: visitType);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${visitType == 'opd' ? 'OPD' : 'In-patient'} visit created for ${patient.fullName}',
          ),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Failed to create visit')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReceptionProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Find Patient')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRegisterPatient,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('New Patient'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _runSearch,
              decoration: const InputDecoration(
                hintText: 'Search by name, phone, or patient number',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: provider.isSearching
                ? const Center(child: CircularProgressIndicator())
                : provider.searchResults.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.isEmpty
                          ? 'Search for a patient, or register a new one'
                          : 'No patients found',
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.searchResults.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final patient = provider.searchResults[index];
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
                            '${patient.patientNumber}${patient.phone != null ? ' · ${patient.phone}' : ''}',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _showVisitTypeSheet(patient),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
