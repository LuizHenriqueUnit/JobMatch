import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/app_notification.dart';

class NotificationsRepository {
  NotificationsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _notificationsCollection =>
      _firestore.collection('notifications');

  Stream<List<AppNotification>> watchNotifications(String userId) {
    final stream = _notificationsCollection
        .where('user_uid', isEqualTo: userId)
        .limit(100)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        return AppNotification.fromMap({
          ...data,
          'id': doc.id,
        });
      }).toList(growable: false);
      items.sort((a, b) {
        final aDate = a.createdAt;
        final bDate = b.createdAt;
        if (aDate != null && bDate != null) {
          return bDate.compareTo(aDate);
        }
        return b.id.compareTo(a.id);
      });
      return items;
    }).timeout(
      const Duration(seconds: 45),
      onTimeout: (sink) => sink.add(const <AppNotification>[]),
    );

    return (() async* {
      yield const <AppNotification>[];
      yield* stream;
    })();
  }

  Future<void> markAsRead(String id) async {
    await _notificationsCollection.doc(id).update({
      'is_read': true,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
