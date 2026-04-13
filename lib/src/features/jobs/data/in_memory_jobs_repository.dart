import 'package:uuid/uuid.dart';

import '../../../shared/models/job.dart';
import '../domain/job_status.dart';
import 'jobs_repository.dart';

class InMemoryJobsRepository implements JobsRepository {
  static const _uuid = Uuid();
  final List<Job> _jobs = [];

  @override
  Future<List<Job>> listJobs() async {
    return List.unmodifiable(_jobs);
  }

  @override
  Future<Job> createJob({
    required String customerName,
    required String address,
    required String jobType,
    required String priority,
    String? notes,
    String? technicianName,
    String? etaWindow,
  }) async {
    final job = Job(
      id: _uuid.v4(),
      customerName: customerName,
      address: address,
      jobType: jobType,
      status: JobStatus.newJob.value,
      priority: priority,
      notes: notes,
      technicianName: technicianName,
      etaWindow: etaWindow,
    );
    _jobs.add(job);
    return job;
  }

  @override
  Future<void> updateStatus({
    required String jobId,
    required String status,
  }) async {
    final index = _jobs.indexWhere((j) => j.id == jobId);
    if (index == -1) return;
    _jobs[index] = _jobs[index].copyWith(status: status);
  }

  @override
  Future<void> updateAssignment({
    required String jobId,
    String? technicianName,
    String? etaWindow,
  }) async {
    final index = _jobs.indexWhere((j) => j.id == jobId);
    if (index == -1) return;
    _jobs[index] = _jobs[index].copyWith(
      technicianName: technicianName,
      etaWindow: etaWindow,
    );
  }

  @override
  Future<void> updateCompletion({
    required String jobId,
    required String completionNotes,
    String? customerSignatureName,
    int? proofPhotoCount,
    List<String>? proofPhotoUrls,
  }) async {
    final index = _jobs.indexWhere((j) => j.id == jobId);
    if (index == -1) return;
    _jobs[index] = _jobs[index].copyWith(
      status: JobStatus.done.value,
      completionNotes: completionNotes,
      customerSignatureName: customerSignatureName,
      proofPhotoCount: proofPhotoCount,
      proofPhotoUrls: proofPhotoUrls,
    );
  }

  @override
  Future<void> updateCustomerConfirmation({
    required String jobId,
    DateTime? confirmedAt,
  }) async {
    final index = _jobs.indexWhere((j) => j.id == jobId);
    if (index == -1) return;
    _jobs[index] = _jobs[index].copyWith(customerConfirmedAt: confirmedAt);
  }
}
