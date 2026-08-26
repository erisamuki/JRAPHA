import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pharmacy_provider.dart';
import '../models/pharmacy_models.dart';
import 'add_stock_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/theme_toggle_button.dart';

class PharmacyDashboardScreen extends StatefulWidget {
  const PharmacyDashboardScreen({super.key});

  @override
  State<PharmacyDashboardScreen> createState() => _PharmacyDashboardScreenState();
}

class _PharmacyDashboardScreenState extends State<PharmacyDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PharmacyProvider>().loadQueue();
      context.read<PharmacyProvider>().loadStock();
    });
  }

  Future<void> _handleDispense(PharmacyQueueItem rx) async {
    final provider = context.read<PharmacyProvider>();
    final success = await provider.dispense(rx.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Dispensed ${rx.drugName}' : (provider.errorMessage ?? 'Failed')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pharmacy = context.watch<PharmacyProvider>();
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pharmacy'),
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
              Tab(text: 'Dispensing', icon: Icon(Icons.medication_liquid_rounded, size: 20)),
              Tab(text: 'Stock', icon: Icon(Icons.inventory_2_rounded, size: 20)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ===== Dispensing tab =====
            RefreshIndicator(
              onRefresh: () => context.read<PharmacyProvider>().loadQueue(),
              child: pharmacy.isLoadingQueue && pharmacy.queue.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : pharmacy.queue.isEmpty
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
                              const Text('No prescriptions waiting'),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: pharmacy.queue.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final rx = pharmacy.queue[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.medication_outlined),
                            title: Text(rx.drugName),
                            subtitle: Text(
                              '${rx.fullName} · ${rx.patientNumber}'
                              '${rx.dosage != null ? ' · ${rx.dosage}' : ''}',
                            ),
                            trailing: FilledButton(
                              onPressed: () => _handleDispense(rx),
                              child: const Text('Dispense'),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // ===== Stock tab =====
            RefreshIndicator(
              onRefresh: () => context.read<PharmacyProvider>().loadStock(),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${pharmacy.stock.length} items in stock',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        FilledButton.icon(
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add Stock'),
                          onPressed: () async {
                            await Navigator.of(
                              context,
                            ).push(MaterialPageRoute(builder: (_) => const AddStockScreen()));
                            if (context.mounted) context.read<PharmacyProvider>().loadStock();
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: pharmacy.isLoadingStock && pharmacy.stock.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : pharmacy.stock.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 100),
                              Center(child: Text('No stock added yet')),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: pharmacy.stock.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = pharmacy.stock[index];
                              final flagged = item.isLowStock || item.isNearExpiry;
                              return Card(
                                color: flagged
                                    ? theme.colorScheme.error.withValues(alpha: 0.06)
                                    : null,
                                child: ListTile(
                                  leading: Icon(
                                    Icons.inventory_2_outlined,
                                    color: flagged ? theme.colorScheme.error : null,
                                  ),
                                  title: Text(item.drugName),
                                  subtitle: Text(
                                    '${item.quantity}${item.unit != null ? ' ${item.unit}' : ''} in stock'
                                    '${item.expiryDate != null ? ' · exp. ${item.expiryDate!.day}/${item.expiryDate!.month}/${item.expiryDate!.year}' : ''}',
                                  ),
                                  trailing: flagged
                                      ? Chip(
                                          label: Text(
                                            item.isLowStock ? 'Low stock' : 'Near expiry',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: theme.colorScheme.error,
                                            ),
                                          ),
                                          backgroundColor: theme.colorScheme.error.withValues(
                                            alpha: 0.12,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
