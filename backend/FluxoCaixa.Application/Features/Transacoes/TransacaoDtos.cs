using FluxoCaixa.Domain.Enums;

namespace FluxoCaixa.Application.Features.Transacoes;

public record TransacaoDto(
    Guid Id,
    TipoMovimento Tipo,
    decimal Valor,
    string? Descricao,
    DateOnly Data,
    DateOnly? DataVencimento,
    DateOnly? DataPagamento,
    StatusTransacao Status,
    Guid ContaId,
    string ContaNome,
    Guid CategoriaId,
    string CategoriaNome,
    Guid? SubcategoriaId,
    string? SubcategoriaNome,
    Guid? ContraParteId,
    string? ContraParteNome,
    Guid? FormaPagamentoId,
    string? FormaPagamentoNome);

public record TransacaoInput(
    TipoMovimento Tipo,
    decimal Valor,
    string? Descricao,
    DateOnly Data,
    DateOnly? DataVencimento,
    DateOnly? DataPagamento,
    StatusTransacao Status,
    Guid ContaId,
    Guid CategoriaId,
    Guid? SubcategoriaId,
    Guid? ContraParteId,
    Guid? FormaPagamentoId);

public record EfetivarInput(DateOnly? DataPagamento);

/// <summary>Resumo do fluxo de caixa num período.</summary>
public record ResumoDto(
    decimal SaldoTotalContas,
    decimal EntradasRealizadas,
    decimal SaidasRealizadas,
    decimal ResultadoPeriodo,
    decimal AReceber,
    decimal APagar,
    decimal ReceberAtrasado,
    decimal PagarAtrasado);
