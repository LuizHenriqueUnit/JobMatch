import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/job_status.dart';
import '../../auth/data/auth_repository.dart';
import '../../jobs/domain/job_application.dart';
import '../../jobs/presentation/providers/jobs_providers.dart';
import 'providers/profile_providers.dart';

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
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(displayEmail),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Metricas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _MetricTile(label: 'Total de candidaturas', value: '$total'),
          const SizedBox(height: 8),
          _MetricTile(label: 'Em etapas de entrevista', value: '$emEntrevista'),
          const SizedBox(height: 8),
          _MetricTile(label: 'Ofertas recebidas', value: '$ofertas'),
          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
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

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD7DEEA)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
