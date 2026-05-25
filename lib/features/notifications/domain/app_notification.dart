class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.message,
    required this.isRead,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      message: map['message'] as String? ?? '',
      isRead: map['is_read'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
    );
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? message,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
