import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/date_formatters.dart';
import '../domain/app_notification.dart';
import 'providers/notifications_providers.dart';

const _primary = Color(0xFF5949C6);
const _background = Color(0xFFF1EFE8);
const _border = Color(0xFFD9D3C8);
const _text = Color(0xFF25232D);
const _muted = Color(0xFF8A867F);

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Notificacoes'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.chevron_left, size: 28),
        ),
      ),
      bottomNavigationBar: const _JobMatchBottomNav(currentIndex: 1),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Erro ao carregar notificacoes: $error'),
          ),
        ),
        data: (notifications) {
          final unread = notifications.where((item) => !item.isRead).toList();
          if (notifications.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Nenhum alerta ate o momento.'),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 82),
            children: [
              _UnreadSummary(
                count: unread.length,
                onMarkAll: unread.isEmpty
                    ? null
                    : () async {
                        final repository = ref.read(notificationsRepositoryProvider);
                        for (final item in unread) {
                          await repository.markAsRead(item.id);
                        }
                      },
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    for (var index = 0; index < notifications.length; index++) ...[
                      _NotificationTile(item: notifications[index]),
                      if (index != notifications.length - 1)
                        const Divider(indent: 0, endIndent: 0),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _UnreadSummary extends StatelessWidget {
  const _UnreadSummary({
    required this.count,
    required this.onMarkAll,
  });

  final int count;
  final VoidCallback? onMarkAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            '$count nao lidas',
            style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          TextButton(
            onPressed: onMarkAll,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Marcar todas como lidas',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: item.isRead ? const Color(0xFFC9C4BA) : _primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.message,
                  style: TextStyle(
                    color: item.isRead ? _muted : _text,
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
                  ),
                ),
                if (item.createdAt != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    formatDateTime(item.createdAt!),
                    style: const TextStyle(color: _muted, fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _NotificationAction(item: item),
        ],
      ),
    );
  }
}

class _NotificationAction extends ConsumerWidget {
  const _NotificationAction({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = item.isRead ? const Color(0xFFC9C4BA) : _primary;
    return InkWell(
      onTap: item.isRead
          ? null
          : () async {
              await ref.read(notificationsRepositoryProvider).markAsRead(item.id);
            },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          item.isRead ? Icons.notifications_none_rounded : Icons.visibility_outlined,
          color: color,
          size: 17,
        ),
      ),
    );
  }
}

class _JobMatchBottomNav extends StatelessWidget {
  const _JobMatchBottomNav({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          _BottomNavItem(
            icon: Icons.grid_view_rounded,
            label: 'Vagas',
            selected: currentIndex == 0,
            onTap: () => context.go('/home'),
          ),
          _BottomNavItem(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Notas',
            selected: currentIndex == 1,
            onTap: () {},
          ),
          _BottomNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Perfil',
            selected: currentIndex == 2,
            onTap: () => context.push('/profile'),
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _primary : _muted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
