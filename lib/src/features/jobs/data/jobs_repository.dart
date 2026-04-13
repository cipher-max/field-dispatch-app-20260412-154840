import '../../../shared/models/job.dart';

abstract class JobsRepository {
  Future<List<Job>> listJobs();

  Future<Job> createJob({
    required String customerName,
    required String address,
    required String jobType,
    required String priority,
    String? notes,
    String? technicianName,
    String? etaWindow,
  });

  Future<void> updateStatus({required String jobId, required String status});

  Future<void> updateAssignment({
    required String jobId,
    String? technicianName,
    String? etaWindow,
  });

  Future<void> updateCompletion({
    required String jobId,
    required String completionNotes,
    String? customerSignatureName,
    int? proofPhotoCount,
    List<String>? proofPhotoUrls,
  });
}
