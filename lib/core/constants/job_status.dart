import 'package:flutter/material.dart';

enum JobStatus {
  inscrito('Inscrito'),
  triagem('Triagem'),
  entrevista('Entrevista'),
  testeTecnico('Teste Tecnico'),
  oferta('Oferta'),
  rejeitado('Rejeitado');

  const JobStatus(this.label);
  final String label;

  static JobStatus fromLabel(String raw) {
    final normalized = raw.trim().toLowerCase();
    for (final status in JobStatus.values) {
      if (status.label.toLowerCase() == normalized) {
        return status;
      }
    }
    return JobStatus.inscrito;
  }
}

const kFunnelOrder = <JobStatus>[
  JobStatus.inscrito,
  JobStatus.triagem,
  JobStatus.entrevista,
  JobStatus.testeTecnico,
  JobStatus.oferta,
  JobStatus.rejeitado,
];

extension JobStatusUi on JobStatus {
  Color get color {
    switch (this) {
      case JobStatus.inscrito:
        return const Color(0xFFE8EEF9);
      case JobStatus.triagem:
        return const Color(0xFFFDF3D7);
      case JobStatus.entrevista:
        return const Color(0xFFE4F9ED);
      case JobStatus.testeTecnico:
        return const Color(0xFFEDE8FF);
      case JobStatus.oferta:
        return const Color(0xFFD8F6E5);
      case JobStatus.rejeitado:
        return const Color(0xFFFBE7E7);
    }
  }
}
