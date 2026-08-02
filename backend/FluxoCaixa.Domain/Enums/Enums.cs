namespace FluxoCaixa.Domain.Enums;

/// <summary>Tipo de conta/caixa onde o dinheiro fica guardado.</summary>
public enum TipoConta
{
    Banco = 1,
    CaixaFisico = 2,
    CarteiraDigital = 3
}

/// <summary>Direção do movimento financeiro.</summary>
public enum TipoMovimento
{
    Entrada = 1,
    Saida = 2
}

/// <summary>Natureza contábil da categoria.</summary>
public enum TipoCategoria
{
    Receita = 1,
    Despesa = 2
}

/// <summary>Classificação alinhada ao demonstrativo de fluxo de caixa (DFC).</summary>
public enum ClassificacaoCategoria
{
    Operacional = 1,
    Investimento = 2,
    Financiamento = 3
}

/// <summary>Situação de uma transação no fluxo de caixa.</summary>
public enum StatusTransacao
{
    Previsto = 1,
    Realizado = 2,
    Atrasado = 3,
    Cancelado = 4
}

/// <summary>Papel de uma contraparte (cliente/fornecedor).</summary>
public enum TipoContraParte
{
    Cliente = 1,
    Fornecedor = 2,
    Ambos = 3
}

/// <summary>Periodicidade de um lançamento recorrente.</summary>
public enum FrequenciaRecorrencia
{
    Diaria = 1,
    Semanal = 2,
    Quinzenal = 3,
    Mensal = 4,
    Bimestral = 5,
    Trimestral = 6,
    Semestral = 7,
    Anual = 8
}

/// <summary>Tipo de movimento de estoque.</summary>
public enum TipoMovimentoEstoque
{
    Entrada = 1,
    Saida = 2,
    Ajuste = 3
}
