import '../../../core/constants/job_status.dart';
import '../../../shared/data/in_memory_store.dart';
import '../domain/job_application.dart';

class JobsRepository {
  JobsRepository(this._store);

  final InMemoryStore _store;

  Stream<List<JobApplication>> watchJobs(String userId) {
    return _store.watchJobs(userId);
  }

  Future<JobApplication?> getById({
    required String id,
    required String userId,
  }) async {
    return _store.getJobById(id: id, userId: userId);
  }

  Future<void> createJob({
    required String userId,
    required String roleName,
    required String companyName,
    required String platform,
    required JobStatus status,
    String notes = '',
  }) async {
    await _store.createJob(
      userId: userId,
      roleName: roleName,
      companyName: companyName,
      platform: platform,
      statusLabel: status.label,
      notes: notes,
    );
  }

  Future<void> updateStatus({
    required String id,
    required String userId,
    required JobStatus status,
    required String roleName,
    required String companyName,
  }) async {
    await _store.updateJobStatus(
      id: id,
      userId: userId,
      statusLabel: status.label,
      roleName: roleName,
      companyName: companyName,
    );
  }

  Future<void> updateJob({
    required String id,
    required String roleName,
    required String companyName,
    required String platform,
    required String notes,
    required JobStatus status,
  }) async {
    await _store.updateJob(
      id: id,
      roleName: roleName,
      companyName: companyName,
      platform: platform,
      notes: notes,
      statusLabel: status.label,
    );
  }

  Future<void> deleteJob({
    required String id,
    required String userId,
    required String roleName,
    required String companyName,
  }) async {
    await _store.deleteJob(
      id: id,
      userId: userId,
      roleName: roleName,
      companyName: companyName,
    );
  }
}
