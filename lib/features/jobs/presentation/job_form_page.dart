import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/job_status.dart';
import '../../auth/data/auth_repository.dart';
import 'providers/jobs_providers.dart';

class JobFormPage extends ConsumerStatefulWidget {
  const JobFormPage({super.key});

  @override
  ConsumerState<JobFormPage> createState() => _JobFormPageState();
}

class _JobFormPageState extends ConsumerState<JobFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _roleController = TextEditingController();
  final _companyController = TextEditingController();
  final _platformController = TextEditingController();

  JobStatus _selectedStatus = JobStatus.inscrito;
  bool _saving = false;

  @override
  void dispose() {
    _roleController.dispose();
    _companyController.dispose();
    _platformController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(jobsRepositoryProvider).createJob(
            userId: user.id,
            roleName: _roleController.text,
            companyName: _companyController.text,
            platform: _platformController.text,
            status: _selectedStatus,
          );
      if (!mounted) return;
      context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nao foi possivel salvar a vaga: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova candidatura')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Plataforma'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Informe a plataforma'
                    : null,
              ),
              const SizedBox(height: 14),
              const Text(
                'Status inicial',
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
                      onSelected: (_) => setState(() => _selectedStatus = status),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => context.pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Salvando...' : 'Salvar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
