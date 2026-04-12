import 'package:app/src/features/jobs/job_list_filters.dart';
import 'package:app/src/shared/models/job.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final jobs = [
    Job(
      id: '1',
      customerName: 'Apex Fitness',
      address: '100 Main St',
      jobType: 'HVAC Tune-up',
      status: 'new',
      priority: 'urgent',
      technicianName: null,
      notes: 'Call first',
    ),
    Job(
      id: '2',
      customerName: 'Beacon Dental',
      address: '200 Oak Ave',
      jobType: 'Plumbing Repair',
      status: 'done',
      priority: 'low',
      technicianName: 'Chris',
    ),
    Job(
      id: '3',
      customerName: 'Cedar Market',
      address: '300 Pine Rd',
      jobType: 'Electrical Inspection',
      status: 'scheduled',
      priority: 'high',
      technicianName: 'Terry',
    ),
  ];

  test('filters unassigned queue and excludes completed jobs', () {
    final result = filterAndSortJobs(
      jobs: jobs,
      queueFilter: JobQueueFilter.unassigned,
      query: '',
    );

    expect(result.map((j) => j.id), ['1']);
  });

  test('supports search across customer/address/notes', () {
    final result = filterAndSortJobs(
      jobs: jobs,
      queueFilter: JobQueueFilter.all,
      query: 'oak',
    );

    expect(result.map((j) => j.id), ['2']);
  });

  test('sorts by priority descending inside filtered results', () {
    final result = filterAndSortJobs(
      jobs: jobs,
      queueFilter: JobQueueFilter.open,
      query: '',
    );

    expect(result.map((j) => j.id), ['1', '3']);
  });
}
