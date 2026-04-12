import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_env.dart';
import 'in_memory_jobs_repository.dart';
import 'jobs_repository.dart';
import 'supabase_jobs_repository.dart';

final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  if (AppEnv.hasSupabase) {
    return SupabaseJobsRepository(Supabase.instance.client);
  }
  return InMemoryJobsRepository();
});
