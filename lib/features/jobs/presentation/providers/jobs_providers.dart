import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/job_status.dart';
import '../../../../features/auth/data/auth_repository.dart';
import '../../data/jobs_repository.dart';
import '../../domain/job_application.dart';

final jobsRepositoryProvider = Provider<JobsRepository>(
  (ref) => JobsRepository(ref.watch(inMemoryStoreProvider)),
);

final jobsStreamProvider = StreamProvider.autoDispose<List<JobApplication>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const <JobApplication>[]);
  return ref.watch(jobsRepositoryProvider).watchJobs(user.id);
});

final groupedJobsProvider = Provider<Map<JobStatus, List<JobApplication>>>((ref) {
  final jobs = ref.watch(jobsStreamProvider).valueOrNull ?? const <JobApplication>[];
  final grouped = <JobStatus, List<JobApplication>>{
    for (final status in kFunnelOrder) status: <JobApplication>[],
  };
  for (final job in jobs) {
    grouped.putIfAbsent(job.status, () => <JobApplication>[]).add(job);
  }
  return grouped;
});

final jobDetailsProvider =
    FutureProvider.autoDispose.family<JobApplication?, String>((ref, jobId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(jobsRepositoryProvider).getById(id: jobId, userId: user.id);
});
