import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../shared/models/job.dart';
import '../../shared/widgets/shell_scaffold.dart';
import '../jobs/domain/job_priority.dart';
import '../jobs/domain/job_status.dart';
import '../jobs/job_provider.dart';
import 'customer_update_message.dart';
import 'dispatch_eta_presets.dart';
import 'dispatch_filters.dart';

class DispatchPage extends ConsumerStatefulWidget {
  const DispatchPage({super.key});

  @override
  ConsumerState<DispatchPage> createState() => _DispatchPageState();
}

class _DispatchPageState extends ConsumerState<DispatchPage> {
  String query = '';
  JobPriority? priorityFilter;
  bool unassignedOnly = false;

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(jobsProvider);

    return ShellScaffold(
      title: 'Dispatch',
      child: jobsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load jobs: $e')),
        data: (jobs) {
          final filtered = filterDispatchJobs(
            jobs: jobs,
            query: query,
            priorityFilter: priorityFilter,
            unassignedOnly: unassignedOnly,
          );
          final recentTechnicians = buildRecentTechnicianNames(jobs);
          final unassignedOpenCount = jobs
              .where((j) => j.status != JobStatus.done.value && (j.technicianName == null || j.technicianName!.trim().isEmpty))
              .length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Search dispatch board',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => query = v),
              ),
              const SizedBox(height: 8),
              if (unassignedOpenCount > 0) ...[
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_rounded),
                    title: Text('$unassignedOpenCount unassigned open job${unassignedOpenCount == 1 ? '' : 's'}'),
                    subtitle: const Text('Use the Unassigned-only filter to dispatch faster.'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All priorities'),
                    selected: priorityFilter == null,
                    onSelected: (_) => setState(() => priorityFilter = null),
                  ),
                  ...JobPriority.values.map(
                    (p) => ChoiceChip(
                      label: Text(p.label),
                      selected: priorityFilter == p,
                      onSelected: (_) => setState(() => priorityFilter = p),
                    ),
                  ),
                  FilterChip(
                    label: const Text('Unassigned only'),
                    selected: unassignedOnly,
                    onSelected: (selected) => setState(() => unassignedOnly = selected),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final status in JobStatus.values) ...[
                Text(status.label.toUpperCase(), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...([...filtered.where((j) => j.status == status.value)]
                      ..sort((a, b) => JobPriorityX.fromValue(b.priority).rank.compareTo(JobPriorityX.fromValue(a.priority).rank)))
                    .map(
                      (job) => Card(
                        child: ListTile(
                          title: Text('${job.customerName} • ${job.jobType}'),
                          subtitle: Text(
                            '${job.address}\nPriority: ${JobPriorityX.fromValue(job.priority).label}${job.technicianName != null ? ' • Tech: ${job.technicianName}' : ''}${job.etaWindow != null ? ' • ETA: ${job.etaWindow}' : ''}',
                          ),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                tooltip: 'Assign tech/ETA',
                                onPressed: () => _showAssignDialog(
                                  context,
                                  ref,
                                  job,
                                  recentTechnicians,
                                ),
                                icon: const Icon(Icons.engineering),
                              ),
                              IconButton(
                                tooltip: 'Copy customer ETA update',
                                onPressed: () => _copyCustomerUpdate(context, job),
                                icon: const Icon(Icons.sms_outlined),
                              ),
                              PopupMenuButton<JobStatus>(
                                onSelected: (value) => ref.read(jobsProvider.notifier).moveStatus(job.id, value),
                                itemBuilder: (_) => JobStatus.values
                                    .where((s) => s != status)
                                    .map((s) => PopupMenuItem(value: s, child: Text('Move to ${s.label}')))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                if (!filtered.any((j) => j.status == status.value))
                  const Card(child: ListTile(title: Text('No jobs'))),
                const SizedBox(height: 16),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _copyCustomerUpdate(BuildContext context, Job job) async {
    final message = buildCustomerUpdateMessage(job);
    await Clipboard.setData(ClipboardData(text: message));

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Customer update copied to clipboard')),
    );
  }

  Future<void> _showAssignDialog(
    BuildContext context,
    WidgetRef ref,
    Job job,
    List<String> recentTechnicians,
  ) async {
    final techCtrl = TextEditingController(text: job.technicianName ?? '');
    final etaCtrl = TextEditingController(text: job.etaWindow ?? '');
    final etaPresets = buildEtaPresets(DateTime.now());

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign technician'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: techCtrl, decoration: const InputDecoration(labelText: 'Technician name')),
            TextField(controller: etaCtrl, decoration: const InputDecoration(labelText: 'ETA window')),
            if (recentTechnicians.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Quick tech', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tech in recentTechnicians)
                    ActionChip(
                      label: Text(tech),
                      onPressed: () {
                        techCtrl.text = tech;
                      },
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Text('Quick ETA', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in etaPresets)
                  ActionChip(
                    label: Text(preset),
                    onPressed: () {
                      etaCtrl.text = preset;
                    },
                  ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await ref.read(jobsProvider.notifier).updateAssignment(
                    jobId: job.id,
                    technicianName: techCtrl.text.trim().isEmpty ? null : techCtrl.text.trim(),
                    etaWindow: etaCtrl.text.trim().isEmpty ? null : etaCtrl.text.trim(),
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
