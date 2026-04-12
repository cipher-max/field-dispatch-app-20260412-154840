import 'package:app/src/features/dispatch/dispatch_filters.dart';
import 'package:app/src/features/jobs/domain/job_priority.dart';
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
      status: 'scheduled',
      priority: 'low',
      technicianName: 'Chris',
      notes: 'Back door',
    ),
  ];

  test('filters unassigned-only queue', () {
    final result = filterDispatchJobs(
      jobs: jobs,
      query: '',
      unassignedOnly: true,
    );

    expect(result.map((j) => j.id), ['1']);
  });

  test('search includes notes and technician name', () {
    final byNotes = filterDispatchJobs(jobs: jobs, query: 'back door');
    final byTech = filterDispatchJobs(jobs: jobs, query: 'chris');

    expect(byNotes.map((j) => j.id), ['2']);
    expect(byTech.map((j) => j.id), ['2']);
  });

  test('applies priority filter', () {
    final result = filterDispatchJobs(
      jobs: jobs,
      query: '',
      priorityFilter: JobPriority.urgent,
    );

    expect(result.map((j) => j.id), ['1']);
  });

  test('builds recent technician names without duplicates', () {
    final result = buildRecentTechnicianNames([
      ...jobs,
      Job(
        id: '3',
        customerName: 'Cobalt Dental',
        address: '300 Pine Rd',
        jobType: 'Panel Upgrade',
        status: 'in_progress',
        priority: 'high',
        technicianName: '  chris  ',
      ),
      Job(
        id: '4',
        customerName: 'Delta Vet',
        address: '400 Elm St',
        jobType: 'Maintenance',
        status: 'new',
        priority: 'medium',
        technicianName: 'Maya',
      ),
    ]);

    expect(result, ['Chris', 'Maya']);
  });
}
