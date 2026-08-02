using Microsoft.AspNetCore.Identity;

namespace FluxoCaixa.Infrastructure.Identity;

/// <summary>Usuário do sistema (estende o Identity do ASP.NET Core).</summary>
public class ApplicationUser : IdentityUser<Guid>
{
    public string NomeCompleto { get; set; } = string.Empty;
    public bool Ativo { get; set; } = true;
    public DateTime CriadoEm { get; set; } = DateTime.UtcNow;
}
