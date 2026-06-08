import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/job_status.dart';
import '../../../core/utils/date_formatters.dart';
import '../../auth/data/auth_repository.dart';
import '../../notifications/presentation/providers/notifications_providers.dart';
import '../domain/job_application.dart';
import 'providers/jobs_providers.dart';

const _primary = Color(0xFF5949C6);
const _background = Color(0xFFF1EFE8);
const _border = Color(0xFFD9D3C8);
const _text = Color(0xFF25232D);
const _muted = Color(0xFF8A867F);

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(jobsStreamProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: _background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/jobs/new'),
        child: const Icon(Icons.add, size: 30),
      ),
      bottomNavigationBar: const _JobMatchBottomNav(currentIndex: 0),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _HomeHeader(
              name: user?.name ?? 'Usuario',
              unreadCount: unreadCount,
              onNotificationsTap: () => context.push('/notifications'),
            ),
            Expanded(
              child: jobsAsync.when(
                loading: () => const _EmptyBoard(syncing: true),
                error: (error, stackTrace) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Erro ao carregar vagas: $error'),
                  ),
                ),
                data: (jobs) => _HomeContent(jobs: jobs),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.name,
    required this.unreadCount,
    required this.onNotificationsTap,
  });

  final String name;
  final int unreadCount;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final firstName = name.trim().split(' ').first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
      decoration: const BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'JobMatch',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ola, $firstName - bom dia!',
                  style: const TextStyle(color: Color(0xFFD9D3FF), fontSize: 13),
                ),
              ],
            ),
          ),
          _HeaderIconButton(
            unreadCount: unreadCount,
            onTap: onNotificationsTap,
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.unreadCount,
    required this.onTap,
  });

  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_outlined, color: Colors.white),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3C23B),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.jobs});

  final List<JobApplication> jobs;

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) return const _EmptyBoard();

    final groupedJobs = _groupJobsByStatus(jobs);
    final active = jobs
        .where(
          (job) =>
              job.status == JobStatus.triagem ||
              job.status == JobStatus.entrevista ||
              job.status == JobStatus.testeTecnico,
        )
        .length;
    final finished = jobs
        .where((job) => job.status == JobStatus.oferta || job.status == JobStatus.rejeitado)
        .length;
    final visibleStatuses = kFunnelOrder
        .where((status) => (groupedJobs[status] ?? const <JobApplication>[]).isNotEmpty)
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
      children: [
        Row(
          children: [
            Expanded(child: _MetricCard(value: '${jobs.length}', label: 'Enviados')),
            const SizedBox(width: 10),
            Expanded(child: _MetricCard(value: '$active', label: 'Em andamento')),
            const SizedBox(width: 10),
            Expanded(child: _MetricCard(value: '$finished', label: 'Finalizados')),
          ],
        ),
        const SizedBox(height: 16),
        for (final status in visibleStatuses) ...[
          _StatusSection(
            status: status,
            jobs: groupedJobs[status] ?? const <JobApplication>[],
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: _primary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _EmptyBoard extends StatelessWidget {
  const _EmptyBoard({this.syncing = false});

  final bool syncing;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          syncing
              ? 'Sincronizando candidaturas...\nSe estiver sem dados, use o + para criar a primeira vaga.'
              : 'Nenhuma candidatura ainda.\nToque no + para adicionar a primeira vaga.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted),
        ),
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({
    required this.status,
    required this.jobs,
  });

  final JobStatus status;
  final List<JobApplication> jobs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: status.color,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _sectionTitle(status),
              style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text('${jobs.length}', style: const TextStyle(color: _muted, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        for (final job in jobs) ...[
          _JobTile(job: job),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _JobTile extends StatelessWidget {
  const _JobTile({required this.job});

  final JobApplication job;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: () => context.push('/jobs/${job.id}'),
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: _border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.roleName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      job.companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF56515B), fontSize: 13),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${job.platform} - ${formatDateTime(job.createdAt)}',
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(status: job.status),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final JobStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _pillTitle(status),
        style: TextStyle(
          color: status.color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
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
            onTap: () {},
          ),
          _BottomNavItem(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Notas',
            selected: currentIndex == 1,
            onTap: () => context.push('/notifications'),
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

String _sectionTitle(JobStatus status) {
  switch (status) {
    case JobStatus.oferta:
      return 'Oferta recebida';
    default:
      return status.label;
  }
}

String _pillTitle(JobStatus status) {
  switch (status) {
    case JobStatus.entrevista:
      return 'Entrevista';
    case JobStatus.oferta:
      return 'Oferta';
    case JobStatus.rejeitado:
      return 'Recusado';
    default:
      return status.label;
  }
}

Map<JobStatus, List<JobApplication>> _groupJobsByStatus(List<JobApplication> jobs) {
  final grouped = <JobStatus, List<JobApplication>>{
    for (final status in kFunnelOrder) status: <JobApplication>[],
  };
  for (final job in jobs) {
    grouped.putIfAbsent(job.status, () => <JobApplication>[]).add(job);
  }
  return grouped;
}
