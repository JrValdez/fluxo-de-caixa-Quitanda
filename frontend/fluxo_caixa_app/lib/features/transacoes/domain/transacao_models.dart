// Modelos de transações, resumo e recorrências (espelham o backend).

const tipoMovimentoLabels = {'Entrada': 'Entrada', 'Saida': 'Saída'};

const statusTransacaoLabels = {
  'Previsto': 'Previsto',
  'Realizado': 'Realizado',
  'Atrasado': 'Atrasado',
  'Cancelado': 'Cancelado',
};

const frequenciaLabels = {
  'Diaria': 'Diária',
  'Semanal': 'Semanal',
  'Quinzenal': 'Quinzenal',
  'Mensal': 'Mensal',
  'Bimestral': 'Bimestral',
  'Trimestral': 'Trimestral',
  'Semestral': 'Semestral',
  'Anual': 'Anual',
};

DateTime? _parseDate(dynamic v) => v == null ? null : DateTime.parse(v as String);

class Transacao {
  final String id;
  final String tipo;
  final double valor;
  final String? descricao;
  final DateTime data;
  final DateTime? dataVencimento;
  final DateTime? dataPagamento;
  final String status;
  final String contaId;
  final String contaNome;
  final String categoriaId;
  final String categoriaNome;
  final String? subcategoriaId;
  final String? subcategoriaNome;
  final String? contraParteId;
  final String? contraParteNome;
  final String? formaPagamentoId;
  final String? formaPagamentoNome;

  Transacao({
    required this.id,
    required this.tipo,
    required this.valor,
    this.descricao,
    required this.data,
    this.dataVencimento,
    this.dataPagamento,
    required this.status,
    required this.contaId,
    required this.contaNome,
    required this.categoriaId,
    required this.categoriaNome,
    this.subcategoriaId,
    this.subcategoriaNome,
    this.contraParteId,
    this.contraParteNome,
    this.formaPagamentoId,
    this.formaPagamentoNome,
  });

  bool get isEntrada => tipo == 'Entrada';

  factory Transacao.fromJson(Map<String, dynamic> j) => Transacao(
        id: j['id'] as String,
        tipo: j['tipo'] as String,
        valor: (j['valor'] as num).toDouble(),
        descricao: j['descricao'] as String?,
        data: DateTime.parse(j['data'] as String),
        dataVencimento: _parseDate(j['dataVencimento']),
        dataPagamento: _parseDate(j['dataPagamento']),
        status: j['status'] as String,
        contaId: j['contaId'] as String,
        contaNome: j['contaNome'] as String,
        categoriaId: j['categoriaId'] as String,
        categoriaNome: j['categoriaNome'] as String,
        subcategoriaId: j['subcategoriaId'] as String?,
        subcategoriaNome: j['subcategoriaNome'] as String?,
        contraParteId: j['contraParteId'] as String?,
        contraParteNome: j['contraParteNome'] as String?,
        formaPagamentoId: j['formaPagamentoId'] as String?,
        formaPagamentoNome: j['formaPagamentoNome'] as String?,
      );
}

class Recorrencia {
  final String id;
  final String descricao;
  final String frequencia;
  final String tipo;
  final double valor;
  final DateTime dataInicio;
  final DateTime? dataFim;
  final DateTime? proximaGeracao;
  final bool ativa;
  final String contaId;
  final String contaNome;
  final String categoriaId;
  final String categoriaNome;
  final String? contraParteId;
  final String? contraParteNome;

  Recorrencia({
    required this.id,
    required this.descricao,
    required this.frequencia,
    required this.tipo,
    required this.valor,
    required this.dataInicio,
    this.dataFim,
    this.proximaGeracao,
    required this.ativa,
    required this.contaId,
    required this.contaNome,
    required this.categoriaId,
    required this.categoriaNome,
    this.contraParteId,
    this.contraParteNome,
  });

  bool get isEntrada => tipo == 'Entrada';

  factory Recorrencia.fromJson(Map<String, dynamic> j) => Recorrencia(
        id: j['id'] as String,
        descricao: j['descricao'] as String,
        frequencia: j['frequencia'] as String,
        tipo: j['tipo'] as String,
        valor: (j['valor'] as num).toDouble(),
        dataInicio: DateTime.parse(j['dataInicio'] as String),
        dataFim: _parseDate(j['dataFim']),
        proximaGeracao: _parseDate(j['proximaGeracao']),
        ativa: j['ativa'] as bool,
        contaId: j['contaId'] as String,
        contaNome: j['contaNome'] as String,
        categoriaId: j['categoriaId'] as String,
        categoriaNome: j['categoriaNome'] as String,
        contraParteId: j['contraParteId'] as String?,
        contraParteNome: j['contraParteNome'] as String?,
      );
}

class Resumo {
  final double saldoTotalContas;
  final double entradasRealizadas;
  final double saidasRealizadas;
  final double resultadoPeriodo;
  final double aReceber;
  final double aPagar;
  final double receberAtrasado;
  final double pagarAtrasado;

  Resumo({
    required this.saldoTotalContas,
    required this.entradasRealizadas,
    required this.saidasRealizadas,
    required this.resultadoPeriodo,
    required this.aReceber,
    required this.aPagar,
    required this.receberAtrasado,
    required this.pagarAtrasado,
  });

  factory Resumo.fromJson(Map<String, dynamic> j) => Resumo(
        saldoTotalContas: (j['saldoTotalContas'] as num).toDouble(),
        entradasRealizadas: (j['entradasRealizadas'] as num).toDouble(),
        saidasRealizadas: (j['saidasRealizadas'] as num).toDouble(),
        resultadoPeriodo: (j['resultadoPeriodo'] as num).toDouble(),
        aReceber: (j['aReceber'] as num).toDouble(),
        aPagar: (j['aPagar'] as num).toDouble(),
        receberAtrasado: (j['receberAtrasado'] as num).toDouble(),
        pagarAtrasado: (j['pagarAtrasado'] as num).toDouble(),
      );
}
