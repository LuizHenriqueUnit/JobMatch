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
        return const Color(0xFF5A4BC6);
      case JobStatus.triagem:
        return const Color(0xFFB88019);
      case JobStatus.entrevista:
        return const Color(0xFFC47A16);
      case JobStatus.testeTecnico:
        return const Color(0xFF5A4BC6);
      case JobStatus.oferta:
        return const Color(0xFF5E9F34);
      case JobStatus.rejeitado:
        return const Color(0xFFC83A3A);
    }
  }
}
