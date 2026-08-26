import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/doctor_provider.dart';
import '../models/doctor_queue_item.dart';

class PatientVisitScreen extends StatefulWidget {
  final DoctorQueueItem patient;
  const PatientVisitScreen({super.key, required this.patient});

  @override
  State<PatientVisitScreen> createState() => _PatientVisitScreenState();
}

class _PatientVisitScreenState extends State<PatientVisitScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorProvider>().loadVisitDetail(widget.patient.visitId);
    });
  }

  Future<void> _showLabOrderDialog() async {
    final controller = TextEditingController();
    final testName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Lab Order'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Test name (e.g. Malaria Test)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Order'),
          ),
        ],
      ),
    );

    if (testName == null || testName.isEmpty || !mounted) return;

    final provider = context.read<DoctorProvider>();
    final success = await provider.createLabOrder(
      visitId: widget.patient.visitId,
      testName: testName,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Lab order created' : (provider.errorMessage ?? 'Failed')),
        ),
      );
    }
  }

  Future<void> _showPrescriptionDialog() async {
    final drugController = TextEditingController();
    final dosageController = TextEditingController();
    final durationController = TextEditingController();
    final quantityController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Prescription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: drugController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Drug name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: dosageController,
              decoration: const InputDecoration(labelText: 'Dosage (e.g. 500mg twice daily)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: durationController,
              decoration: const InputDecoration(labelText: 'Duration (e.g. 5 days)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Prescribe'),
          ),
        ],
      ),
    );

    if (confirmed != true || drugController.text.trim().isEmpty || !mounted) return;

    final provider = context.read<DoctorProvider>();
    final success = await provider.createPrescription(
      visitId: widget.patient.visitId,
      drugName: drugController.text.trim(),
      dosage: dosageController.text.trim().isEmpty ? null : dosageController.text.trim(),
      duration: durationController.text.trim().isEmpty ? null : durationController.text.trim(),
      quantity: int.tryParse(quantityController.text.trim()),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Prescription added' : (provider.errorMessage ?? 'Failed')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DoctorProvider>();
    final detail = provider.visitDetail;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.patient.fullName)),
      body: provider.isLoadingDetail || detail == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                            child: Text(
                              detail.fullName.isNotEmpty ? detail.fullName[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(detail.fullName, style: theme.textTheme.titleMedium),
                                Text(
                                  '${detail.patientNumber} · ${detail.status.replaceAll('_', ' ')}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text('Latest Vitals', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (detail.vitals.isEmpty)
                    const Text('No vitals recorded')
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            if (detail.vitals.first.bloodPressure != null)
                              _VitalChip(label: 'BP', value: detail.vitals.first.bloodPressure!),
                            if (detail.vitals.first.temperatureC != null)
                              _VitalChip(
                                label: 'Temp',
                                value: '${detail.vitals.first.temperatureC}°C',
                              ),
                            if (detail.vitals.first.pulseBpm != null)
                              _VitalChip(
                                label: 'Pulse',
                                value: '${detail.vitals.first.pulseBpm} bpm',
                              ),
                            if (detail.vitals.first.spo2Percent != null)
                              _VitalChip(
                                label: 'SpO2',
                                value: '${detail.vitals.first.spo2Percent}%',
                              ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Lab Orders', style: theme.textTheme.titleMedium),
                      TextButton.icon(
                        onPressed: _showLabOrderDialog,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Order'),
                      ),
                    ],
                  ),
                  if (detail.labOrders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No lab orders yet'),
                    )
                  else
                    ...detail.labOrders.map(
                      (lab) => Card(
                        child: ListTile(
                          leading: Icon(
                            lab.status == 'completed'
                                ? Icons.check_circle_outline_rounded
                                : Icons.hourglass_empty_rounded,
                            color: lab.isCritical ? theme.colorScheme.error : null,
                          ),
                          title: Text(lab.testName),
                          subtitle: Text(lab.result ?? lab.status.replaceAll('_', ' ')),
                          trailing: lab.isCritical
                              ? Chip(
                                  label: const Text('Critical', style: TextStyle(fontSize: 11)),
                                  backgroundColor: theme.colorScheme.error.withValues(alpha: 0.12),
                                  labelStyle: TextStyle(color: theme.colorScheme.error),
                                  visualDensity: VisualDensity.compact,
                                )
                              : null,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Prescriptions', style: theme.textTheme.titleMedium),
                      TextButton.icon(
                        onPressed: _showPrescriptionDialog,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Prescribe'),
                      ),
                    ],
                  ),
                  if (detail.prescriptions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No prescriptions yet'),
                    )
                  else
                    ...detail.prescriptions.map(
                      (rx) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.medication_outlined),
                          title: Text(rx.drugName),
                          subtitle: Text(
                            '${rx.dosage ?? ''}${rx.duration != null ? ' · ${rx.duration}' : ''}',
                          ),
                          trailing: Chip(
                            label: Text(
                              rx.status.replaceAll('_', ' '),
                              style: const TextStyle(fontSize: 11),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _VitalChip extends StatelessWidget {
  final String label;
  final String value;
  const _VitalChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
