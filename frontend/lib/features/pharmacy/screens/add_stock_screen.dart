import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pharmacy_provider.dart';
import '../../../core/widgets/app_text_field.dart';

class AddStockScreen extends StatefulWidget {
  const AddStockScreen({super.key});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _batchController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _reorderController = TextEditingController(text: '10');
  final _priceController = TextEditingController();
  DateTime? _expiryDate;

  @override
  void dispose() {
    _nameController.dispose();
    _batchController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _reorderController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<PharmacyProvider>();
    final success = await provider.addStock(
      drugName: _nameController.text.trim(),
      batchNumber: _batchController.text.trim().isEmpty ? null : _batchController.text.trim(),
      quantity: int.parse(_quantityController.text.trim()),
      unit: _unitController.text.trim().isEmpty ? null : _unitController.text.trim(),
      reorderLevel: int.tryParse(_reorderController.text.trim()),
      expiryDate: _expiryDate,
      unitPriceUgx: double.tryParse(_priceController.text.trim()),
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Failed to add stock')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PharmacyProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Stock')),
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
                    AppTextField(
                      controller: _nameController,
                      label: 'Drug name',
                      prefixIcon: Icons.medication_outlined,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Enter a drug name' : null,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(controller: _batchController, label: 'Batch number (optional)'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _quantityController,
                            label: 'Quantity',
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                (v == null || int.tryParse(v.trim()) == null) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _unitController,
                            label: 'Unit (e.g. tablets)',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _reorderController,
                            label: 'Reorder level',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _priceController,
                            label: 'Unit price (UGX)',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickExpiryDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Expiry date (optional)'),
                        child: Text(
                          _expiryDate != null
                              ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                              : 'Tap to select',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
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
                          : const Text('Add Stock'),
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
