import '../../../shared/data/in_memory_store.dart';
import '../domain/app_notification.dart';

class NotificationsRepository {
  NotificationsRepository(this._store);

  final InMemoryStore _store;

  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _store.watchNotifications(userId);
  }

  Future<void> markAsRead(String id) async {
    await _store.markNotificationAsRead(id);
  }
}
