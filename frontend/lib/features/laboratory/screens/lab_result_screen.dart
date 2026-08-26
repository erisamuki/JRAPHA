import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/lab_provider.dart';
import '../models/lab_queue_item.dart';

class LabResultScreen extends StatefulWidget {
  final LabQueueItem order;
  const LabResultScreen({super.key, required this.order});

  @override
  State<LabResultScreen> createState() => _LabResultScreenState();
}

class _LabResultScreenState extends State<LabResultScreen> {
  final _resultController = TextEditingController();
  bool _isCritical = false;

  @override
  void dispose() {
    _resultController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_resultController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a result before submitting')));
      return;
    }

    final provider = context.read<LabProvider>();
    final success = await provider.submitResult(
      labOrderId: widget.order.id,
      result: _resultController.text.trim(),
      isCritical: _isCritical,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Result submitted for ${widget.order.fullName}')));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Failed to submit result')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LabProvider>();
    final theme = Theme.of(context);
    final order = widget.order;

    return Scaffold(
      appBar: AppBar(title: const Text('Enter Result')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.testName, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            '${order.fullName} · ${order.patientNumber}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _resultController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Result',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    color: _isCritical ? theme.colorScheme.error.withValues(alpha: 0.08) : null,
                    child: SwitchListTile(
                      value: _isCritical,
                      onChanged: (value) => setState(() => _isCritical = value),
                      title: const Text('Flag as critical'),
                      subtitle: const Text('Notifies the ordering doctor immediately'),
                      secondary: Icon(
                        Icons.warning_amber_rounded,
                        color: _isCritical ? theme.colorScheme.error : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: provider.isSubmitting ? null : _handleSubmit,
                    style: _isCritical
                        ? ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.error)
                        : null,
                    child: provider.isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Submit Result'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
