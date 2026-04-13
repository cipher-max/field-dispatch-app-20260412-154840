import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/trades/trade_provider.dart';
import '../../core/trades/trade_type.dart';
import '../../shared/widgets/shell_scaffold.dart';
import '../invoices/invoice_provider.dart';
import '../jobs/domain/job_status.dart';
import '../jobs/job_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflow = ref.watch(selectedWorkflowProvider);

    if (workflow == null) {
      return ShellScaffold(
        title: 'Dashboard',
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Start by choosing your trade template'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go('/onboarding'),
                child: const Text('Choose trade'),
              ),
            ],
          ),
        ),
      );
    }

    final jobsAsync = ref.watch(jobsProvider);
    final invoicesAsync = ref.watch(invoiceProvider);
    final pendingSync = ref.watch(jobsPendingActionsCountProvider);

    return ShellScaffold(
      title: 'Dashboard',
      child: jobsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load dashboard: $e')),
        data: (jobs) {
          final invoices = invoicesAsync.asData?.value ?? [];
          final total = jobs.length;
          final scheduled = jobs
              .where((j) => j.status == JobStatus.scheduled.value)
              .length;
          final inProgress = jobs
              .where((j) => j.status == JobStatus.inProgress.value)
              .length;
          final done = jobs
              .where((j) => j.status == JobStatus.done.value)
              .length;
          final unassigned = jobs
              .where((j) => (j.technicianName ?? '').trim().isEmpty)
              .length;
          final urgent = jobs.where((j) => j.priority == 'urgent').length;
          final needsEta = jobs
              .where(
                (j) =>
                    (j.technicianName ?? '').trim().isNotEmpty &&
                    (j.etaWindow ?? '').trim().isEmpty &&
                    j.status != JobStatus.done.value,
              )
              .length;
          final paidCents = invoices
              .where((i) => i.documentType == 'invoice')
              .fold<int>(0, (sum, i) => sum + i.amountPaidCents);
          final outstandingCents = invoices
              .where((i) => i.documentType == 'invoice')
              .fold<int>(0, (sum, i) => sum + i.amountDueCents);
          final invoicesPartial = invoices
              .where(
                (i) => i.documentType == 'invoice' && i.status == 'partial',
              )
              .length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${workflow.trade.label} workflow active${workflow.trade.isBeta ? ' (Beta)' : ''}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetricCard(label: 'Total', value: total.toString()),
                  _MetricCard(label: 'Scheduled', value: scheduled.toString()),
                  _MetricCard(
                    label: 'In Progress',
                    value: inProgress.toString(),
                  ),
                  _MetricCard(label: 'Done', value: done.toString()),
                  _MetricCard(
                    label: 'Unassigned',
                    value: unassigned.toString(),
                  ),
                  _MetricCard(label: 'Urgent', value: urgent.toString()),
                  _MetricCard(
                    label: 'Outstanding',
                    value: '\$${(outstandingCents / 100).toStringAsFixed(0)}',
                  ),
                  _MetricCard(
                    label: 'Paid',
                    value: '\$${(paidCents / 100).toStringAsFixed(0)}',
                  ),
                  _MetricCard(
                    label: 'Pending Sync',
                    value: pendingSync.toString(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Quick actions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => context.go('/jobs'),
                    icon: const Icon(Icons.add),
                    label: const Text('New Job'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/dispatch'),
                    icon: const Icon(Icons.alt_route),
                    label: const Text('Dispatch Board'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/invoices'),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('Invoices'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Needs attention',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (unassigned > 0)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_rounded),
                    title: Text('$unassigned unassigned jobs'),
                    subtitle: const Text('Assign techs to keep jobs moving.'),
                    trailing: TextButton(
                      onPressed: () => context.go('/dispatch'),
                      child: const Text('Open'),
                    ),
                  ),
                ),
              if (urgent > 0)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.priority_high_rounded),
                    title: Text('$urgent urgent jobs'),
                    subtitle: const Text('Review urgent queue first.'),
                    trailing: TextButton(
                      onPressed: () => context.go('/dispatch'),
                      child: const Text('Open'),
                    ),
                  ),
                ),
              if (needsEta > 0)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.schedule_send_rounded),
                    title: Text('$needsEta assigned jobs missing ETA'),
                    subtitle: const Text(
                      'Set ETA to reduce customer uncertainty.',
                    ),
                    trailing: TextButton(
                      onPressed: () => context.go('/dispatch'),
                      child: const Text('Open'),
                    ),
                  ),
                ),
              if (invoicesPartial > 0)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.request_quote_outlined),
                    title: Text('$invoicesPartial invoices partially paid'),
                    subtitle: const Text(
                      'Follow up to close outstanding balances.',
                    ),
                    trailing: TextButton(
                      onPressed: () => context.go('/invoices'),
                      child: const Text('Open'),
                    ),
                  ),
                ),
              if (pendingSync > 0)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.sync_problem_outlined),
                    title: Text('$pendingSync local changes pending sync'),
                    subtitle: const Text(
                      'Retry sync from Dispatch to clear queue.',
                    ),
                    trailing: TextButton(
                      onPressed: () => context.go('/dispatch'),
                      child: const Text('Open'),
                    ),
                  ),
                ),
              if (unassigned == 0 &&
                  urgent == 0 &&
                  needsEta == 0 &&
                  invoicesPartial == 0 &&
                  pendingSync == 0)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline),
                    title: Text('Everything looks healthy'),
                    subtitle: Text('No urgent dispatch blockers right now.'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
