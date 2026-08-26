import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/reception_provider.dart';
import '../models/patient_model.dart';
import '../../../core/widgets/app_text_field.dart';

class RegisterPatientScreen extends StatefulWidget {
  const RegisterPatientScreen({super.key});

  @override
  State<RegisterPatientScreen> createState() => _RegisterPatientScreenState();
}

class _RegisterPatientScreenState extends State<RegisterPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ninController = TextEditingController();
  final _districtController = TextEditingController();
  final _nokNameController = TextEditingController();
  final _nokPhoneController = TextEditingController();
  DateTime? _dateOfBirth;
  String? _gender;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _ninController.dispose();
    _districtController.dispose();
    _nokNameController.dispose();
    _nokPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ReceptionProvider>();
    final patient = await provider.registerPatient(
      fullName: _fullNameController.text.trim(),
      dateOfBirth: _dateOfBirth,
      gender: _gender,
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      nin: _ninController.text.trim().isEmpty ? null : _ninController.text.trim(),
      district: _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
      nextOfKinName: _nokNameController.text.trim().isEmpty ? null : _nokNameController.text.trim(),
      nextOfKinPhone: _nokPhoneController.text.trim().isEmpty
          ? null
          : _nokPhoneController.text.trim(),
    );

    if (!mounted) return;

    if (patient != null) {
      Navigator.of(context).pop<PatientModel>(patient);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Failed to register patient')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReceptionProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Register Patient')),
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
                    Text('Patient details', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 20),

                    AppTextField(
                      controller: _fullNameController,
                      label: 'Full name',
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Enter the patient\'s name' : null,
                    ),
                    const SizedBox(height: 16),

                    InkWell(
                      onTap: _pickDateOfBirth,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Date of birth (optional)'),
                        child: Text(
                          _dateOfBirth != null
                              ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                              : 'Tap to select',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: const InputDecoration(labelText: 'Gender (optional)'),
                      items: kGenderOptions
                          .map((g) => DropdownMenuItem(value: g['value'], child: Text(g['label']!)))
                          .toList(),
                      onChanged: (value) => setState(() => _gender = value),
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _phoneController,
                      label: 'Phone (optional)',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _ninController,
                      label: 'National ID / NIN (optional)',
                      prefixIcon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _districtController,
                      label: 'District (optional)',
                      prefixIcon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 24),

                    Text('Next of kin (optional)', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),

                    AppTextField(
                      controller: _nokNameController,
                      label: 'Name',
                      prefixIcon: Icons.people_outline_rounded,
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _nokPhoneController,
                      label: 'Phone',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 28),

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
                          : const Text('Register Patient'),
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
