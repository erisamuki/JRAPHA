import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_toggle_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/billing_model.dart';
import '../providers/cashier_provider.dart';

const _paymentMethods = <(String, String)>[
  ('cash', 'Cash'),
  ('mtn_momo', 'MTN Mobile Money'),
  ('airtel_money', 'Airtel Money'),
  ('bank_card', 'Bank Card'),
];

class CashierDashboardScreen extends StatefulWidget {
  const CashierDashboardScreen({super.key});

  @override
  State<CashierDashboardScreen> createState() => _CashierDashboardScreenState();
}

class _CashierDashboardScreenState extends State<CashierDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CashierProvider>().loadOutstanding();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cashier = context.watch<CashierProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance · Cashier'),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Outstanding bills',
                    value: '${cashier.outstanding.length}',
                    icon: Icons.receipt_long_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    label: 'Balance to collect',
                    value: _formatUgx(cashier.totalOutstanding),
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
              ],
            ),
          ),
          if (cashier.errorMessage != null)
            MaterialBanner(
              content: Text(cashier.errorMessage!),
              actions: [
                TextButton(
                  onPressed: () =>
                      context.read<CashierProvider>().loadOutstanding(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  context.read<CashierProvider>().loadOutstanding(),
              child: cashier.isLoading && cashier.outstanding.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : cashier.outstanding.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 100),
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        const Center(child: Text('No outstanding bills')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: cashier.outstanding.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final bill = cashier.outstanding[index];
                        return _BillCard(
                          bill: bill,
                          onTap: () => _showBillDetails(bill),
                          onPay: () => _showPaymentDialog(bill),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showBillDetails(BillingModel bill) async {
    final provider = context.read<CashierProvider>();
    final details = await provider.getBillingDetails(bill.id);
    if (!mounted) return;
    if (details == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Unable to load billing details.',
          ),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(bill.fullName),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Patient ${bill.patientNumber} · ${bill.visitType}'),
                const SizedBox(height: 16),
                Text('Charges', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                if (details.items.isEmpty)
                  const Text('No item breakdown available.'),
                ...details.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${item.description} × ${item.quantity}'),
                        ),
                        Text(_formatUgx(item.totalPrice)),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 24),
                _DetailRow(
                  label: 'Bill total',
                  value: _formatUgx(bill.totalAmount),
                ),
                _DetailRow(label: 'Paid', value: _formatUgx(bill.amountPaid)),
                _DetailRow(
                  label: 'Balance due',
                  value: _formatUgx(bill.balanceDue),
                ),
                const SizedBox(height: 16),
                Text(
                  'Payment history',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                if (details.payments.isEmpty)
                  const Text('No payments recorded yet.'),
                ...details.payments.map(
                  (payment) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(_paymentMethodLabel(payment.paymentMethod)),
                    subtitle: Text(
                      [
                        if (payment.reference != null &&
                            payment.reference!.isNotEmpty)
                          'Ref ${payment.reference}',
                        if (payment.createdAt != null)
                          _formatDate(payment.createdAt!),
                      ].join(' · '),
                    ),
                    trailing: Text(_formatUgx(payment.amount)),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: bill.balanceDue > 0
                ? () {
                    Navigator.of(dialogContext).pop();
                    _showPaymentDialog(bill);
                  }
                : null,
            child: const Text('Record payment'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPaymentDialog(BillingModel bill) async {
    final amountController = TextEditingController(
      text: bill.balanceDue.toStringAsFixed(2),
    );
    final referenceController = TextEditingController();
    var selectedMethod = _paymentMethods.first.$1;
    var isSubmitting = false;
    String? errorMessage;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Record payment'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${bill.fullName} · balance ${_formatUgx(bill.balanceDue)}',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount (UGX)',
                    prefixText: 'UGX ',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment method',
                  ),
                  items: _paymentMethods
                      .map(
                        (method) => DropdownMenuItem(
                          value: method.$1,
                          child: Text(method.$2),
                        ),
                      )
                      .toList(),
                  onChanged: isSubmitting
                      ? null
                      : (value) {
                          if (value != null) {
                            setDialogState(() => selectedMethod = value);
                          }
                        },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: referenceController,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Transaction reference (optional)',
                    counterText: '',
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Verify the mobile money or card transaction before recording it.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final amount = double.tryParse(
                        amountController.text.trim(),
                      );
                      if (amount == null || amount <= 0) {
                        setDialogState(
                          () => errorMessage =
                              'Enter a valid amount greater than zero.',
                        );
                        return;
                      }
                      if (amount > bill.balanceDue) {
                        setDialogState(
                          () => errorMessage =
                              'Amount cannot exceed the balance due.',
                        );
                        return;
                      }
                      setDialogState(() {
                        isSubmitting = true;
                        errorMessage = null;
                      });
                      final provider = this.context.read<CashierProvider>();
                      final success = await provider.recordPayment(
                        billingId: bill.id,
                        amount: amount,
                        paymentMethod: selectedMethod,
                        reference: referenceController.text,
                      );
                      if (!mounted || !dialogContext.mounted) return;
                      if (success) {
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Payment recorded successfully.'),
                          ),
                        );
                      } else {
                        setDialogState(() {
                          isSubmitting = false;
                          errorMessage =
                              provider.errorMessage ??
                              'Failed to record payment.';
                        });
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Record payment'),
            ),
          ],
        ),
      ),
    );
    amountController.dispose();
    referenceController.dispose();
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}

class _BillCard extends StatelessWidget {
  final BillingModel bill;
  final VoidCallback onTap;
  final VoidCallback onPay;

  const _BillCard({
    required this.bill,
    required this.onTap,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    bill.fullName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  _formatUgx(bill.balanceDue),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              [
                bill.patientNumber,
                bill.visitType,
                if (bill.createdAt != null) _formatDate(bill.createdAt!),
              ].where((value) => value.isNotEmpty).join(' · '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Total ${_formatUgx(bill.totalAmount)}  ·  Paid ${_formatUgx(bill.amountPaid)}',
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: onPay,
                child: const Text('Record payment'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

String _formatUgx(double amount) => 'UGX ${amount.toStringAsFixed(0)}';

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String _paymentMethodLabel(String value) => switch (value) {
  'mtn_momo' => 'MTN Mobile Money',
  'airtel_money' => 'Airtel Money',
  'bank_card' => 'Bank Card',
  'cash' => 'Cash',
  'insurance' => 'Insurance',
  'other' => 'Other',
  _ => value,
};
