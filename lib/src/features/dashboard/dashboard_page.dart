import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/trades/trade_provider.dart';
import '../../core/trades/trade_type.dart';
import '../../shared/widgets/shell_scaffold.dart';
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

    return ShellScaffold(
      title: 'Dashboard',
      child: jobsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load dashboard: $e')),
        data: (jobs) {
          final total = jobs.length;
          final scheduled = jobs.where((j) => j.status == JobStatus.scheduled.value).length;
          final inProgress = jobs.where((j) => j.status == JobStatus.inProgress.value).length;
          final done = jobs.where((j) => j.status == JobStatus.done.value).length;
          final unassigned = jobs.where((j) => (j.technicianName ?? '').trim().isEmpty).length;
          final urgent = jobs.where((j) => j.priority == 'urgent').length;

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
                  _MetricCard(label: 'In Progress', value: inProgress.toString()),
                  _MetricCard(label: 'Done', value: done.toString()),
                  _MetricCard(label: 'Unassigned', value: unassigned.toString()),
                  _MetricCard(label: 'Urgent', value: urgent.toString()),
                ],
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
