import '../../shared/models/job.dart';
import 'domain/job_priority.dart';

enum JobQueueFilter { all, open, unassigned, done }

List<Job> filterAndSortJobs({
  required List<Job> jobs,
  required JobQueueFilter queueFilter,
  required String query,
}) {
  final normalized = query.trim().toLowerCase();

  final filtered = jobs.where((job) {
    final matchesQueue = switch (queueFilter) {
      JobQueueFilter.all => true,
      JobQueueFilter.open => job.status != 'done',
      JobQueueFilter.unassigned =>
        (job.technicianName == null || job.technicianName!.trim().isEmpty) &&
            job.status != 'done',
      JobQueueFilter.done => job.status == 'done',
    };

    if (!matchesQueue) return false;
    if (normalized.isEmpty) return true;

    final haystack = [
      job.customerName,
      job.address,
      job.jobType,
      job.technicianName ?? '',
      job.notes ?? '',
    ].join(' ').toLowerCase();

    return haystack.contains(normalized);
  }).toList();

  filtered.sort((a, b) {
    final priorityCompare = JobPriorityX.fromValue(
      b.priority,
    ).rank.compareTo(JobPriorityX.fromValue(a.priority).rank);
    if (priorityCompare != 0) return priorityCompare;

    return a.customerName.toLowerCase().compareTo(b.customerName.toLowerCase());
  });

  return filtered;
}
