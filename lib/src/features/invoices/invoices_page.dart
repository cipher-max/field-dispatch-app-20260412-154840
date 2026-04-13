import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../shared/models/invoice.dart';
import '../../shared/widgets/shell_scaffold.dart';
import '../../core/config/app_env.dart';
import '../jobs/domain/job_status.dart';
import '../jobs/job_provider.dart';
import 'invoice_provider.dart';
import 'quickbooks_export_service.dart';
import 'stripe_payment_link_service.dart';

class InvoicesPage extends ConsumerWidget {
  const InvoicesPage({super.key});

  static final _stripeLinks = StripePaymentLinkService();
  static final _quickBooks = QuickBooksExportService();

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
          final jobs = jobsAsync.asData?.value ?? [];
          final completedJobs = jobs
              .where((j) => j.status == JobStatus.done.value)
              .toList();
          final openJobs = jobs
              .where((j) => j.status != JobStatus.done.value)
              .toList();

          final docByJobId = {for (final inv in invoices) inv.jobId: inv};
          final totalInvoiced = invoices
              .where((i) => i.documentType == 'invoice')
              .fold<int>(0, (sum, i) => sum + i.amountCents);
          final totalPaid = invoices
              .where((i) => i.documentType == 'invoice')
              .fold<int>(0, (sum, i) => sum + i.amountPaidCents);
          final totalOutstanding = totalInvoiced - totalPaid;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetricCard(
                    label: 'Invoiced',
                    value: _usd(totalInvoiced),
                    icon: Icons.receipt_long_outlined,
                  ),
                  _MetricCard(
                    label: 'Paid',
                    value: _usd(totalPaid),
                    icon: Icons.check_circle_outline,
                  ),
                  _MetricCard(
                    label: 'Outstanding',
                    value: _usd(totalOutstanding),
                    icon: Icons.pending_actions_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.hub_outlined),
                  title: const Text('Integrations readiness'),
                  subtitle: Text(
                    'Stripe links: ${AppEnv.hasStripeLinkBase ? 'configured' : 'not configured'} • QuickBooks app: ${AppEnv.hasQuickBooksClientId ? 'configured' : 'not configured'}',
                  ),
                  trailing: OutlinedButton.icon(
                    onPressed:
                        invoices
                            .where((i) => i.documentType == 'invoice')
                            .isEmpty
                        ? null
                        : () => _exportQuickBooks(context, invoices),
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('Export QB CSV'),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Create estimate from active jobs',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (openJobs.isEmpty)
                const Card(child: ListTile(title: Text('No active jobs')))
              else
                ...openJobs.map((job) {
                  final existing = docByJobId[job.id];
                  return Card(
                    child: ListTile(
                      title: Text('${job.customerName} • ${job.jobType}'),
                      subtitle: Text(
                        existing == null
                            ? job.address
                            : '${job.address}\n${existing.documentType.toUpperCase()}: ${existing.status.toUpperCase()}',
                      ),
                      isThreeLine: existing != null,
                      trailing: FilledButton.tonal(
                        onPressed: existing != null
                            ? null
                            : () => _createEstimateDialog(
                                context,
                                ref,
                                job.id,
                                job.customerName,
                              ),
                        child: Text(existing == null ? 'Estimate' : 'Linked'),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 20),
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
                  final existing = docByJobId[job.id];
                  return Card(
                    child: ListTile(
                      title: Text('${job.customerName} • ${job.jobType}'),
                      subtitle: Text(
                        existing == null
                            ? job.address
                            : '${job.address}\n${existing.documentType.toUpperCase()}: ${existing.status.toUpperCase()} • Due: ${_usd(existing.amountDueCents)}',
                      ),
                      isThreeLine: existing != null,
                      trailing: FilledButton(
                        onPressed: existing == null
                            ? () => _createInvoiceDialog(
                                context,
                                ref,
                                job.id,
                                job.customerName,
                              )
                            : (existing.documentType == 'estimate' &&
                                  existing.status != 'declined')
                            ? () => ref
                                  .read(invoiceProvider.notifier)
                                  .convertEstimateToInvoice(existing.id)
                            : null,
                        child: Text(
                          existing == null
                              ? 'Invoice'
                              : existing.documentType == 'estimate'
                              ? 'Convert'
                              : 'Invoiced',
                        ),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 20),
              Text(
                'Documents (${invoices.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (invoices.isEmpty)
                const Card(child: ListTile(title: Text('No documents yet')))
              else
                ...invoices.map(
                  (inv) => Card(
                    child: ListTile(
                      title: Text(
                        '${inv.customerName} • ${inv.documentType.toUpperCase()}',
                      ),
                      subtitle: Text(
                        'Total: ${_usd(inv.amountCents)} • Paid: ${_usd(inv.amountPaidCents)} • Due: ${_usd(inv.amountDueCents)}\n${inv.status.toUpperCase()}${inv.paymentLinkUrl != null ? ' • LINK READY' : ''}',
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) =>
                            _handleDocumentAction(context, ref, inv, value),
                        itemBuilder: (_) {
                          if (inv.documentType == 'estimate') {
                            return const [
                              PopupMenuItem(
                                value: 'sent',
                                child: Text('Mark Sent'),
                              ),
                              PopupMenuItem(
                                value: 'approved',
                                child: Text('Mark Approved'),
                              ),
                              PopupMenuItem(
                                value: 'declined',
                                child: Text('Mark Declined'),
                              ),
                              PopupMenuItem(
                                value: 'convert',
                                child: Text('Convert to Invoice'),
                              ),
                            ];
                          }

                          return const [
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
                            PopupMenuItem(
                              value: 'payment',
                              child: Text('Record Payment'),
                            ),
                            PopupMenuItem(
                              value: 'payment_link',
                              child: Text('Generate Payment Link'),
                            ),
                            PopupMenuItem(
                              value: 'copy_link',
                              child: Text('Copy Payment Link'),
                            ),
                          ];
                        },
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

  Future<void> _createEstimateDialog(
    BuildContext context,
    WidgetRef ref,
    String jobId,
    String customerName,
  ) async {
    final amountCtrl = TextEditingController(text: '149.00');

    await _createDocumentDialog(
      context: context,
      title: 'Create estimate',
      controller: amountCtrl,
      onCreate: () async {
        final parsed = double.tryParse(amountCtrl.text.trim());
        if (parsed == null || parsed <= 0) return;
        await ref
            .read(invoiceProvider.notifier)
            .createEstimate(
              jobId: jobId,
              customerName: customerName,
              amountCents: (parsed * 100).round(),
            );
      },
    );
  }

  Future<void> _createInvoiceDialog(
    BuildContext context,
    WidgetRef ref,
    String jobId,
    String customerName,
  ) async {
    final amountCtrl = TextEditingController(text: '149.00');

    await _createDocumentDialog(
      context: context,
      title: 'Create invoice',
      controller: amountCtrl,
      onCreate: () async {
        final parsed = double.tryParse(amountCtrl.text.trim());
        if (parsed == null || parsed <= 0) return;
        await ref
            .read(invoiceProvider.notifier)
            .createInvoice(
              jobId: jobId,
              customerName: customerName,
              amountCents: (parsed * 100).round(),
            );
      },
    );
  }

  Future<void> _createDocumentDialog({
    required BuildContext context,
    required String title,
    required TextEditingController controller,
    required Future<void> Function() onCreate,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
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
              try {
                await onCreate();
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

  Future<void> _handleDocumentAction(
    BuildContext context,
    WidgetRef ref,
    Invoice invoice,
    String action,
  ) async {
    if (action == 'convert') {
      await ref
          .read(invoiceProvider.notifier)
          .convertEstimateToInvoice(invoice.id);
      return;
    }

    if (action == 'payment') {
      final ctrl = TextEditingController(
        text: (invoice.amountDueCents / 100).toStringAsFixed(2),
      );
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Record payment'),
          content: TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Payment amount (USD)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final parsed = double.tryParse(ctrl.text.trim());
                if (parsed == null || parsed <= 0) return;
                await ref
                    .read(invoiceProvider.notifier)
                    .recordPayment(
                      invoiceId: invoice.id,
                      paymentCents: (parsed * 100).round(),
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
      return;
    }

    if (action == 'payment_link') {
      final link = _stripeLinks.buildPaymentLink(invoice);
      if (link == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Set STRIPE_PAYMENT_LINK_BASE_URL to enable link generation.',
            ),
          ),
        );
        return;
      }

      await ref
          .read(invoiceProvider.notifier)
          .attachPaymentLink(invoiceId: invoice.id, paymentLinkUrl: link);
      if (!context.mounted) return;
      await Clipboard.setData(ClipboardData(text: link));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment link generated and copied')),
      );
      return;
    }

    if (action == 'copy_link') {
      final link = invoice.paymentLinkUrl;
      if (link == null || link.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No payment link yet for this invoice.'),
          ),
        );
        return;
      }
      await Clipboard.setData(ClipboardData(text: link));
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment link copied')));
      return;
    }

    await ref.read(invoiceProvider.notifier).markStatus(invoice.id, action);
  }

  Future<void> _exportQuickBooks(
    BuildContext context,
    List<Invoice> docs,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final path = await _quickBooks.exportInvoicesCsv(docs);
    await SharePlus.instance.share(
      ShareParams(text: 'QuickBooks invoice export CSV', files: [XFile(path)]),
    );
    messenger.showSnackBar(
      const SnackBar(content: Text('QuickBooks CSV exported to share sheet')),
    );
  }
}

String _usd(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18),
              const SizedBox(height: 6),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
