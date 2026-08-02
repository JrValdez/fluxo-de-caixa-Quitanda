using FluxoCaixa.Domain.Enums;

namespace FluxoCaixa.Application.Features.Projecoes;

/// <summary>Ponto diário da projeção de caixa.</summary>
public record ProjecaoPontoDto(DateOnly Data, decimal Entradas, decimal Saidas, decimal SaldoProjetado);

/// <summary>Projeção de fluxo de caixa para um horizonte futuro.</summary>
public record ProjecaoDto(
    decimal SaldoInicial,
    int Dias,
    bool IncluiSimulacoes,
    IReadOnlyList<ProjecaoPontoDto> Pontos,
    decimal MenorSaldo,
    DateOnly? PrimeiroDiaNegativo);

/// <summary>Lançamento hipotético do simulador de cenários ("e se").</summary>
public record SimulacaoDto(
    Guid Id,
    TipoMovimento Tipo,
    decimal Valor,
    string? Descricao,
    DateOnly Data,
    Guid ContaId,
    string ContaNome,
    Guid CategoriaId,
    string CategoriaNome);

public record SimulacaoInput(
    TipoMovimento Tipo,
    decimal Valor,
    string? Descricao,
    DateOnly Data,
    Guid ContaId,
    Guid CategoriaId);

/// <summary>Indicadores de capital de giro / ciclo financeiro.</summary>
public record CapitalGiroDto(
    double PrazoMedioRecebimento,
    double PrazoMedioPagamento,
    double PrazoMedioEstoque,
    double CicloOperacional,
    double CicloFinanceiro,
    decimal DesembolsoDiarioMedio,
    decimal NecessidadeCapitalGiro);
