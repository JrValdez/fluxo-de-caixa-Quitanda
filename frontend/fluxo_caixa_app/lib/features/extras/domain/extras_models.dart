// Modelos dos recursos extras (alertas, auditoria, conciliação).

class Alerta {
  final String tipo;
  final String severidade; // Info | Aviso | Critico
  final String titulo;
  final String descricao;
  final DateTime? data;

  Alerta({required this.tipo, required this.severidade, required this.titulo, required this.descricao, this.data});

  factory Alerta.fromJson(Map<String, dynamic> j) => Alerta(
        tipo: j['tipo'] as String,
        severidade: j['severidade'] as String,
        titulo: j['titulo'] as String,
        descricao: j['descricao'] as String,
        data: j['data'] == null ? null : DateTime.parse(j['data'] as String),
      );
}

class AuditLogItem {
  final String entidade;
  final String entidadeId;
  final String acao;
  final String? usuario;
  final String? dadosDepois;
  final DateTime criadoEm;

  AuditLogItem({
    required this.entidade,
    required this.entidadeId,
    required this.acao,
    this.usuario,
    this.dadosDepois,
    required this.criadoEm,
  });

  factory AuditLogItem.fromJson(Map<String, dynamic> j) => AuditLogItem(
        entidade: j['entidade'] as String,
        entidadeId: j['entidadeId'] as String,
        acao: j['acao'] as String,
        usuario: j['usuario'] as String?,
        dadosDepois: j['dadosDepois'] as String?,
        criadoEm: DateTime.parse(j['criadoEm'] as String),
      );
}

class LinhaExtrato {
  final DateTime data;
  final String descricao;
  final double valor;
  final String tipo; // Entrada | Saida
  final String? transacaoCorrespondenteId;
  final String? descricaoCorrespondente;
  bool conciliada;

  LinhaExtrato({
    required this.data,
    required this.descricao,
    required this.valor,
    required this.tipo,
    this.transacaoCorrespondenteId,
    this.descricaoCorrespondente,
    this.conciliada = false,
  });

  bool get isEntrada => tipo == 'Entrada';

  factory LinhaExtrato.fromJson(Map<String, dynamic> j) => LinhaExtrato(
        data: DateTime.parse(j['data'] as String),
        descricao: j['descricao'] as String,
        valor: (j['valor'] as num).toDouble(),
        tipo: j['tipo'] as String,
        transacaoCorrespondenteId: j['transacaoCorrespondenteId'] as String?,
        descricaoCorrespondente: j['descricaoCorrespondente'] as String?,
      );
}
