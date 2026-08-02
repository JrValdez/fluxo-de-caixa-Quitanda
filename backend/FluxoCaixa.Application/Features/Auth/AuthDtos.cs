namespace FluxoCaixa.Application.Features.Auth;

public record LoginRequest(string Email, string Senha);

public record AuthResponse(
    string Token,
    DateTime ExpiraEm,
    string Email,
    string NomeCompleto,
    IReadOnlyList<string> Perfis);

public record UsuarioDto(
    Guid Id,
    string Email,
    string NomeCompleto,
    bool Ativo,
    IReadOnlyList<string> Perfis);

public record CriarUsuarioRequest(
    string Email,
    string NomeCompleto,
    string Senha,
    string Perfil);

public record AtualizarUsuarioRequest(
    string NomeCompleto,
    bool Ativo,
    string Perfil);

public record AlterarSenhaRequest(string SenhaAtual, string NovaSenha);
