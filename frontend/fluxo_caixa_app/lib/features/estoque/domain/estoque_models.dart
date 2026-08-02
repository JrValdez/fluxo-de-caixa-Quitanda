// Modelos de estoque (espelham o backend).

const tipoMovimentoEstoqueLabels = {
  'Entrada': 'Entrada (compra)',
  'Saida': 'Saída (venda)',
  'Ajuste': 'Ajuste',
};

class Produto {
  final String id;
  final String nome;
  final String? sku;
  final String unidadeMedida;
  final double custoMedio;
  final double precoVenda;
  final double quantidadeAtual;
  final double estoqueMinimo;
  final bool ativo;
  final bool estoqueBaixo;

  Produto({
    required this.id,
    required this.nome,
    this.sku,
    required this.unidadeMedida,
    required this.custoMedio,
    required this.precoVenda,
    required this.quantidadeAtual,
    required this.estoqueMinimo,
    required this.ativo,
    required this.estoqueBaixo,
  });

  factory Produto.fromJson(Map<String, dynamic> j) => Produto(
        id: j['id'] as String,
        nome: j['nome'] as String,
        sku: j['sku'] as String?,
        unidadeMedida: j['unidadeMedida'] as String,
        custoMedio: (j['custoMedio'] as num).toDouble(),
        precoVenda: (j['precoVenda'] as num).toDouble(),
        quantidadeAtual: (j['quantidadeAtual'] as num).toDouble(),
        estoqueMinimo: (j['estoqueMinimo'] as num).toDouble(),
        ativo: j['ativo'] as bool,
        estoqueBaixo: j['estoqueBaixo'] as bool,
      );
}

class MovimentoEstoque {
  final String id;
  final String produtoNome;
  final String tipo;
  final double quantidade;
  final double custoUnitario;
  final DateTime data;
  final String? observacao;
  final String? transacaoId;

  MovimentoEstoque({
    required this.id,
    required this.produtoNome,
    required this.tipo,
    required this.quantidade,
    required this.custoUnitario,
    required this.data,
    this.observacao,
    this.transacaoId,
  });

  factory MovimentoEstoque.fromJson(Map<String, dynamic> j) => MovimentoEstoque(
        id: j['id'] as String,
        produtoNome: (j['produtoNome'] ?? '') as String,
        tipo: j['tipo'] as String,
        quantidade: (j['quantidade'] as num).toDouble(),
        custoUnitario: (j['custoUnitario'] as num).toDouble(),
        data: DateTime.parse(j['data'] as String),
        observacao: j['observacao'] as String?,
        transacaoId: j['transacaoId'] as String?,
      );
}
