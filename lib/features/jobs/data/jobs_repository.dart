import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/job_status.dart';
import '../domain/job_application.dart';

class JobsRepository {
  JobsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _jobsCollection =>
      _firestore.collection('jobs');

  CollectionReference<Map<String, dynamic>> get _notificationsCollection =>
      _firestore.collection('notifications');

  Stream<List<JobApplication>> watchJobs(String userId) {
    final stream = _jobsCollection
        .where('user_uid', isEqualTo: userId)
        .limit(200)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
      final jobs = snapshot.docs.map((doc) {
        final data = doc.data();
        return JobApplication.fromMap({
          ...data,
          'id': doc.id,
        });
      }).toList(growable: false);
      jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return jobs;
    }).timeout(
      const Duration(seconds: 45),
      onTimeout: (sink) => sink.add(const <JobApplication>[]),
    );

    return (() async* {
      yield const <JobApplication>[];
      yield* stream;
    })();
  }

  Future<JobApplication?> getById({
    required String id,
    required String userId,
  }) async {
    final doc = await _jobsCollection.doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    if ((data['user_uid'] as String?) != userId) return null;
    return JobApplication.fromMap({
      ...data,
      'id': doc.id,
    });
  }

  Stream<JobApplication?> watchById({
    required String id,
    required String userId,
  }) {
    return _jobsCollection
        .doc(id)
        .snapshots(includeMetadataChanges: true)
        .map((doc) {
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      if ((data['user_uid'] as String?) != userId) return null;
      return JobApplication.fromMap({
        ...data,
        'id': doc.id,
      });
    }).timeout(
      const Duration(seconds: 45),
      onTimeout: (sink) => sink.add(null),
    );
  }

  Future<void> createJob({
    required String userId,
    required String userEmail,
    required String roleName,
    required String companyName,
    required String platform,
    required JobStatus status,
    String notes = '',
  }) async {
    await _jobsCollection
        .add({
      'user_uid': userId,
      'criado_por': userEmail,
      'role_name': roleName.trim(),
      'company_name': companyName.trim(),
      'platform': platform.trim(),
      'status': status.label,
      'notes': notes.trim(),
      'created_at': FieldValue.serverTimestamp(),
    })
        .timeout(const Duration(seconds: 20));

    unawaited(
      _insertNotificationSafe(
        userId: userId,
        userEmail: userEmail,
        message: 'Nova candidatura criada: ${roleName.trim()} em ${companyName.trim()}',
      ),
    );
  }

  Future<void> updateStatus({
    required String id,
    required String userId,
    required String userEmail,
    required JobStatus status,
    required String roleName,
    required String companyName,
  }) async {
    await _jobsCollection.doc(id).update({
      'status': status.label,
      'updated_at': FieldValue.serverTimestamp(),
      'criado_por': userEmail,
      'user_uid': userId,
    }).timeout(const Duration(seconds: 20));

    unawaited(
      _insertNotificationSafe(
        userId: userId,
        userEmail: userEmail,
        message:
            'Status atualizado para "${status.label}": ${roleName.trim()} em ${companyName.trim()}',
      ),
    );
  }

  Future<void> updateJob({
    required String id,
    required String userId,
    required String userEmail,
    required String roleName,
    required String companyName,
    required String platform,
    required String notes,
    required JobStatus status,
  }) async {
    await _jobsCollection.doc(id).update({
      'role_name': roleName.trim(),
      'company_name': companyName.trim(),
      'platform': platform.trim(),
      'notes': notes.trim(),
      'status': status.label,
      'updated_at': FieldValue.serverTimestamp(),
      'criado_por': userEmail,
      'user_uid': userId,
    }).timeout(const Duration(seconds: 20));
  }

  Future<void> deleteJob({
    required String id,
    required String userId,
    required String userEmail,
    required String roleName,
    required String companyName,
  }) async {
    await _jobsCollection.doc(id).delete().timeout(const Duration(seconds: 20));

    unawaited(
      _insertNotificationSafe(
        userId: userId,
        userEmail: userEmail,
        message: 'Candidatura removida: ${roleName.trim()} em ${companyName.trim()}',
      ),
    );
  }

  Future<void> _insertNotification({
    required String userId,
    required String userEmail,
    required String message,
  }) async {
    await _notificationsCollection.add({
      'user_uid': userId,
      'criado_por': userEmail,
      'message': message,
      'is_read': false,
      'created_at': FieldValue.serverTimestamp(),
    }).timeout(const Duration(seconds: 15));
  }

  Future<void> _insertNotificationSafe({
    required String userId,
    required String userEmail,
    required String message,
  }) async {
    try {
      await _insertNotification(
        userId: userId,
        userEmail: userEmail,
        message: message,
      );
    } catch (_) {
      // Notificacao nao pode bloquear fluxo principal de candidatura.
    }
  }
}
