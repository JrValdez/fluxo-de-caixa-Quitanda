using FluxoCaixa.Domain.Enums;

namespace FluxoCaixa.Application.Features.Transacoes;

public record RecorrenciaDto(
    Guid Id,
    string Descricao,
    FrequenciaRecorrencia Frequencia,
    TipoMovimento Tipo,
    decimal Valor,
    DateOnly DataInicio,
    DateOnly? DataFim,
    DateOnly? ProximaGeracao,
    bool Ativa,
    Guid ContaId,
    string ContaNome,
    Guid CategoriaId,
    string CategoriaNome,
    Guid? ContraParteId,
    string? ContraParteNome);

public record RecorrenciaInput(
    string Descricao,
    FrequenciaRecorrencia Frequencia,
    TipoMovimento Tipo,
    decimal Valor,
    DateOnly DataInicio,
    DateOnly? DataFim,
    bool Ativa,
    Guid ContaId,
    Guid CategoriaId,
    Guid? ContraParteId);
