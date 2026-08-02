namespace FluxoCaixa.Application.Common.Interfaces;

/// <summary>Gera tokens JWT para usuários autenticados.</summary>
public interface ITokenService
{
    TokenResult GerarToken(Guid usuarioId, string email, string nomeCompleto, IEnumerable<string> perfis);
}

public record TokenResult(string Token, DateTime ExpiraEm);
