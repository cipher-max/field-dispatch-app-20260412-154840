import '../../shared/models/job.dart';
import '../jobs/domain/job_priority.dart';

List<Job> filterDispatchJobs({
  required List<Job> jobs,
  required String query,
  JobPriority? priorityFilter,
  bool unassignedOnly = false,
}) {
  final normalized = query.trim().toLowerCase();

  return jobs.where((job) {
    final matchesQuery = normalized.isEmpty ||
        [
          job.customerName,
          job.address,
          job.jobType,
          job.technicianName ?? '',
          job.notes ?? '',
        ].join(' ').toLowerCase().contains(normalized);

    final matchesPriority =
        priorityFilter == null || job.priority == priorityFilter.value;
    final matchesAssignment =
        !unassignedOnly || (job.technicianName == null || job.technicianName!.trim().isEmpty);

    return matchesQuery && matchesPriority && matchesAssignment;
  }).toList();
}

List<String> buildRecentTechnicianNames(
  List<Job> jobs, {
  int limit = 6,
}) {
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
