import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/trades/trade_provider.dart';
import '../../core/trades/trade_type.dart';
import '../../shared/models/job.dart';
import '../../shared/widgets/shell_scaffold.dart';
import 'domain/job_priority.dart';
import 'job_list_filters.dart';
import 'job_provider.dart';

class JobsPage extends ConsumerStatefulWidget {
  const JobsPage({super.key});

  @override
  ConsumerState<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends ConsumerState<JobsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  JobQueueFilter _queueFilter = JobQueueFilter.all;

  Color _priorityColor(BuildContext context, String priority) {
    switch (priority) {
      case 'urgent':
        return Theme.of(context).colorScheme.error;
      case 'high':
        return Colors.orange;
      case 'medium':
      case 'normal':
        return Theme.of(context).colorScheme.primary;
      case 'low':
        return Theme.of(context).colorScheme.outline;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workflow = ref.watch(selectedWorkflowProvider);
    final jobsAsync = ref.watch(jobsProvider);
    final syncInProgress = ref.watch(jobsSyncInProgressProvider);
    final lastSyncAt = ref.watch(jobsLastSyncAtProvider);
    final syncError = ref.watch(jobsSyncErrorProvider);
    final pendingCount = ref.watch(jobsPendingActionsCountProvider);

    if (workflow == null) {
      return ShellScaffold(
        title: 'Jobs',
        child: Center(
          child: ElevatedButton(
            onPressed: () => context.go('/onboarding'),
            child: const Text('Choose trade first'),
          ),
        ),
      );
    }

    return ShellScaffold(
      title: 'Jobs',
      child: jobsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load jobs: $e')),
        data: (jobs) {
          final visibleJobs = filterAndSortJobs(
            jobs: jobs,
            queueFilter: _queueFilter,
            query: _query,
          );

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(jobsProvider.notifier).refreshFromRemote(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: syncError == null
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Theme.of(context).colorScheme.errorContainer,
                  child: ListTile(
                    leading: Icon(
                      syncError == null
                          ? Icons.cloud_done_outlined
                          : Icons.cloud_off_outlined,
                    ),
                    title: Text(syncError ?? 'Sync healthy'),
                    subtitle: Text(
                      lastSyncAt == null
                          ? 'No sync timestamp yet'
                          : 'Last sync: ${DateFormat.yMd().add_jm().format(lastSyncAt.toLocal())}${syncInProgress ? ' (syncing...)' : ''}',
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        if (pendingCount > 0)
                          OutlinedButton(
                            onPressed: () => ref
                                .read(jobsProvider.notifier)
                                .retryPendingActions(),
                            child: Text('Retry ($pendingCount)'),
                          ),
                        OutlinedButton(
                          onPressed: syncInProgress
                              ? null
                              : () => ref
                                    .read(jobsProvider.notifier)
                                    .refreshFromRemote(),
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Job types for ${workflow.trade.label}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () =>
                          _showCreateJobDialog(context, ref, workflow.jobTypes),
                      icon: const Icon(Icons.add),
                      label: const Text('New job'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...workflow.jobTypes.map((type) => ListTile(title: Text(type))),
                const SizedBox(height: 16),
                Text(
                  'Required intake fields',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...workflow.requiredFields.map((f) => ListTile(title: Text(f))),
                const SizedBox(height: 20),
                Text(
                  'Created jobs (${visibleJobs.length}/${jobs.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search customer, address, tech, notes',
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.clear),
                          ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _queueFilter == JobQueueFilter.all,
                      onSelected: (_) =>
                          setState(() => _queueFilter = JobQueueFilter.all),
                    ),
                    ChoiceChip(
                      label: const Text('Open'),
                      selected: _queueFilter == JobQueueFilter.open,
                      onSelected: (_) =>
                          setState(() => _queueFilter = JobQueueFilter.open),
                    ),
                    ChoiceChip(
                      label: const Text('Unassigned'),
                      selected: _queueFilter == JobQueueFilter.unassigned,
                      onSelected: (_) => setState(
                        () => _queueFilter = JobQueueFilter.unassigned,
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('Done'),
                      selected: _queueFilter == JobQueueFilter.done,
                      onSelected: (_) =>
                          setState(() => _queueFilter = JobQueueFilter.done),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (visibleJobs.isEmpty)
                  Card(
                    child: ListTile(
                      title: const Text('No matching jobs'),
                      subtitle: Text(
                        _query.isEmpty
                            ? 'Try another queue filter.'
                            : 'Try a broader search query.',
                      ),
                    ),
                  )
                else
                  ...visibleJobs.map(
                    (job) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${job.customerName} • ${job.jobType}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(job.address),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(
                                  avatar: Icon(
                                    Icons.flag,
                                    size: 16,
                                    color: _priorityColor(
                                      context,
                                      job.priority,
                                    ),
                                  ),
                                  label: Text(job.priority.toUpperCase()),
                                ),
                                Chip(label: Text(job.status.toUpperCase())),
                                if ((job.technicianName ?? '')
                                    .trim()
                                    .isNotEmpty)
                                  Chip(
                                    label: Text('Tech: ${job.technicianName}'),
                                  ),
                                if ((job.etaWindow ?? '').trim().isNotEmpty)
                                  Chip(label: Text('ETA: ${job.etaWindow}')),
                                if ((job.proofPhotoCount ??
                                        job.proofPhotoUrls?.length ??
                                        0) >
                                    0)
                                  Chip(
                                    label: Text(
                                      'Photos: ${job.proofPhotoCount ?? job.proofPhotoUrls?.length}',
                                    ),
                                  ),
                              ],
                            ),
                            if ((job.completionNotes ?? '').trim().isNotEmpty ||
                                (job.customerSignatureName ?? '')
                                    .trim()
                                    .isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${(job.completionNotes ?? '').trim().isNotEmpty ? 'Completion: ${job.completionNotes}' : ''}${(job.customerSignatureName ?? '').trim().isNotEmpty ? '${(job.completionNotes ?? '').trim().isNotEmpty ? ' • ' : ''}Signed: ${job.customerSignatureName}' : ''}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            if (job.status == 'done') ...[
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _createFollowUpDialog(context, ref, job),
                                  icon: const Icon(Icons.repeat),
                                  label: const Text('Create Follow-up'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _createFollowUpDialog(
    BuildContext context,
    WidgetRef ref,
    Job job,
  ) async {
    int days = 30;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create follow-up job'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Create a recurring follow-up for ${job.customerName}?'),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: days,
                items: const [7, 14, 30, 60, 90]
                    .map(
                      (d) =>
                          DropdownMenuItem(value: d, child: Text('In $d days')),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => days = value);
                },
                decoration: const InputDecoration(labelText: 'Interval'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await ref
                    .read(jobsProvider.notifier)
                    .createFollowUp(source: job, daysOut: days);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateJobDialog(
    BuildContext context,
    WidgetRef ref,
    List<String> jobTypes,
  ) async {
    final customerCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final techCtrl = TextEditingController();
    final etaCtrl = TextEditingController();
    String selectedType = jobTypes.first;
    JobPriority selectedPriority = JobPriority.normal;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Create job'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: customerCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Customer name',
                    ),
                  ),
                  TextField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    items: jobTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => selectedType = value);
                    },
                    decoration: const InputDecoration(labelText: 'Job type'),
                  ),
                  DropdownButtonFormField<JobPriority>(
                    initialValue: selectedPriority,
                    items: JobPriority.values
                        .map(
                          (p) =>
                              DropdownMenuItem(value: p, child: Text(p.label)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedPriority = value);
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Priority'),
                  ),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                    ),
                  ),
                  TextField(
                    controller: techCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Technician (optional)',
                    ),
                  ),
                  TextField(
                    controller: etaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ETA window (optional)',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (customerCtrl.text.trim().isEmpty ||
                      addressCtrl.text.trim().isEmpty) {
                    return;
                  }
                  await ref
                      .read(jobsProvider.notifier)
                      .addJob(
                        customerName: customerCtrl.text.trim(),
                        address: addressCtrl.text.trim(),
                        jobType: selectedType,
                        priority: selectedPriority,
                        notes: notesCtrl.text.trim().isEmpty
                            ? null
                            : notesCtrl.text.trim(),
                        technicianName: techCtrl.text.trim().isEmpty
                            ? null
                            : techCtrl.text.trim(),
                        etaWindow: etaCtrl.text.trim().isEmpty
                            ? null
                            : etaCtrl.text.trim(),
                      );
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Create'),
              ),
            ],
          ),
        );
      },
    );
  }
}
