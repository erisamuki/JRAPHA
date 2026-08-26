import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/nurse_provider.dart';
import '../models/nurse_queue_item.dart';
import '../../../core/widgets/app_text_field.dart';

class VitalsEntryScreen extends StatefulWidget {
  final NurseQueueItem patient;
  const VitalsEntryScreen({super.key, required this.patient});

  @override
  State<VitalsEntryScreen> createState() => _VitalsEntryScreenState();
}

class _VitalsEntryScreenState extends State<VitalsEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bpController = TextEditingController();
  final _tempController = TextEditingController();
  final _pulseController = TextEditingController();
  final _respController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _bpController.dispose();
    _tempController.dispose();
    _pulseController.dispose();
    _respController.dispose();
    _spo2Controller.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<NurseProvider>();
    final success = await provider.recordVitals(
      visitId: widget.patient.visitId,
      bloodPressure: _bpController.text.trim().isEmpty ? null : _bpController.text.trim(),
      temperatureC: double.tryParse(_tempController.text.trim()),
      pulseBpm: int.tryParse(_pulseController.text.trim()),
      respRate: int.tryParse(_respController.text.trim()),
      spo2Percent: int.tryParse(_spo2Controller.text.trim()),
      weightKg: double.tryParse(_weightController.text.trim()),
      heightCm: double.tryParse(_heightController.text.trim()),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Vitals recorded for ${widget.patient.fullName}')));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Failed to record vitals')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NurseProvider>();
    final theme = Theme.of(context);
    final p = widget.patient;

    return Scaffold(
      appBar: AppBar(title: const Text('Record Vitals')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                              child: Text(
                                p.fullName.isNotEmpty ? p.fullName[0].toUpperCase() : '?',
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
                                  Text(p.fullName, style: theme.textTheme.titleMedium),
                                  Text(
                                    '${p.patientNumber}'
                                    '${p.age != null ? ' · ${p.age} yrs' : ''}'
                                    '${p.gender != null ? ' · ${p.gender}' : ''}',
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
                    Text('Vitals', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),

                    AppTextField(
                      controller: _bpController,
                      label: 'Blood pressure (e.g. 120/80)',
                      prefixIcon: Icons.favorite_outline_rounded,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _tempController,
                            label: 'Temp (°C)',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _pulseController,
                            label: 'Pulse (bpm)',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _respController,
                            label: 'Resp. rate',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _spo2Controller,
                            label: 'SpO2 (%)',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _weightController,
                            label: 'Weight (kg)',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _heightController,
                            label: 'Height (cm)',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    AppTextField(
                      controller: _notesController,
                      label: 'Notes (optional)',
                      prefixIcon: Icons.notes_rounded,
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: provider.isSubmitting ? null : _handleSubmit,
                      child: provider.isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text('Save Vitals'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
