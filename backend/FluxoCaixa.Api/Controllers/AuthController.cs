using System.Security.Claims;
using FluxoCaixa.Application.Common.Interfaces;
using FluxoCaixa.Application.Features.Auth;
using FluxoCaixa.Infrastructure.Identity;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace FluxoCaixa.Api.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly ITokenService _tokenService;

    public AuthController(UserManager<ApplicationUser> userManager, ITokenService tokenService)
    {
        _userManager = userManager;
        _tokenService = tokenService;
    }

    /// <summary>Autentica um usuário e retorna o token JWT.</summary>
    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<ActionResult<AuthResponse>> Login([FromBody] LoginRequest request)
    {
        var user = await _userManager.FindByEmailAsync(request.Email);
        if (user is null || !user.Ativo || !await _userManager.CheckPasswordAsync(user, request.Senha))
            return Unauthorized(new { mensagem = "E-mail ou senha inválidos." });

        var perfis = await _userManager.GetRolesAsync(user);
        var token = _tokenService.GerarToken(user.Id, user.Email!, user.NomeCompleto, perfis);

        return Ok(new AuthResponse(token.Token, token.ExpiraEm, user.Email!, user.NomeCompleto, perfis.ToList()));
    }

    /// <summary>Retorna os dados do usuário autenticado.</summary>
    [HttpGet("me")]
    [Authorize]
    public async Task<ActionResult<UsuarioDto>> Me()
    {
        var id = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var user = id is not null ? await _userManager.FindByIdAsync(id) : null;
        if (user is null) return Unauthorized();

        var perfis = await _userManager.GetRolesAsync(user);
        return Ok(new UsuarioDto(user.Id, user.Email!, user.NomeCompleto, user.Ativo, perfis.ToList()));
    }

    /// <summary>Altera a senha do próprio usuário autenticado.</summary>
    [HttpPost("alterar-senha")]
    [Authorize]
    public async Task<IActionResult> AlterarSenha([FromBody] AlterarSenhaRequest request)
    {
        var id = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var user = id is not null ? await _userManager.FindByIdAsync(id) : null;
        if (user is null) return Unauthorized();

        var result = await _userManager.ChangePasswordAsync(user, request.SenhaAtual, request.NovaSenha);
        if (!result.Succeeded)
            return BadRequest(new { erros = result.Errors.Select(e => e.Description) });

        return NoContent();
    }
}
