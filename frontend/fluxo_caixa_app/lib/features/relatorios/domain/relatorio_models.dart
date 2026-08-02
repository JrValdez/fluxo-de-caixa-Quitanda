// Modelos dos relatórios (espelham o backend).

class SaldoDiario {
  final DateTime data;
  final double entradas;
  final double saidas;
  final double saldoAcumulado;
  SaldoDiario({required this.data, required this.entradas, required this.saidas, required this.saldoAcumulado});
  factory SaldoDiario.fromJson(Map<String, dynamic> j) => SaldoDiario(
        data: DateTime.parse(j['data'] as String),
        entradas: (j['entradas'] as num).toDouble(),
        saidas: (j['saidas'] as num).toDouble(),
        saldoAcumulado: (j['saldoAcumulado'] as num).toDouble(),
      );
}

class CategoriaResumo {
  final String categoria;
  final String tipo;
  final double total;
  CategoriaResumo({required this.categoria, required this.tipo, required this.total});
  factory CategoriaResumo.fromJson(Map<String, dynamic> j) => CategoriaResumo(
        categoria: j['categoria'] as String,
        tipo: j['tipo'] as String,
        total: (j['total'] as num).toDouble(),
      );
}

class DreLinha {
  final String grupo;
  final double receitas;
  final double despesas;
  final double resultado;
  DreLinha({required this.grupo, required this.receitas, required this.despesas, required this.resultado});
  factory DreLinha.fromJson(Map<String, dynamic> j) => DreLinha(
        grupo: j['grupo'] as String,
        receitas: (j['receitas'] as num).toDouble(),
        despesas: (j['despesas'] as num).toDouble(),
        resultado: (j['resultado'] as num).toDouble(),
      );
}

class Dre {
  final List<DreLinha> linhas;
  final double totalReceitas;
  final double totalDespesas;
  final double resultadoLiquido;
  Dre({required this.linhas, required this.totalReceitas, required this.totalDespesas, required this.resultadoLiquido});
  factory Dre.fromJson(Map<String, dynamic> j) => Dre(
        linhas: (j['linhas'] as List).map((e) => DreLinha.fromJson(e as Map<String, dynamic>)).toList(),
        totalReceitas: (j['totalReceitas'] as num).toDouble(),
        totalDespesas: (j['totalDespesas'] as num).toDouble(),
        resultadoLiquido: (j['resultadoLiquido'] as num).toDouble(),
      );
}

class Kpis {
  final double ticketMedio;
  final double prazoMedioRecebimento;
  final double prazoMedioPagamento;
  final double inadimplenciaPercent;
  final double indiceLiquidez;
  final int qtdTransacoesPeriodo;
  Kpis({
    required this.ticketMedio,
    required this.prazoMedioRecebimento,
    required this.prazoMedioPagamento,
    required this.inadimplenciaPercent,
    required this.indiceLiquidez,
    required this.qtdTransacoesPeriodo,
  });
  factory Kpis.fromJson(Map<String, dynamic> j) => Kpis(
        ticketMedio: (j['ticketMedio'] as num).toDouble(),
        prazoMedioRecebimento: (j['prazoMedioRecebimento'] as num).toDouble(),
        prazoMedioPagamento: (j['prazoMedioPagamento'] as num).toDouble(),
        inadimplenciaPercent: (j['inadimplenciaPercent'] as num).toDouble(),
        indiceLiquidez: (j['indiceLiquidez'] as num).toDouble(),
        qtdTransacoesPeriodo: (j['qtdTransacoesPeriodo'] as num).toInt(),
      );
}
