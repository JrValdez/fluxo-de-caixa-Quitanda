using System.Security.Claims;
using FluxoCaixa.Application.Common.Interfaces;

namespace FluxoCaixa.Api.Services;

/// <summary>Lê o usuário autenticado do HttpContext (para auditoria).</summary>
public class CurrentUser : ICurrentUser
{
    private readonly IHttpContextAccessor _accessor;
    public CurrentUser(IHttpContextAccessor accessor) => _accessor = accessor;

    public string? Email =>
        _accessor.HttpContext?.User.FindFirstValue(ClaimTypes.Email)
        ?? _accessor.HttpContext?.User.FindFirstValue(ClaimTypes.Name);
}
