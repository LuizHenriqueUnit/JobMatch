import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/data/auth_repository.dart';
import '../../data/notifications_repository.dart';
import '../../domain/app_notification.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref.watch(inMemoryStoreProvider)),
);

final notificationsStreamProvider =
    StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const <AppNotification>[]);
  return ref.watch(notificationsRepositoryProvider).watchNotifications(user.id);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications =
      ref.watch(notificationsStreamProvider).valueOrNull ?? const <AppNotification>[];
  return notifications.where((item) => !item.isRead).length;
});
