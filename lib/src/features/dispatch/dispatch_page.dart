import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../shared/models/job.dart';
import '../../shared/widgets/shell_scaffold.dart';
import '../jobs/domain/job_priority.dart';
import '../jobs/domain/job_status.dart';
import '../jobs/job_provider.dart';
import 'customer_update_message.dart';
import 'dispatch_eta_presets.dart';
import 'dispatch_filters.dart';
import 'proof_export_service.dart';
import 'proof_photo_store.dart';
import 'dispatch_status_flow.dart';

class DispatchPage extends ConsumerStatefulWidget {
  const DispatchPage({super.key});

  @override
  ConsumerState<DispatchPage> createState() => _DispatchPageState();
}

class _DispatchPageState extends ConsumerState<DispatchPage> {
  final _picker = ImagePicker();
  final _photoStore = ProofPhotoStore();
  final _exportService = ProofExportService();

  String query = '';
  JobPriority? priorityFilter;
  String? technicianFilter;
  bool unassignedOnly = false;
  bool needsEtaOnly = false;
  bool needsActionOnly = false;
  bool needsCustomerUpdateOnly = false;
  bool needsScopeNotesOnly = false;
  bool needsConfirmationOnly = false;
  bool needsAgingOnly = false;

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

  Color _statusColor(BuildContext context, String status) {
    switch (status) {
      case 'new':
        return Colors.blueGrey;
      case 'scheduled':
        return Colors.indigo;
      case 'in_progress':
        return Colors.deepOrange;
      case 'done':
        return Colors.green;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(jobsProvider);
    final syncInProgress = ref.watch(jobsSyncInProgressProvider);
    final lastSyncAt = ref.watch(jobsLastSyncAtProvider);
    final syncError = ref.watch(jobsSyncErrorProvider);
    final pendingCount = ref.watch(jobsPendingActionsCountProvider);
    final pendingJobIds = ref.watch(jobsPendingActionJobIdsProvider);

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
            technicianFilter: technicianFilter,
            unassignedOnly: unassignedOnly,
            needsEtaOnly: needsEtaOnly,
            needsActionOnly: needsActionOnly,
            needsCustomerUpdateOnly: needsCustomerUpdateOnly,
            needsScopeNotesOnly: needsScopeNotesOnly,
            needsConfirmationOnly: needsConfirmationOnly,
            needsAgingOnly: needsAgingOnly,
          );
          final recentTechnicians = buildRecentTechnicianNames(jobs);
          final unassignedOpenCount = jobs
              .where(
                (j) =>
                    j.status != JobStatus.done.value &&
                    (j.technicianName == null ||
                        j.technicianName!.trim().isEmpty),
              )
              .length;
          final needsEtaCount = jobs.where(jobNeedsEta).length;
          final needsActionCount = jobs.where(jobNeedsDispatchAction).length;
          final needsCustomerUpdateCount = jobs
              .where(jobNeedsCustomerUpdate)
              .length;
          final needsScopeNotesCount = jobs.where(jobNeedsScopeNotes).length;
          final needsConfirmationCount = jobs
              .where(jobNeedsConfirmation)
              .length;
          final agingRiskCount = jobs.where(jobIsAgingRisk).length;

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
                      title: Text(
                        '$unassignedOpenCount unassigned open job${unassignedOpenCount == 1 ? '' : 's'}',
                      ),
                      subtitle: const Text(
                        'Use the Unassigned-only filter to dispatch faster.',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (needsActionCount > 0) ...[
                  Card(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: ListTile(
                      leading: const Icon(Icons.bolt_rounded),
                      title: Text(
                        '$needsActionCount job${needsActionCount == 1 ? '' : 's'} need dispatch action',
                      ),
                      subtitle: const Text(
                        'Unassigned jobs and assigned jobs without ETA.',
                      ),
                      trailing: TextButton(
                        onPressed: () => setState(() => needsActionOnly = true),
                        child: const Text('Focus'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (needsEtaCount > 0) ...[
                  Card(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    child: ListTile(
                      leading: const Icon(Icons.schedule_send_rounded),
                      title: Text(
                        '$needsEtaCount assigned job${needsEtaCount == 1 ? '' : 's'} missing ETA',
                      ),
                      subtitle: const Text(
                        'Set ETA quickly so dispatch and customers stay aligned.',
                      ),
                      trailing: TextButton(
                        onPressed: () => setState(() => needsEtaOnly = true),
                        child: const Text('Filter'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (needsCustomerUpdateCount > 0) ...[
                  Card(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    child: ListTile(
                      leading: const Icon(Icons.mark_chat_unread_outlined),
                      title: Text(
                        '$needsCustomerUpdateCount job${needsCustomerUpdateCount == 1 ? '' : 's'} need customer updates',
                      ),
                      subtitle: const Text(
                        'Scheduled jobs with ETA but no recent customer message.',
                      ),
                      trailing: TextButton(
                        onPressed: () =>
                            setState(() => needsCustomerUpdateOnly = true),
                        child: const Text('Filter'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (needsScopeNotesCount > 0) ...[
                  Card(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: ListTile(
                      leading: const Icon(Icons.assignment_late_outlined),
                      title: Text(
                        '$needsScopeNotesCount active job${needsScopeNotesCount == 1 ? '' : 's'} missing scope notes',
                      ),
                      subtitle: const Text(
                        'Missing details lead to unprepared tech visits and repeat trips.',
                      ),
                      trailing: TextButton(
                        onPressed: () =>
                            setState(() => needsScopeNotesOnly = true),
                        child: const Text('Filter'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (needsConfirmationCount > 0) ...[
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: ListTile(
                      leading: const Icon(Icons.phone_in_talk_outlined),
                      title: Text(
                        '$needsConfirmationCount scheduled job${needsConfirmationCount == 1 ? '' : 's'} need customer confirmation',
                      ),
                      subtitle: const Text(
                        'Unconfirmed appointments are at higher risk for no-shows.',
                      ),
                      trailing: TextButton(
                        onPressed: () =>
                            setState(() => needsConfirmationOnly = true),
                        child: const Text('Filter'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (agingRiskCount > 0) ...[
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: ListTile(
                      leading: const Icon(Icons.timer_off_outlined),
                      title: Text(
                        '$agingRiskCount open job${agingRiskCount == 1 ? '' : 's'} aging 2+ days',
                      ),
                      subtitle: const Text(
                        'Aging jobs can slip through the cracks and hurt conversion.',
                      ),
                      trailing: TextButton(
                        onPressed: () => setState(() => needsAgingOnly = true),
                        child: const Text('Filter'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All techs'),
                      selected: technicianFilter == null,
                      onSelected: (_) =>
                          setState(() => technicianFilter = null),
                    ),
                    ...recentTechnicians.map(
                      (tech) => ChoiceChip(
                        label: Text(tech),
                        selected:
                            technicianFilter?.toLowerCase() ==
                            tech.toLowerCase(),
                        onSelected: (_) =>
                            setState(() => technicianFilter = tech),
                      ),
                    ),
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
                      onSelected: (selected) =>
                          setState(() => unassignedOnly = selected),
                    ),
                    FilterChip(
                      label: const Text('Needs ETA'),
                      selected: needsEtaOnly,
                      onSelected: (selected) =>
                          setState(() => needsEtaOnly = selected),
                    ),
                    FilterChip(
                      label: const Text('Needs action'),
                      selected: needsActionOnly,
                      onSelected: (selected) =>
                          setState(() => needsActionOnly = selected),
                    ),
                    FilterChip(
                      label: const Text('Needs customer update'),
                      selected: needsCustomerUpdateOnly,
                      onSelected: (selected) =>
                          setState(() => needsCustomerUpdateOnly = selected),
                    ),
                    FilterChip(
                      label: const Text('Missing scope notes'),
                      selected: needsScopeNotesOnly,
                      onSelected: (selected) =>
                          setState(() => needsScopeNotesOnly = selected),
                    ),
                    FilterChip(
                      label: const Text('Needs confirmation'),
                      selected: needsConfirmationOnly,
                      onSelected: (selected) =>
                          setState(() => needsConfirmationOnly = selected),
                    ),
                    FilterChip(
                      label: const Text('Aging 2+ days'),
                      selected: needsAgingOnly,
                      onSelected: (selected) =>
                          setState(() => needsAgingOnly = selected),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final status in JobStatus.values) ...[
                  Text(
                    status.label.toUpperCase(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...([...filtered.where((j) => j.status == status.value)]
                        ..sort(
                          (a, b) =>
                              JobPriorityX.fromValue(b.priority).rank.compareTo(
                                JobPriorityX.fromValue(a.priority).rank,
                              ),
                        ))
                      .map((job) {
                        final nextStatus = nextDispatchStatus(status);
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${job.customerName} • ${job.jobType}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
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
                                      label: Text(
                                        JobPriorityX.fromValue(
                                          job.priority,
                                        ).label,
                                      ),
                                    ),
                                    Chip(
                                      avatar: Icon(
                                        Icons.track_changes,
                                        size: 16,
                                        color: _statusColor(
                                          context,
                                          job.status,
                                        ),
                                      ),
                                      label: Text(status.label),
                                    ),
                                    if ((job.technicianName ?? '')
                                        .trim()
                                        .isNotEmpty)
                                      Chip(
                                        label: Text(
                                          'Tech: ${job.technicianName}',
                                        ),
                                      ),
                                    if ((job.etaWindow ?? '').trim().isNotEmpty)
                                      Chip(
                                        label: Text('ETA: ${job.etaWindow}'),
                                      ),
                                    if ((job.proofPhotoCount ??
                                            job.proofPhotoUrls?.length ??
                                            0) >
                                        0)
                                      Chip(
                                        label: Text(
                                          'Photos: ${job.proofPhotoCount ?? job.proofPhotoUrls?.length}',
                                        ),
                                      ),
                                    if (job.status ==
                                            JobStatus.scheduled.value &&
                                        (job.etaWindow ?? '').trim().isNotEmpty)
                                      Chip(
                                        avatar: Icon(
                                          job.customerConfirmedAt == null
                                              ? Icons.pending_actions_outlined
                                              : Icons.verified_outlined,
                                          size: 16,
                                        ),
                                        label: Text(
                                          job.customerConfirmedAt == null
                                              ? 'Unconfirmed'
                                              : 'Confirmed',
                                        ),
                                      ),
                                    Chip(
                                      avatar: Icon(
                                        pendingJobIds.contains(job.id)
                                            ? Icons.sync_problem_outlined
                                            : Icons.cloud_done_outlined,
                                        size: 16,
                                      ),
                                      label: Text(
                                        pendingJobIds.contains(job.id)
                                            ? 'Pending sync'
                                            : 'Synced',
                                      ),
                                    ),
                                  ],
                                ),
                                if ((job.completionNotes ?? '')
                                        .trim()
                                        .isNotEmpty ||
                                    (job.customerSignatureName ?? '')
                                        .trim()
                                        .isNotEmpty ||
                                    job.lastCustomerMessageAt != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '${(job.completionNotes ?? '').trim().isNotEmpty ? 'Completion: ${job.completionNotes}' : ''}${(job.customerSignatureName ?? '').trim().isNotEmpty ? '${(job.completionNotes ?? '').trim().isNotEmpty ? ' • ' : ''}Signed: ${job.customerSignatureName}' : ''}${job.lastCustomerMessageAt != null ? '${((job.completionNotes ?? '').trim().isNotEmpty || (job.customerSignatureName ?? '').trim().isNotEmpty) ? ' • ' : ''}Customer updated' : ''}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    FilledButton.tonalIcon(
                                      onPressed: () => _showAssignDialog(
                                        context,
                                        ref,
                                        job,
                                        recentTechnicians,
                                      ),
                                      icon: const Icon(Icons.engineering),
                                      label: const Text('Assign'),
                                    ),
                                    FilledButton.tonalIcon(
                                      onPressed: () => _copyCustomerUpdate(
                                        context,
                                        ref,
                                        job,
                                      ),
                                      icon: const Icon(Icons.sms_outlined),
                                      label: const Text('Update'),
                                    ),
                                    if (job.status == JobStatus.scheduled.value)
                                      FilledButton.tonalIcon(
                                        onPressed: () => _markCustomerConfirmed(
                                          context,
                                          ref,
                                          job,
                                        ),
                                        icon: const Icon(
                                          Icons.check_circle_outline,
                                        ),
                                        label: Text(
                                          job.customerConfirmedAt == null
                                              ? 'Mark Confirmed'
                                              : 'Confirmed',
                                        ),
                                      ),
                                    PopupMenuButton<DispatchMessageTemplate>(
                                      tooltip: 'Quick customer templates',
                                      onSelected: (template) =>
                                          _copyTemplateUpdate(
                                            context,
                                            ref,
                                            job,
                                            template,
                                          ),
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                          value:
                                              DispatchMessageTemplate.scheduled,
                                          child: Text('Copy: Scheduled'),
                                        ),
                                        PopupMenuItem(
                                          value:
                                              DispatchMessageTemplate.onTheWay,
                                          child: Text('Copy: On my way'),
                                        ),
                                        PopupMenuItem(
                                          value:
                                              DispatchMessageTemplate.delayed,
                                          child: Text('Copy: Delayed'),
                                        ),
                                        PopupMenuItem(
                                          value:
                                              DispatchMessageTemplate.completed,
                                          child: Text('Copy: Completed'),
                                        ),
                                      ],
                                      child: const Chip(
                                        avatar: Icon(Icons.forum_outlined),
                                        label: Text('Notify'),
                                      ),
                                    ),
                                    FilledButton.tonalIcon(
                                      onPressed: () =>
                                          _exportProofPackage(context, job),
                                      icon: const Icon(
                                        Icons.ios_share_outlined,
                                      ),
                                      label: const Text('Export'),
                                    ),
                                    if (nextStatus != null)
                                      FilledButton.icon(
                                        onPressed: () {
                                          if (nextStatus == JobStatus.done) {
                                            _showCompleteJobDialog(
                                              context,
                                              ref,
                                              job,
                                            );
                                          } else {
                                            ref
                                                .read(jobsProvider.notifier)
                                                .moveStatus(job.id, nextStatus);
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.arrow_circle_right_outlined,
                                        ),
                                        label: Text(
                                          nextStatus == JobStatus.done
                                              ? 'Complete'
                                              : 'Advance',
                                        ),
                                      ),
                                    PopupMenuButton<JobStatus>(
                                      onSelected: (value) => ref
                                          .read(jobsProvider.notifier)
                                          .moveStatus(job.id, value),
                                      itemBuilder: (_) => JobStatus.values
                                          .where((s) => s != status)
                                          .map(
                                            (s) => PopupMenuItem(
                                              value: s,
                                              child: Text('Move to ${s.label}'),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  if (!filtered.any((j) => j.status == status.value))
                    const Card(child: ListTile(title: Text('No jobs'))),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _copyTemplateUpdate(
    BuildContext context,
    WidgetRef ref,
    Job job,
    DispatchMessageTemplate template,
  ) async {
    final message = buildCustomerUpdateTemplateMessage(job, template);
    await Clipboard.setData(ClipboardData(text: message));
    await ref.read(jobsProvider.notifier).markCustomerUpdateSent(job.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Customer template copied to clipboard')),
    );
  }

  Future<void> _markCustomerConfirmed(
    BuildContext context,
    WidgetRef ref,
    Job job,
  ) async {
    if (job.customerConfirmedAt != null) return;
    await ref.read(jobsProvider.notifier).markCustomerConfirmed(job.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Customer confirmation recorded')),
    );
  }

  Future<void> _exportProofPackage(BuildContext context, Job job) async {
    final files = await _exportService.buildExportBundle(job);

    if (files.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No proof files to export yet.')),
      );
      return;
    }

    await SharePlus.instance.share(
      ShareParams(
        text: 'Proof package: ${job.customerName} (${job.id})',
        files: files.map(XFile.new).toList(),
      ),
    );
  }

  Future<void> _copyCustomerUpdate(
    BuildContext context,
    WidgetRef ref,
    Job job,
  ) async {
    final message = buildCustomerUpdateMessage(job);
    await Clipboard.setData(ClipboardData(text: message));

    await ref.read(jobsProvider.notifier).markCustomerUpdateSent(job.id);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Customer update copied to clipboard')),
    );
  }

  Future<void> _showCompleteJobDialog(
    BuildContext context,
    WidgetRef ref,
    Job job,
  ) async {
    final notesCtrl = TextEditingController(text: job.completionNotes ?? '');
    final signatureCtrl = TextEditingController(
      text: job.customerSignatureName ?? '',
    );
    final proofCtrl = TextEditingController(
      text: (job.proofPhotoCount ?? 0).toString(),
    );
    final photoPaths = [...?job.proofPhotoUrls];

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Complete job'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: notesCtrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Completion notes',
                  ),
                ),
                TextField(
                  controller: signatureCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Customer signature name (optional)',
                  ),
                ),
                TextField(
                  controller: proofCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Proof photos count',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Proof photos (local)',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () async {
                        final picked = await _picker.pickImage(
                          source: ImageSource.camera,
                        );
                        if (picked == null) return;

                        final savedPath = await _photoStore.savePhoto(
                          sourcePath: picked.path,
                          customerName: job.customerName,
                          jobId: job.id,
                        );

                        setState(() {
                          photoPaths.add(savedPath);
                          proofCtrl.text = photoPaths.length.toString();
                        });
                      },
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('Camera'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await _picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (picked == null) return;

                        final savedPath = await _photoStore.savePhoto(
                          sourcePath: picked.path,
                          customerName: job.customerName,
                          jobId: job.id,
                        );

                        setState(() {
                          photoPaths.add(savedPath);
                          proofCtrl.text = photoPaths.length.toString();
                        });
                      },
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (photoPaths.isEmpty)
                  const Text('No photos yet')
                else
                  SizedBox(
                    height: 92,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: photoPaths.length,
                      separatorBuilder: (_, index) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final path = photoPaths[i];
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(path),
                                width: 92,
                                height: 92,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 92,
                                      height: 92,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.broken_image_outlined,
                                      ),
                                    ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                visualDensity: VisualDensity.compact,
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    photoPaths.removeAt(i);
                                    proofCtrl.text = photoPaths.length
                                        .toString();
                                  });
                                },
                                icon: const Icon(Icons.close, size: 16),
                              ),
                            ),
                          ],
                        );
                      },
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
                final notes = notesCtrl.text.trim();
                if (notes.isEmpty) return;

                await ref
                    .read(jobsProvider.notifier)
                    .completeJob(
                      jobId: job.id,
                      completionNotes: notes,
                      customerSignatureName: signatureCtrl.text.trim().isEmpty
                          ? null
                          : signatureCtrl.text.trim(),
                      proofPhotoCount:
                          int.tryParse(proofCtrl.text.trim()) ??
                          photoPaths.length,
                      proofPhotoUrls: photoPaths,
                    );

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Complete'),
            ),
          ],
        ),
      ),
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
            TextField(
              controller: techCtrl,
              decoration: const InputDecoration(labelText: 'Technician name'),
            ),
            TextField(
              controller: etaCtrl,
              decoration: const InputDecoration(labelText: 'ETA window'),
            ),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(jobsProvider.notifier)
                  .updateAssignment(
                    jobId: job.id,
                    technicianName: techCtrl.text.trim().isEmpty
                        ? null
                        : techCtrl.text.trim(),
                    etaWindow: etaCtrl.text.trim().isEmpty
                        ? null
                        : etaCtrl.text.trim(),
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
