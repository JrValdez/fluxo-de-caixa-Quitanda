namespace FluxoCaixa.Infrastructure.Auth;

/// <summary>Configurações do token JWT (seção "Jwt" no appsettings).</summary>
public class JwtSettings
{
    public const string SectionName = "Jwt";

    public string Chave { get; set; } = string.Empty;
    public string Emissor { get; set; } = "FluxoCaixa";
    public string Audiencia { get; set; } = "FluxoCaixaApp";
    public int ExpiracaoMinutos { get; set; } = 480;
}
