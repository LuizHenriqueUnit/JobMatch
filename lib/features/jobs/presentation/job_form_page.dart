import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/job_status.dart';
import '../../auth/data/auth_repository.dart';
import 'providers/jobs_providers.dart';

const _primary = Color(0xFF5949C6);
const _background = Color(0xFFF1EFE8);
const _border = Color(0xFFD9D3C8);
const _text = Color(0xFF25232D);
const _muted = Color(0xFF78736C);

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
            userEmail: user.email,
            roleName: _roleController.text,
            companyName: _companyController.text,
            platform: _platformController.text,
            status: _selectedStatus,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Candidatura salva. Sincronizando mural...')),
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;
      final message = error is TimeoutException
          ? 'Tempo de rede excedido. Verifique sua conexao e tente novamente.'
          : 'Nao foi possivel salvar a vaga: $error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Nova candidatura'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.chevron_left, size: 28),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Panel(
                  title: 'Dados da vaga',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Nome da vaga'),
                      TextFormField(
                        controller: _roleController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(hintText: 'UX Designer Pleno'),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? 'Informe a vaga' : null,
                      ),
                      const SizedBox(height: 12),
                      _FieldLabel('Empresa'),
                      TextFormField(
                        controller: _companyController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(hintText: 'ex: Nubank'),
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? 'Informe a empresa'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _FieldLabel('Plataforma'),
                      DropdownButtonFormField<String>(
                        value: _platformController.text.isEmpty
                            ? null
                            : _platformController.text,
                        decoration: const InputDecoration(hintText: 'Selecionar plataforma...'),
                        items: const [
                          DropdownMenuItem(value: 'LinkedIn', child: Text('LinkedIn')),
                          DropdownMenuItem(value: 'Gupy', child: Text('Gupy')),
                          DropdownMenuItem(value: 'Indeed', child: Text('Indeed')),
                          DropdownMenuItem(value: 'InfoJobs', child: Text('InfoJobs')),
                          DropdownMenuItem(value: 'Outro', child: Text('Outro')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          _platformController.text = value;
                        },
                        validator: (_) => _platformController.text.trim().isEmpty
                            ? 'Informe a plataforma'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _Panel(
                  title: 'Status inicial',
                  child: Column(
                    children: [
                      for (final status in kFunnelOrder) ...[
                        _StatusOption(
                          status: status,
                          selected: _selectedStatus == status,
                          onTap: () => setState(() => _selectedStatus = status),
                        ),
                        if (status != kFunnelOrder.last) const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: _muted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final JobStatus status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEDEAFF) : Colors.white,
          border: Border.all(color: selected ? _primary : _border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? _primary : const Color(0xFFC6C0B8),
              size: 18,
            ),
            const SizedBox(width: 9),
            Text(
              _statusFormLabel(status),
              style: TextStyle(
                color: selected ? _primary : _text,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _statusFormLabel(JobStatus status) {
  switch (status) {
    case JobStatus.triagem:
      return 'Aguardando retorno';
    case JobStatus.entrevista:
      return 'Entrevista marcada';
    case JobStatus.testeTecnico:
      return 'Teste tecnico';
    case JobStatus.oferta:
      return 'Oferta recebida';
    case JobStatus.rejeitado:
      return 'Recusado / Encerrado';
    case JobStatus.inscrito:
      return 'Inscrito';
  }
}
