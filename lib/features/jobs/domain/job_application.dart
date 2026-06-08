import '../../../core/constants/job_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JobApplication {
  const JobApplication({
    required this.id,
    required this.userId,
    required this.roleName,
    required this.companyName,
    required this.platform,
    required this.status,
    required this.notes,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String roleName;
  final String companyName;
  final String platform;
  final JobStatus status;
  final String notes;
  final DateTime createdAt;

  factory JobApplication.fromMap(Map<String, dynamic> map) {
    return JobApplication(
      id: map['id'] as String? ?? '',
      userId: map['user_uid'] as String? ?? map['user_id'] as String? ?? '',
      roleName: map['role_name'] as String? ?? '',
      companyName: map['company_name'] as String? ?? '',
      platform: map['platform'] as String? ?? '',
      status: JobStatus.fromLabel(map['status'] as String? ?? ''),
      notes: map['notes'] as String? ?? '',
      createdAt: _parseDateTime(map['created_at']),
    );
  }

  JobApplication copyWith({
    String? id,
    String? userId,
    String? roleName,
    String? companyName,
    String? platform,
    JobStatus? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return JobApplication(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      roleName: roleName ?? this.roleName,
      companyName: companyName ?? this.companyName,
      platform: platform ?? this.platform,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

DateTime _parseDateTime(Object? raw) {
  if (raw == null) return DateTime.now();
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  if (raw is String) {
    return DateTime.tryParse(raw) ?? DateTime.now();
  }
  return DateTime.now();
}
