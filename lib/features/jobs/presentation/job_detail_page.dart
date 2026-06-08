import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/job_status.dart';
import '../../../core/utils/date_formatters.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/job_application.dart';
import 'providers/jobs_providers.dart';

const _primary = Color(0xFF5949C6);
const _background = Color(0xFFF1EFE8);
const _border = Color(0xFFD9D3C8);
const _text = Color(0xFF25232D);
const _muted = Color(0xFF78736C);
const _danger = Color(0xFFC83A3A);

class JobDetailPage extends ConsumerStatefulWidget {
  const JobDetailPage({super.key, required this.jobId});

  final String jobId;

  @override
  ConsumerState<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends ConsumerState<JobDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final _roleController = TextEditingController();
  final _companyController = TextEditingController();
  final _platformController = TextEditingController();
  final _notesController = TextEditingController();

  String? _boundJobId;
  JobStatus _selectedStatus = JobStatus.inscrito;
  bool _updatingStatus = false;
  bool _saving = false;
  bool _deleting = false;

  @override
  void dispose() {
    _roleController.dispose();
    _companyController.dispose();
    _platformController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _bindForm(JobApplication job) {
    if (_boundJobId == job.id) return;
    _boundJobId = job.id;
    _selectedStatus = job.status;
    _roleController.text = job.roleName;
    _companyController.text = job.companyName;
    _platformController.text = job.platform;
    _notesController.text = job.notes;
  }

  Future<void> _updateStatus(JobApplication job, JobStatus status) async {
    if (_selectedStatus == status || _updatingStatus) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() {
      _updatingStatus = true;
      _selectedStatus = status;
    });

    try {
      await ref.read(jobsRepositoryProvider).updateStatus(
            id: job.id,
            userId: user.id,
            userEmail: user.email,
            status: status,
            roleName: _roleController.text,
            companyName: _companyController.text,
          );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar status: $error')),
      );
      setState(() => _selectedStatus = job.status);
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  Future<void> _save(JobApplication job) async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(jobsRepositoryProvider).updateJob(
            id: job.id,
            userId: user.id,
            userEmail: user.email,
            roleName: _roleController.text,
            companyName: _companyController.text,
            platform: _platformController.text,
            notes: _notesController.text,
            status: _selectedStatus,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Candidatura atualizada.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(JobApplication job) async {
    final user = ref.read(currentUserProvider);
    if (user == null || _deleting) return;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Excluir candidatura'),
            content: const Text('Essa acao nao pode ser desfeita. Deseja continuar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _danger),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() => _deleting = true);
    try {
      await ref.read(jobsRepositoryProvider).deleteJob(
            id: job.id,
            userId: user.id,
            userEmail: user.email,
            roleName: _roleController.text,
            companyName: _companyController.text,
          );
      if (!mounted) return;
      context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir: $error')),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(jobDetailsProvider(widget.jobId));

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Detalhe da vaga'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.chevron_left, size: 28),
        ),
      ),
      body: jobAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Erro ao carregar vaga: $error'),
          ),
        ),
        data: (job) {
          if (job == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Vaga nao encontrada.'),
              ),
            );
          }

          _bindForm(job);

          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SummaryCard(job: job),
                    const SizedBox(height: 10),
                    _Panel(
                      title: 'Dados da vaga',
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _roleController,
                            decoration: const InputDecoration(labelText: 'Vaga'),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? 'Informe a vaga'
                                    : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _companyController,
                            decoration: const InputDecoration(labelText: 'Empresa'),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? 'Informe a empresa'
                                    : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _platformController,
                            decoration: const InputDecoration(labelText: 'Plataforma'),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? 'Informe a plataforma'
                                    : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _Panel(
                      title: 'Alterar status',
                      child: Column(
                        children: [
                          for (final status in kFunnelOrder) ...[
                            _StatusRow(
                              status: status,
                              selected: _selectedStatus == status,
                              disabled: _updatingStatus,
                              onTap: () => _updateStatus(job, status),
                            ),
                            if (status != kFunnelOrder.last) const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _Panel(
                      title: 'Anotacoes',
                      child: TextFormField(
                        controller: _notesController,
                        minLines: 4,
                        maxLines: 7,
                        decoration: const InputDecoration(
                          hintText: 'Entrevista marcada para 18/04 as 15h...',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _saving ? null : () => _save(job),
                      child: Text(_saving ? 'Salvando...' : 'Salvar alteracoes'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _deleting ? null : () => _delete(job),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _danger,
                        side: const BorderSide(color: Color(0xFFE89B9B)),
                      ),
                      child: Text(_deleting ? 'Excluindo...' : 'Excluir vaga'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.job});

  final JobApplication job;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEAFF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            job.roleName,
            style: const TextStyle(
              color: Color(0xFF2E267C),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(job.companyName, style: const TextStyle(color: _primary, fontSize: 12)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _SmallTag(job.platform),
              _SmallTag('Criada em ${formatDateTime(job.createdAt)}'),
              _SmallTag(job.status.label),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  const _SmallTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _primary),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _primary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.status,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final JobStatus status;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEDEAFF) : Colors.white,
          border: Border.all(color: selected ? _primary : _border),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? _primary : const Color(0xFFC6C0B8),
              size: 17,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _statusDetailLabel(status),
                style: const TextStyle(color: _text, fontSize: 12),
              ),
            ),
            if (selected) _ActiveBadge(status: status),
          ],
        ),
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({required this.status});

  final JobStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        status == JobStatus.entrevista ? 'Ativo' : status.label,
        style: TextStyle(
          color: status.color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _statusDetailLabel(JobStatus status) {
  switch (status) {
    case JobStatus.testeTecnico:
      return 'Teste tecnico';
    case JobStatus.oferta:
      return 'Oferta recebida';
    case JobStatus.rejeitado:
      return 'Recusado / Encerrado';
    default:
      return status.label;
  }
}
