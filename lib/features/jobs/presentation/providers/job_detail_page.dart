import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/job_status.dart';
import '../../../core/utils/date_formatters.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/job_application.dart';
import 'providers/jobs_providers.dart';

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
    setState(() => _saving = true);
    try {
      await ref.read(jobsRepositoryProvider).updateJob(
            id: job.id,
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
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
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
      appBar: AppBar(title: const Text('Detalhe da vaga')),
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Criada em ${formatDateTime(job.createdAt)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _roleController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Vaga'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? 'Informe a vaga' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _companyController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Empresa'),
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? 'Informe a empresa'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _platformController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Plataforma'),
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? 'Informe a plataforma'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _notesController,
                    minLines: 4,
                    maxLines: 8,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(labelText: 'Anotacoes'),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Troca rapida de status (1 clique)',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final status in kFunnelOrder)
                        ChoiceChip(
                          label: Text(status.label),
                          selected: _selectedStatus == status,
                          onSelected: _updatingStatus
                              ? null
                              : (_) => _updateStatus(job, status),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _saving ? null : () => _save(job),
                    child: Text(_saving ? 'Salvando...' : 'Salvar edicao'),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: _deleting ? null : () => _delete(job),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                    ),
                    child: Text(_deleting ? 'Excluindo...' : 'Excluir candidatura'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
