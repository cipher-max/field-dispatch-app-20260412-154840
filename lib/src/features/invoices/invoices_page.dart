import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../jobs/domain/job_status.dart';
import '../jobs/job_provider.dart';
import 'invoice_provider.dart';
import '../../shared/widgets/shell_scaffold.dart';

class InvoicesPage extends ConsumerWidget {
  const InvoicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(jobsProvider);
    final invoicesAsync = ref.watch(invoiceProvider);

    return ShellScaffold(
      title: 'Invoices',
      child: invoicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Invoice error: $e')),
        data: (invoices) {
          final completedJobs =
              jobsAsync.asData?.value
                  .where((j) => j.status == JobStatus.done.value)
                  .toList() ??
              [];

          final invoiceByJobId = {for (final inv in invoices) inv.jobId: inv};

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Create invoice from completed jobs',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (completedJobs.isEmpty)
                const Card(
                  child: ListTile(title: Text('No completed jobs yet')),
                )
              else
                ...completedJobs.map((job) {
                  final existing = invoiceByJobId[job.id];
                  return Card(
                    child: ListTile(
                      title: Text('${job.customerName} • ${job.jobType}'),
                      subtitle: Text(
                        existing == null
                            ? job.address
                            : '${job.address}\nInvoice: ${existing.status.toUpperCase()} • \$${(existing.amountCents / 100).toStringAsFixed(2)}',
                      ),
                      isThreeLine: existing != null,
                      trailing: FilledButton(
                        onPressed: existing != null
                            ? null
                            : () => _createInvoiceDialog(
                                context,
                                ref,
                                job.id,
                                job.customerName,
                              ),
                        child: Text(existing == null ? 'Invoice' : 'Invoiced'),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 20),
              Text(
                'Invoices (${invoices.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (invoices.isEmpty)
                const Card(child: ListTile(title: Text('No invoices yet')))
              else
                ...invoices.map(
                  (inv) => Card(
                    child: ListTile(
                      title: Text(inv.customerName),
                      subtitle: Text(
                        'Amount: \$${(inv.amountCents / 100).toStringAsFixed(2)} • ${inv.status.toUpperCase()}',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) => ref
                            .read(invoiceProvider.notifier)
                            .markStatus(inv.id, value),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'draft',
                            child: Text('Mark Draft'),
                          ),
                          PopupMenuItem(
                            value: 'sent',
                            child: Text('Mark Sent'),
                          ),
                          PopupMenuItem(
                            value: 'paid',
                            child: Text('Mark Paid'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createInvoiceDialog(
    BuildContext context,
    WidgetRef ref,
    String jobId,
    String customerName,
  ) async {
    final amountCtrl = TextEditingController(text: '149.00');

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create invoice'),
        content: TextField(
          controller: amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount (USD)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final parsed = double.tryParse(amountCtrl.text.trim());
              if (parsed == null || parsed <= 0) return;
              try {
                await ref
                    .read(invoiceProvider.notifier)
                    .createInvoice(
                      jobId: jobId,
                      customerName: customerName,
                      amountCents: (parsed * 100).round(),
                    );
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
