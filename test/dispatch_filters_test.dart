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
      etaWindow: '2:00-3:00 PM',
      notes: 'Back door',
    ),
    Job(
      id: '3',
      customerName: 'Cobalt Dental',
      address: '300 Pine Rd',
      jobType: 'Panel Upgrade',
      status: 'scheduled',
      priority: 'high',
      technicianName: 'Maya',
      etaWindow: null,
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

  test('filters by technician name (case-insensitive)', () {
    final result = filterDispatchJobs(
      jobs: jobs,
      query: '',
      technicianFilter: 'chris',
    );

    expect(result.map((j) => j.id), ['2']);
  });

  test('filters jobs that need ETA', () {
    final result = filterDispatchJobs(
      jobs: jobs,
      query: '',
      needsEtaOnly: true,
    );

    expect(result.map((j) => j.id), ['3']);
  });

  test('jobNeedsEta ignores done jobs and jobs with ETA', () {
    expect(jobNeedsEta(jobs[1]), isFalse);
    expect(jobNeedsEta(jobs[2]), isTrue);

    final doneMissingEta = Job(
      id: '4',
      customerName: 'Delta Vet',
      address: '400 Elm St',
      jobType: 'Maintenance',
      status: 'done',
      priority: 'medium',
      technicianName: 'Pat',
      etaWindow: null,
    );

    expect(jobNeedsEta(doneMissingEta), isFalse);
  });

  test('filters jobs needing dispatch action', () {
    final result = filterDispatchJobs(
      jobs: jobs,
      query: '',
      needsActionOnly: true,
    );

    expect(result.map((j) => j.id), ['1', '3']);
  });

  test(
    'jobNeedsDispatchAction covers unassigned and missing ETA only for open jobs',
    () {
      expect(jobNeedsDispatchAction(jobs[0]), isTrue);
      expect(jobNeedsDispatchAction(jobs[1]), isFalse);
      expect(jobNeedsDispatchAction(jobs[2]), isTrue);

      final doneUnassigned = Job(
        id: '6',
        customerName: 'Gamma Clinic',
        address: '700 Cedar St',
        jobType: 'Inspection',
        status: 'done',
        priority: 'low',
        technicianName: null,
        etaWindow: null,
      );

      expect(jobNeedsDispatchAction(doneUnassigned), isFalse);
    },
  );

  test('builds recent technician names without duplicates', () {
    final result = buildRecentTechnicianNames([
      ...jobs,
      Job(
        id: '4',
        customerName: 'Echo Dental',
        address: '500 Pine Rd',
        jobType: 'Panel Upgrade',
        status: 'in_progress',
        priority: 'high',
        technicianName: '  chris  ',
      ),
      Job(
        id: '5',
        customerName: 'Foxtrot Vet',
        address: '600 Elm St',
        jobType: 'Maintenance',
        status: 'new',
        priority: 'medium',
        technicianName: 'Nina',
      ),
    ]);

    expect(result, ['Chris', 'Maya', 'Nina']);
  });
}
