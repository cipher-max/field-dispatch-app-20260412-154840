import '../../shared/models/job.dart';
import '../jobs/domain/job_priority.dart';

List<Job> filterDispatchJobs({
  required List<Job> jobs,
  required String query,
  JobPriority? priorityFilter,
  String? technicianFilter,
  bool unassignedOnly = false,
  bool needsEtaOnly = false,
  bool needsActionOnly = false,
  bool needsCustomerUpdateOnly = false,
  bool needsScopeNotesOnly = false,
  bool needsConfirmationOnly = false,
  bool needsAgingOnly = false,
}) {
  final normalized = query.trim().toLowerCase();

  return jobs.where((job) {
    final matchesQuery =
        normalized.isEmpty ||
        [
          job.customerName,
          job.address,
          job.jobType,
          job.technicianName ?? '',
          job.notes ?? '',
        ].join(' ').toLowerCase().contains(normalized);

    final matchesPriority =
        priorityFilter == null || job.priority == priorityFilter.value;
    final matchesTechnician =
        technicianFilter == null ||
        (job.technicianName ?? '').trim().toLowerCase() ==
            technicianFilter.trim().toLowerCase();
    final matchesAssignment =
        !unassignedOnly ||
        (job.technicianName == null || job.technicianName!.trim().isEmpty);
    final matchesEta = !needsEtaOnly || jobNeedsEta(job);
    final matchesNeedsAction = !needsActionOnly || jobNeedsDispatchAction(job);
    final matchesNeedsCustomerUpdate =
        !needsCustomerUpdateOnly || jobNeedsCustomerUpdate(job);
    final matchesNeedsScopeNotes =
        !needsScopeNotesOnly || jobNeedsScopeNotes(job);
    final matchesNeedsConfirmation =
        !needsConfirmationOnly || jobNeedsConfirmation(job);
    final matchesAging = !needsAgingOnly || jobIsAgingRisk(job);

    return matchesQuery &&
        matchesPriority &&
        matchesTechnician &&
        matchesAssignment &&
        matchesEta &&
        matchesNeedsAction &&
        matchesNeedsCustomerUpdate &&
        matchesNeedsScopeNotes &&
        matchesNeedsConfirmation &&
        matchesAging;
  }).toList();
}

bool jobNeedsScopeNotes(Job job) {
  if (job.status == 'done' || job.status == 'new') return false;
  return (job.notes ?? '').trim().isEmpty;
}

bool jobNeedsConfirmation(Job job) {
  if (job.status != 'scheduled') return false;
  if ((job.etaWindow ?? '').trim().isEmpty) return false;
  return job.customerConfirmedAt == null;
}

bool jobIsAgingRisk(Job job, {DateTime? now}) {
  if (job.status == 'done') return false;
  final created = job.createdAt;
  if (created == null) return false;
  final effectiveNow = now ?? DateTime.now();
  return effectiveNow.difference(created).inDays >= 2;
}

bool jobNeedsCustomerUpdate(Job job) {
  final isDone = job.status == 'done';
  if (isDone) return false;

  final hasEta = (job.etaWindow ?? '').trim().isNotEmpty;
  if (!hasEta) return false;

  final lastUpdate = job.lastCustomerMessageAt;
  if (lastUpdate == null) return true;

  return DateTime.now().difference(lastUpdate).inHours >= 4;
}

bool jobNeedsDispatchAction(Job job) {
  final isDone = job.status == 'done';
  if (isDone) return false;

  final isUnassigned = (job.technicianName ?? '').trim().isEmpty;
  return isUnassigned || jobNeedsEta(job);
}

bool jobNeedsEta(Job job) {
  final hasTechnician = (job.technicianName ?? '').trim().isNotEmpty;
  final hasEta = (job.etaWindow ?? '').trim().isNotEmpty;
  final isDone = job.status == 'done';

  return hasTechnician && !hasEta && !isDone;
}

List<String> buildRecentTechnicianNames(List<Job> jobs, {int limit = 6}) {
  final seen = <String>{};
  final names = <String>[];

  for (final job in jobs) {
    final name = (job.technicianName ?? '').trim();
    if (name.isEmpty) continue;
    final key = name.toLowerCase();
    if (seen.add(key)) {
      names.add(name);
      if (names.length == limit) break;
    }
  }

  return names;
}
