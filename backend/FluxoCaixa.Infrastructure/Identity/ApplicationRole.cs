using Microsoft.AspNetCore.Identity;

namespace FluxoCaixa.Infrastructure.Identity;

/// <summary>Perfil de acesso (role) do Identity.</summary>
public class ApplicationRole : IdentityRole<Guid>
{
    public ApplicationRole() { }
    public ApplicationRole(string nome) : base(nome) { }
}
