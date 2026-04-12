import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/job.dart';
import 'jobs_repository.dart';

class SupabaseJobsRepository implements JobsRepository {
  SupabaseJobsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Job>> listJobs() async {
    final rows = await _client
        .from('jobs')
        .select()
        .order('created_at', ascending: false);

    return (rows as List).cast<Map<String, dynamic>>().map(Job.fromMap).toList();
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
    final row = await _client
        .from('jobs')
        .insert({
          'customer_name': customerName,
          'address': address,
          'job_type': jobType,
          'status': 'new',
          'priority': priority,
          'notes': notes,
          'technician_name': technicianName,
          'eta_window': etaWindow,
        })
        .select()
        .single();

    return Job.fromMap(Map<String, dynamic>.from(row as Map));
  }

  @override
  Future<void> updateStatus({required String jobId, required String status}) async {
    await _client.from('jobs').update({'status': status}).eq('id', jobId);
  }

  @override
  Future<void> updateAssignment({
    required String jobId,
    String? technicianName,
    String? etaWindow,
  }) async {
    await _client.from('jobs').update({
      'technician_name': technicianName,
      'eta_window': etaWindow,
    }).eq('id', jobId);
  }
}
