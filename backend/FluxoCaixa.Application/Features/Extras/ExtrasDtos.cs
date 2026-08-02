using FluxoCaixa.Domain.Enums;

namespace FluxoCaixa.Application.Features.Extras;

// ----- Alertas -----
public enum SeveridadeAlerta { Info = 1, Aviso = 2, Critico = 3 }

public record AlertaDto(string Tipo, SeveridadeAlerta Severidade, string Titulo, string Descricao, DateOnly? Data);

// ----- Auditoria -----
public record AuditLogDto(
    Guid Id,
    string Entidade,
    string EntidadeId,
    string Acao,
    string? Usuario,
    string? DadosDepois,
    DateTime CriadoEm);

// ----- Conciliação bancária (importação de extrato) -----
public record ImportarExtratoRequest(Guid ContaId, string Conteudo);

/// <summary>Linha do extrato importada, com possível correspondência a uma transação prevista.</summary>
public record LinhaExtratoDto(
    DateOnly Data,
    string Descricao,
    decimal Valor,
    TipoMovimento Tipo,
    Guid? TransacaoCorrespondenteId,
    string? DescricaoCorrespondente);

public record ConciliarRequest(
    Guid ContaId,
    DateOnly Data,
    string Descricao,
    decimal Valor,
    TipoMovimento Tipo,
    Guid? TransacaoCorrespondenteId,
    Guid CategoriaId);
