import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/job.dart';
import 'data/jobs_repository_provider.dart';
import 'domain/job_priority.dart';
import 'domain/job_status.dart';

class JobsSyncInProgressNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

class JobsLastSyncAtNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void set(DateTime? value) => state = value;
}

class JobsSyncErrorNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}

class JobsPendingActionsCountNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int value) => state = value;
}

class JobsPendingActionJobIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void set(Set<String> value) => state = value;
}

final jobsSyncInProgressProvider =
    NotifierProvider<JobsSyncInProgressNotifier, bool>(
      JobsSyncInProgressNotifier.new,
    );
final jobsLastSyncAtProvider =
    NotifierProvider<JobsLastSyncAtNotifier, DateTime?>(
      JobsLastSyncAtNotifier.new,
    );
final jobsSyncErrorProvider = NotifierProvider<JobsSyncErrorNotifier, String?>(
  JobsSyncErrorNotifier.new,
);
final jobsPendingActionsCountProvider =
    NotifierProvider<JobsPendingActionsCountNotifier, int>(
      JobsPendingActionsCountNotifier.new,
    );
final jobsPendingActionJobIdsProvider =
    NotifierProvider<JobsPendingActionJobIdsNotifier, Set<String>>(
      JobsPendingActionJobIdsNotifier.new,
    );

class JobsNotifier extends AsyncNotifier<List<Job>> {
  static const _cacheKey = 'jobs_cache_v1';
  static const _cacheUpdatedAtKey = 'jobs_cache_updated_at_v1';
  static const _pendingActionsKey = 'jobs_pending_actions_v1';

  @override
  Future<List<Job>> build() async {
    await _syncPendingCount();

    final cached = await _readCache();
    final lastCachedAt = await _readCacheUpdatedAt();
    if (lastCachedAt != null) {
      ref.read(jobsLastSyncAtProvider.notifier).state = lastCachedAt;
    }

    if (cached.isNotEmpty) return cached;

    return _refreshInternal();
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

    try {
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
      _setSyncError(null);
    } catch (e) {
      _setSyncError('Could not create job. Check connection and retry.');
      rethrow;
    }
  }

  Future<void> moveStatus(String jobId, JobStatus status) async {
    final repo = ref.read(jobsRepositoryProvider);

    final current = state.asData?.value ?? [];
    final next = [
      for (final job in current)
        if (job.id == jobId) job.copyWith(status: status.value) else job,
    ];
    state = AsyncData(next);
    await _writeCache(next);

    try {
      await repo.updateStatus(jobId: jobId, status: status.value);
      _setSyncError(null);
    } catch (_) {
      await _enqueuePendingAction({
        'type': 'updateStatus',
        'jobId': jobId,
        'status': status.value,
      });
      _setSyncError('Saved locally. Pending sync actions need retry.');
    }
  }

  Future<void> completeJob({
    required String jobId,
    required String completionNotes,
    String? customerSignatureName,
    int? proofPhotoCount,
    List<String>? proofPhotoUrls,
  }) async {
    final repo = ref.read(jobsRepositoryProvider);

    final current = state.asData?.value ?? [];
    final next = [
      for (final job in current)
        if (job.id == jobId)
          job.copyWith(
            status: JobStatus.done.value,
            completionNotes: completionNotes,
            customerSignatureName: customerSignatureName,
            proofPhotoCount: proofPhotoCount,
            proofPhotoUrls: proofPhotoUrls,
          )
        else
          job,
    ];
    state = AsyncData(next);
    await _writeCache(next);

    try {
      await repo.updateCompletion(
        jobId: jobId,
        completionNotes: completionNotes,
        customerSignatureName: customerSignatureName,
        proofPhotoCount: proofPhotoCount,
        proofPhotoUrls: proofPhotoUrls,
      );
      _setSyncError(null);
    } catch (_) {
      await _enqueuePendingAction({
        'type': 'updateCompletion',
        'jobId': jobId,
        'completionNotes': completionNotes,
        'customerSignatureName': customerSignatureName,
        'proofPhotoCount': proofPhotoCount,
        'proofPhotoUrls': proofPhotoUrls,
      });
      _setSyncError('Saved locally. Pending sync actions need retry.');
    }
  }

  Future<void> markCustomerUpdateSent(String jobId) async {
    final current = state.asData?.value ?? [];
    final now = DateTime.now();
    final next = [
      for (final job in current)
        if (job.id == jobId) job.copyWith(lastCustomerMessageAt: now) else job,
    ];
    state = AsyncData(next);
    await _writeCache(next);
  }

  Future<void> markCustomerConfirmed(String jobId) async {
    final repo = ref.read(jobsRepositoryProvider);
    final now = DateTime.now();
    final current = state.asData?.value ?? [];
    final next = [
      for (final job in current)
        if (job.id == jobId) job.copyWith(customerConfirmedAt: now) else job,
    ];
    state = AsyncData(next);
    await _writeCache(next);

    try {
      await repo.updateCustomerConfirmation(jobId: jobId, confirmedAt: now);
      _setSyncError(null);
    } catch (_) {
      await _enqueuePendingAction({
        'type': 'updateCustomerConfirmation',
        'jobId': jobId,
        'confirmedAt': now.toIso8601String(),
      });
      _setSyncError('Saved locally. Pending sync actions need retry.');
    }
  }

  Future<void> createFollowUp({
    required Job source,
    required int daysOut,
  }) async {
    final repo = ref.read(jobsRepositoryProvider);

    try {
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
      _setSyncError(null);
    } catch (_) {
      _setSyncError('Could not create follow-up job. Try again.');
      rethrow;
    }
  }

  Future<void> updateAssignment({
    required String jobId,
    String? technicianName,
    String? etaWindow,
  }) async {
    final repo = ref.read(jobsRepositoryProvider);

    final current = state.asData?.value ?? [];
    final next = [
      for (final job in current)
        if (job.id == jobId)
          job.copyWith(technicianName: technicianName, etaWindow: etaWindow)
        else
          job,
    ];
    state = AsyncData(next);
    await _writeCache(next);

    try {
      await repo.updateAssignment(
        jobId: jobId,
        technicianName: technicianName,
        etaWindow: etaWindow,
      );
      _setSyncError(null);
    } catch (_) {
      await _enqueuePendingAction({
        'type': 'updateAssignment',
        'jobId': jobId,
        'technicianName': technicianName,
        'etaWindow': etaWindow,
      });
      _setSyncError('Saved locally. Pending sync actions need retry.');
    }
  }

  Future<void> refreshFromRemote() async {
    await _refreshInternal();
  }

  Future<void> retryPendingActions() async {
    final repo = ref.read(jobsRepositoryProvider);
    final pending = await _readPendingActions();

    if (pending.isEmpty) return;

    final stillPending = <Map<String, dynamic>>[];

    for (final action in pending) {
      final type = (action['type'] ?? '').toString();
      try {
        if (type == 'updateStatus') {
          await repo.updateStatus(
            jobId: action['jobId'].toString(),
            status: action['status'].toString(),
          );
        } else if (type == 'updateAssignment') {
          await repo.updateAssignment(
            jobId: action['jobId'].toString(),
            technicianName: action['technicianName']?.toString(),
            etaWindow: action['etaWindow']?.toString(),
          );
        } else if (type == 'updateCompletion') {
          await repo.updateCompletion(
            jobId: action['jobId'].toString(),
            completionNotes: action['completionNotes'].toString(),
            customerSignatureName: action['customerSignatureName']?.toString(),
            proofPhotoCount: action['proofPhotoCount'] is num
                ? (action['proofPhotoCount'] as num).toInt()
                : int.tryParse((action['proofPhotoCount'] ?? '').toString()),
            proofPhotoUrls: (action['proofPhotoUrls'] as List?)
                ?.map((e) => e.toString())
                .toList(),
          );
        } else if (type == 'updateCustomerConfirmation') {
          await repo.updateCustomerConfirmation(
            jobId: action['jobId'].toString(),
            confirmedAt: DateTime.tryParse(
              (action['confirmedAt'] ?? '').toString(),
            ),
          );
        }
      } catch (_) {
        stillPending.add(action);
      }
    }

    await _writePendingActions(stillPending);
    await _syncPendingCount();

    if (stillPending.isEmpty) {
      _setSyncError(null);
      await _refreshInternal();
    } else {
      _setSyncError('Some pending actions still failed.');
    }
  }

  Future<List<Job>> _refreshInternal() async {
    final repo = ref.read(jobsRepositoryProvider);
    ref.read(jobsSyncInProgressProvider.notifier).state = true;

    try {
      final remote = await repo.listJobs();
      state = AsyncData(remote);
      await _writeCache(remote);
      ref.read(jobsLastSyncAtProvider.notifier).state = DateTime.now();
      _setSyncError(null);
      return remote;
    } catch (_) {
      _setSyncError('Refresh failed. Showing cached data.');
      return state.asData?.value ?? [];
    } finally {
      ref.read(jobsSyncInProgressProvider.notifier).state = false;
    }
  }

  void _setSyncError(String? value) {
    ref.read(jobsSyncErrorProvider.notifier).state = value;
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
    await prefs.setString(_cacheUpdatedAtKey, DateTime.now().toIso8601String());
    ref.read(jobsLastSyncAtProvider.notifier).state = DateTime.now();
  }

  Future<DateTime?> _readCacheUpdatedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheUpdatedAtKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> _enqueuePendingAction(Map<String, dynamic> action) async {
    final pending = await _readPendingActions();
    pending.add(action);
    await _writePendingActions(pending);
    await _syncPendingCount();
  }

  Future<List<Map<String, dynamic>>> _readPendingActions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingActionsKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return decoded;
  }

  Future<void> _writePendingActions(List<Map<String, dynamic>> actions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingActionsKey, jsonEncode(actions));
  }

  Future<void> _syncPendingCount() async {
    final pending = await _readPendingActions();
    ref.read(jobsPendingActionsCountProvider.notifier).state = pending.length;
    final pendingJobIds = pending
        .map((a) => (a['jobId'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();
    ref.read(jobsPendingActionJobIdsProvider.notifier).state = pendingJobIds;
  }
}

final jobsProvider = AsyncNotifierProvider<JobsNotifier, List<Job>>(
  JobsNotifier.new,
);
