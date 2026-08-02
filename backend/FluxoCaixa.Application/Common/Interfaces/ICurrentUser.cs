namespace FluxoCaixa.Application.Common.Interfaces;

/// <summary>Usuário autenticado da requisição atual (para auditoria).</summary>
public interface ICurrentUser
{
    string? Email { get; }
}
