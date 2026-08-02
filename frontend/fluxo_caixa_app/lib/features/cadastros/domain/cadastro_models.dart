// Modelos e enums dos cadastros base (espelham o backend, que serializa enums como texto).

// ---------- Rótulos de enums ----------
const tipoContaLabels = {
  'Banco': 'Banco',
  'CaixaFisico': 'Caixa físico',
  'CarteiraDigital': 'Carteira digital',
};

const tipoCategoriaLabels = {
  'Receita': 'Receita',
  'Despesa': 'Despesa',
};

const classificacaoLabels = {
  'Operacional': 'Operacional',
  'Investimento': 'Investimento',
  'Financiamento': 'Financiamento',
};

const tipoContraParteLabels = {
  'Cliente': 'Cliente',
  'Fornecedor': 'Fornecedor',
  'Ambos': 'Ambos',
};

// ---------- Conta ----------
class Conta {
  final String id;
  final String nome;
  final String tipo;
  final String moeda;
  final double saldoInicial;
  final double saldoAtual;
  final bool ativa;
  final String? observacao;

  Conta({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.moeda,
    required this.saldoInicial,
    required this.saldoAtual,
    required this.ativa,
    this.observacao,
  });

  factory Conta.fromJson(Map<String, dynamic> j) => Conta(
        id: j['id'] as String,
        nome: j['nome'] as String,
        tipo: j['tipo'] as String,
        moeda: j['moeda'] as String,
        saldoInicial: (j['saldoInicial'] as num).toDouble(),
        saldoAtual: (j['saldoAtual'] as num).toDouble(),
        ativa: j['ativa'] as bool,
        observacao: j['observacao'] as String?,
      );
}

// ---------- Categoria / Subcategoria ----------
class Subcategoria {
  final String id;
  final String nome;
  final bool ativa;
  Subcategoria({required this.id, required this.nome, required this.ativa});
  factory Subcategoria.fromJson(Map<String, dynamic> j) =>
      Subcategoria(id: j['id'] as String, nome: j['nome'] as String, ativa: j['ativa'] as bool);
}

class Categoria {
  final String id;
  final String nome;
  final String tipo;
  final String classificacao;
  final bool ativa;
  final List<Subcategoria> subcategorias;

  Categoria({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.classificacao,
    required this.ativa,
    required this.subcategorias,
  });

  factory Categoria.fromJson(Map<String, dynamic> j) => Categoria(
        id: j['id'] as String,
        nome: j['nome'] as String,
        tipo: j['tipo'] as String,
        classificacao: j['classificacao'] as String,
        ativa: j['ativa'] as bool,
        subcategorias: (j['subcategorias'] as List?)
                ?.map((e) => Subcategoria.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

// ---------- Contraparte ----------
class ContraParte {
  final String id;
  final String nome;
  final String tipo;
  final String? documento;
  final String? email;
  final String? telefone;
  final bool ativa;

  ContraParte({
    required this.id,
    required this.nome,
    required this.tipo,
    this.documento,
    this.email,
    this.telefone,
    required this.ativa,
  });

  factory ContraParte.fromJson(Map<String, dynamic> j) => ContraParte(
        id: j['id'] as String,
        nome: j['nome'] as String,
        tipo: j['tipo'] as String,
        documento: j['documento'] as String?,
        email: j['email'] as String?,
        telefone: j['telefone'] as String?,
        ativa: j['ativa'] as bool,
      );
}

// ---------- Forma de pagamento ----------
class FormaPagamento {
  final String id;
  final String nome;
  final bool ativa;
  FormaPagamento({required this.id, required this.nome, required this.ativa});
  factory FormaPagamento.fromJson(Map<String, dynamic> j) =>
      FormaPagamento(id: j['id'] as String, nome: j['nome'] as String, ativa: j['ativa'] as bool);
}
