import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_formatters.dart';
import '../domain/app_notification.dart';
import 'providers/notifications_providers.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notificacoes')),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Erro ao carregar notificacoes: $error'),
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Nenhum alerta ate o momento.'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = notifications[index];
              return _NotificationTile(item: item);
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.isRead ? Colors.white : const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD7DEEA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.isRead ? Icons.mark_email_read_outlined : Icons.notifications_active_outlined,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.message),
                if (item.createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    formatDateTime(item.createdAt!),
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!item.isRead)
            TextButton(
              onPressed: () async {
                await ref.read(notificationsRepositoryProvider).markAsRead(item.id);
              },
              child: const Text('Marcar como lido'),
            ),
        ],
      ),
    );
  }
}
