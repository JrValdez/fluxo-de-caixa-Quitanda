using FluxoCaixa.Domain.Enums;

namespace FluxoCaixa.Application.Features.Estoque;

public record ProdutoDto(
    Guid Id,
    string Nome,
    string? Sku,
    string UnidadeMedida,
    decimal CustoMedio,
    decimal PrecoVenda,
    decimal QuantidadeAtual,
    decimal EstoqueMinimo,
    bool Ativo,
    bool EstoqueBaixo);

public record ProdutoInput(
    string Nome,
    string? Sku,
    string UnidadeMedida,
    decimal PrecoVenda,
    decimal EstoqueMinimo,
    bool Ativo,
    // usados apenas na criação (estoque inicial); ignorados na edição de quantidade
    decimal CustoMedio,
    decimal QuantidadeInicial);

public record MovimentoEstoqueDto(
    Guid Id,
    Guid ProdutoId,
    string ProdutoNome,
    TipoMovimentoEstoque Tipo,
    decimal Quantidade,
    decimal CustoUnitario,
    DateOnly Data,
    string? Observacao,
    Guid? TransacaoId,
    decimal QuantidadeResultante);

/// <summary>
/// Registro de movimento de estoque. Se GerarTransacao=true, cria um lançamento no caixa:
/// Entrada de estoque (compra) → Saída de caixa; Saída de estoque (venda) → Entrada de caixa.
/// </summary>
public record MovimentoEstoqueInput(
    Guid ProdutoId,
    TipoMovimentoEstoque Tipo,
    decimal Quantidade,
    decimal CustoUnitario,
    DateOnly Data,
    string? Observacao,
    bool GerarTransacao,
    decimal? ValorTransacao,
    Guid? ContaId,
    Guid? CategoriaId,
    Guid? FormaPagamentoId,
    Guid? ContraParteId);
