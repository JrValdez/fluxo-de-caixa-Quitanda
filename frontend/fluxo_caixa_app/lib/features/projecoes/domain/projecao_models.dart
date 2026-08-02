// Modelos de projeção, simulação e capital de giro (espelham o backend).

class ProjecaoPonto {
  final DateTime data;
  final double entradas;
  final double saidas;
  final double saldoProjetado;
  ProjecaoPonto({required this.data, required this.entradas, required this.saidas, required this.saldoProjetado});
  factory ProjecaoPonto.fromJson(Map<String, dynamic> j) => ProjecaoPonto(
        data: DateTime.parse(j['data'] as String),
        entradas: (j['entradas'] as num).toDouble(),
        saidas: (j['saidas'] as num).toDouble(),
        saldoProjetado: (j['saldoProjetado'] as num).toDouble(),
      );
}

class Projecao {
  final double saldoInicial;
  final int dias;
  final bool incluiSimulacoes;
  final List<ProjecaoPonto> pontos;
  final double menorSaldo;
  final DateTime? primeiroDiaNegativo;

  Projecao({
    required this.saldoInicial,
    required this.dias,
    required this.incluiSimulacoes,
    required this.pontos,
    required this.menorSaldo,
    this.primeiroDiaNegativo,
  });

  factory Projecao.fromJson(Map<String, dynamic> j) => Projecao(
        saldoInicial: (j['saldoInicial'] as num).toDouble(),
        dias: j['dias'] as int,
        incluiSimulacoes: j['incluiSimulacoes'] as bool,
        pontos: (j['pontos'] as List).map((e) => ProjecaoPonto.fromJson(e as Map<String, dynamic>)).toList(),
        menorSaldo: (j['menorSaldo'] as num).toDouble(),
        primeiroDiaNegativo: j['primeiroDiaNegativo'] == null ? null : DateTime.parse(j['primeiroDiaNegativo'] as String),
      );
}

class Simulacao {
  final String id;
  final String tipo;
  final double valor;
  final String? descricao;
  final DateTime data;
  final String contaId;
  final String contaNome;
  final String categoriaId;
  final String categoriaNome;

  Simulacao({
    required this.id,
    required this.tipo,
    required this.valor,
    this.descricao,
    required this.data,
    required this.contaId,
    required this.contaNome,
    required this.categoriaId,
    required this.categoriaNome,
  });

  bool get isEntrada => tipo == 'Entrada';

  factory Simulacao.fromJson(Map<String, dynamic> j) => Simulacao(
        id: j['id'] as String,
        tipo: j['tipo'] as String,
        valor: (j['valor'] as num).toDouble(),
        descricao: j['descricao'] as String?,
        data: DateTime.parse(j['data'] as String),
        contaId: j['contaId'] as String,
        contaNome: j['contaNome'] as String,
        categoriaId: j['categoriaId'] as String,
        categoriaNome: j['categoriaNome'] as String,
      );
}

class CapitalGiro {
  final double prazoMedioRecebimento;
  final double prazoMedioPagamento;
  final double prazoMedioEstoque;
  final double cicloOperacional;
  final double cicloFinanceiro;
  final double desembolsoDiarioMedio;
  final double necessidadeCapitalGiro;

  CapitalGiro({
    required this.prazoMedioRecebimento,
    required this.prazoMedioPagamento,
    required this.prazoMedioEstoque,
    required this.cicloOperacional,
    required this.cicloFinanceiro,
    required this.desembolsoDiarioMedio,
    required this.necessidadeCapitalGiro,
  });

  factory CapitalGiro.fromJson(Map<String, dynamic> j) => CapitalGiro(
        prazoMedioRecebimento: (j['prazoMedioRecebimento'] as num).toDouble(),
        prazoMedioPagamento: (j['prazoMedioPagamento'] as num).toDouble(),
        prazoMedioEstoque: (j['prazoMedioEstoque'] as num).toDouble(),
        cicloOperacional: (j['cicloOperacional'] as num).toDouble(),
        cicloFinanceiro: (j['cicloFinanceiro'] as num).toDouble(),
        desembolsoDiarioMedio: (j['desembolsoDiarioMedio'] as num).toDouble(),
        necessidadeCapitalGiro: (j['necessidadeCapitalGiro'] as num).toDouble(),
      );
}
