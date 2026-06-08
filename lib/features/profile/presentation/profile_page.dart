import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/job_status.dart';
import '../../auth/data/auth_repository.dart';
import '../../jobs/domain/job_application.dart';
import '../../jobs/presentation/providers/jobs_providers.dart';
import 'providers/profile_providers.dart';

const _primary = Color(0xFF5949C6);
const _background = Color(0xFFF1EFE8);
const _border = Color(0xFFD9D3C8);
const _text = Color(0xFF25232D);
const _muted = Color(0xFF8A867F);
const _danger = Color(0xFFC83A3A);

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(profileStreamProvider);
    final jobs = ref.watch(jobsStreamProvider).valueOrNull ?? const <JobApplication>[];

    final total = jobs.length;
    final emEntrevista = jobs
        .where(
          (job) => job.status == JobStatus.entrevista || job.status == JobStatus.testeTecnico,
        )
        .length;
    final ofertas = jobs.where((job) => job.status == JobStatus.oferta).length;

    final profile = profileAsync.valueOrNull;
    final displayName = profile?.name.trim().isNotEmpty == true
        ? profile!.name
        : (user?.email?.split('@').first ?? 'Usuario');
    final displayEmail = profile?.email.trim().isNotEmpty == true
        ? profile!.email
        : (user?.email ?? '-');

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Perfil'),
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
          icon: const Icon(Icons.chevron_left, size: 28),
        ),
      ),
      bottomNavigationBar: const _JobMatchBottomNav(currentIndex: 2),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 82),
        children: [
          _ProfileHeader(
            displayName: displayName,
            displayEmail: displayEmail,
          ),
          const SizedBox(height: 14),
          _MetricsPanel(
            total: total,
            emEntrevista: emEntrevista,
            ofertas: ofertas,
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: _danger,
              side: const BorderSide(color: Color(0xFFE89B9B)),
              backgroundColor: Colors.white,
            ),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.displayEmail,
  });

  final String displayName;
  final String displayEmail;

  @override
  Widget build(BuildContext context) {
    final initial = displayName.trim().isEmpty
        ? 'U'
        : displayName.trim()[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFD9D3FF), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsPanel extends StatelessWidget {
  const _MetricsPanel({
    required this.total,
    required this.emEntrevista,
    required this.ofertas,
  });

  final int total;
  final int emEntrevista;
  final int ofertas;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Metricas',
            style: TextStyle(
              color: _text,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Total',
                  value: '$total',
                  color: _primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'Entrevistas',
                  value: '$emEntrevista',
                  color: const Color(0xFFC47A16),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'Ofertas',
                  value: '$ofertas',
                  color: const Color(0xFF5E9F34),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F5),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
        ],
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
            onTap: () => context.push('/notifications'),
          ),
          _BottomNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Perfil',
            selected: currentIndex == 2,
            onTap: () {},
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
