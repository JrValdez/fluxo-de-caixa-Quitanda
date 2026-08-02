using FluxoCaixa.Domain.Enums;

namespace FluxoCaixa.Application.Features.Relatorios;

/// <summary>Ponto da série de saldo acumulado ao longo do tempo.</summary>
public record SaldoDiarioDto(DateOnly Data, decimal Entradas, decimal Saidas, decimal SaldoAcumulado);

/// <summary>Total movimentado por categoria no período.</summary>
public record CategoriaResumoDto(Guid CategoriaId, string Categoria, TipoCategoria Tipo, decimal Total);

/// <summary>Linha do DRE simplificado (por classificação).</summary>
public record DreLinhaDto(string Grupo, decimal Receitas, decimal Despesas, decimal Resultado);

public record DreDto(
    DateOnly De,
    DateOnly Ate,
    IReadOnlyList<DreLinhaDto> Linhas,
    decimal TotalReceitas,
    decimal TotalDespesas,
    decimal ResultadoLiquido);

/// <summary>Indicadores-chave do fluxo de caixa.</summary>
public record KpisDto(
    decimal TicketMedio,
    double PrazoMedioRecebimento,
    double PrazoMedioPagamento,
    decimal InadimplenciaPercent,
    decimal IndiceLiquidez,
    int QtdTransacoesPeriodo);
