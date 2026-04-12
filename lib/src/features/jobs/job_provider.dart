import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/job.dart';
import 'data/jobs_repository_provider.dart';
import 'domain/job_priority.dart';
import 'domain/job_status.dart';

class JobsNotifier extends AsyncNotifier<List<Job>> {
  static const _cacheKey = 'jobs_cache_v1';

  @override
  Future<List<Job>> build() async {
    final cached = await _readCache();
    if (cached.isNotEmpty) return cached;

    final repo = ref.read(jobsRepositoryProvider);
    final remote = await repo.listJobs();
    await _writeCache(remote);
    return remote;
  }

  Future<void> addJob({
    required String customerName,
    required String address,
    required String jobType,
    required JobPriority priority,
    String? notes,
    String? technicianName,
    String? etaWindow,
  }) async {
    final repo = ref.read(jobsRepositoryProvider);
    final current = state.asData?.value ?? [];
    final created = await repo.createJob(
      customerName: customerName,
      address: address,
      jobType: jobType,
      priority: priority.value,
      notes: notes,
      technicianName: technicianName,
      etaWindow: etaWindow,
    );
    final next = [created, ...current];
    state = AsyncData(next);
    await _writeCache(next);
  }

  Future<void> moveStatus(String jobId, JobStatus status) async {
    final repo = ref.read(jobsRepositoryProvider);
    await repo.updateStatus(jobId: jobId, status: status.value);

    final current = state.asData?.value ?? [];
    final next = [
      for (final job in current)
        if (job.id == jobId) job.copyWith(status: status.value) else job,
    ];
    state = AsyncData(next);
    await _writeCache(next);
  }

  Future<void> createFollowUp({
    required Job source,
    required int daysOut,
  }) async {
    final repo = ref.read(jobsRepositoryProvider);
    final followUp = await repo.createJob(
      customerName: source.customerName,
      address: source.address,
      jobType: source.jobType,
      priority: source.priority,
      notes: 'Follow-up from ${source.id} (${daysOut}d)',
      technicianName: source.technicianName,
      etaWindow: 'In $daysOut day(s)',
    );

    final current = state.asData?.value ?? [];
    final next = [followUp, ...current];
    state = AsyncData(next);
    await _writeCache(next);
  }

  Future<void> updateAssignment({
    required String jobId,
    String? technicianName,
    String? etaWindow,
  }) async {
    final repo = ref.read(jobsRepositoryProvider);
    await repo.updateAssignment(
      jobId: jobId,
      technicianName: technicianName,
      etaWindow: etaWindow,
    );

    final current = state.asData?.value ?? [];
    final next = [
      for (final job in current)
        if (job.id == jobId)
          job.copyWith(
            technicianName: technicianName,
            etaWindow: etaWindow,
          )
        else
          job,
    ];
    state = AsyncData(next);
    await _writeCache(next);
  }

  Future<List<Job>> _readCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return decoded.map(Job.fromMap).toList();
  }

  Future<void> _writeCache(List<Job> jobs) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(jobs.map((j) => j.toMap()).toList());
    await prefs.setString(_cacheKey, raw);
  }
}

final jobsProvider = AsyncNotifierProvider<JobsNotifier, List<Job>>(JobsNotifier.new);
