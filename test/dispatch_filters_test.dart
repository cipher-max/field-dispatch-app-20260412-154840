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

  test('filters jobs that need customer update', () {
    final result = filterDispatchJobs(
      jobs: [
        jobs[1],
        jobs[2].copyWith(etaWindow: '3:00-4:00 PM'),
      ],
      query: '',
      needsCustomerUpdateOnly: true,
    );

    expect(result.map((j) => j.id), ['2', '3']);
  });

  test('jobNeedsCustomerUpdate respects recency and completion', () {
    final stale = jobs[1].copyWith(
      lastCustomerMessageAt: DateTime.now().subtract(const Duration(hours: 6)),
    );
    final recent = jobs[1].copyWith(
      lastCustomerMessageAt: DateTime.now().subtract(const Duration(hours: 1)),
    );
    final done = jobs[1].copyWith(status: 'done');

    expect(jobNeedsCustomerUpdate(stale), isTrue);
    expect(jobNeedsCustomerUpdate(recent), isFalse);
    expect(jobNeedsCustomerUpdate(done), isFalse);
  });

  test('filters jobs missing scope notes', () {
    final result = filterDispatchJobs(
      jobs: jobs,
      query: '',
      needsScopeNotesOnly: true,
    );

    expect(result.map((j) => j.id), ['3']);
  });

  test('jobNeedsScopeNotes excludes new and done jobs', () {
    final missingScheduledNotes = jobs[2];
    final missingNewNotes = jobs[0].copyWith(notes: null);
    final missingDoneNotes = jobs[1].copyWith(status: 'done', notes: null);

    expect(jobNeedsScopeNotes(missingScheduledNotes), isTrue);
    expect(jobNeedsScopeNotes(missingNewNotes), isFalse);
    expect(jobNeedsScopeNotes(missingDoneNotes), isFalse);
  });

  test('filters jobs needing customer confirmation', () {
    final withEtaNoConfirmation = jobs[1];
    final withConfirmation = jobs[1].copyWith(
      customerConfirmedAt: DateTime.now(),
    );

    final result = filterDispatchJobs(
      jobs: [withEtaNoConfirmation, withConfirmation],
      query: '',
      needsConfirmationOnly: true,
    );

    expect(result.map((j) => j.id), ['2']);
  });

  test('jobNeedsConfirmation only applies to scheduled with ETA', () {
    expect(jobNeedsConfirmation(jobs[1]), isTrue);
    expect(jobNeedsConfirmation(jobs[2]), isFalse);
    expect(jobNeedsConfirmation(jobs[0]), isFalse);
    expect(
      jobNeedsConfirmation(
        jobs[1].copyWith(customerConfirmedAt: DateTime.now()),
      ),
      isFalse,
    );
  });

  test('filters aging jobs 2+ days old', () {
    final now = DateTime(2026, 4, 13, 15);
    final aging = jobs[1].copyWith(
      createdAt: now.subtract(const Duration(days: 3)),
    );
    final fresh = jobs[2].copyWith(
      createdAt: now.subtract(const Duration(hours: 12)),
    );

    final result = filterDispatchJobs(
      jobs: [aging, fresh],
      query: '',
      needsAgingOnly: true,
    );

    expect(result.map((j) => j.id), ['2']);
  });

  test('jobIsAgingRisk ignores done and missing-created jobs', () {
    final now = DateTime(2026, 4, 13, 15);
    expect(
      jobIsAgingRisk(
        jobs[1].copyWith(createdAt: now.subtract(const Duration(days: 4))),
        now: now,
      ),
      isTrue,
    );
    expect(
      jobIsAgingRisk(
        jobs[1].copyWith(
          status: 'done',
          createdAt: now.subtract(const Duration(days: 4)),
        ),
        now: now,
      ),
      isFalse,
    );
    expect(jobIsAgingRisk(jobs[1], now: now), isFalse);
  });
}
