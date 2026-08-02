using FluxoCaixa.Application.Features.Auth;
using FluxoCaixa.Domain.Constants;
using FluxoCaixa.Infrastructure.Identity;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FluxoCaixa.Api.Controllers;

[ApiController]
[Route("api/usuarios")]
[Authorize(Policy = "SomenteAdmin")]
public class UsuariosController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;

    public UsuariosController(UserManager<ApplicationUser> userManager) => _userManager = userManager;

    [HttpGet]
    public async Task<ActionResult<IEnumerable<UsuarioDto>>> Listar()
    {
        var users = await _userManager.Users.OrderBy(u => u.NomeCompleto).ToListAsync();
        var result = new List<UsuarioDto>();
        foreach (var u in users)
        {
            var perfis = await _userManager.GetRolesAsync(u);
            result.Add(new UsuarioDto(u.Id, u.Email!, u.NomeCompleto, u.Ativo, perfis.ToList()));
        }
        return Ok(result);
    }

    [HttpPost]
    public async Task<ActionResult<UsuarioDto>> Criar([FromBody] CriarUsuarioRequest request)
    {
        if (!Roles.Todos.Contains(request.Perfil))
            return BadRequest(new { mensagem = "Perfil inválido." });

        var user = new ApplicationUser
        {
            UserName = request.Email,
            Email = request.Email,
            EmailConfirmed = true,
            NomeCompleto = request.NomeCompleto,
            Ativo = true
        };
        var result = await _userManager.CreateAsync(user, request.Senha);
        if (!result.Succeeded)
            return BadRequest(new { erros = result.Errors.Select(e => e.Description) });

        await _userManager.AddToRoleAsync(user, request.Perfil);
        return CreatedAtAction(nameof(Listar), new UsuarioDto(
            user.Id, user.Email!, user.NomeCompleto, user.Ativo, new[] { request.Perfil }));
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Atualizar(Guid id, [FromBody] AtualizarUsuarioRequest request)
    {
        if (!Roles.Todos.Contains(request.Perfil))
            return BadRequest(new { mensagem = "Perfil inválido." });

        var user = await _userManager.FindByIdAsync(id.ToString());
        if (user is null) return NotFound();

        user.NomeCompleto = request.NomeCompleto;
        user.Ativo = request.Ativo;
        await _userManager.UpdateAsync(user);

        var perfisAtuais = await _userManager.GetRolesAsync(user);
        await _userManager.RemoveFromRolesAsync(user, perfisAtuais);
        await _userManager.AddToRoleAsync(user, request.Perfil);

        return NoContent();
    }

    [HttpPost("{id:guid}/redefinir-senha")]
    public async Task<IActionResult> RedefinirSenha(Guid id, [FromBody] RedefinirSenhaRequest request)
    {
        var user = await _userManager.FindByIdAsync(id.ToString());
        if (user is null) return NotFound();

        var token = await _userManager.GeneratePasswordResetTokenAsync(user);
        var result = await _userManager.ResetPasswordAsync(user, token, request.NovaSenha);
        if (!result.Succeeded)
            return BadRequest(new { erros = result.Errors.Select(e => e.Description) });

        return NoContent();
    }
}

public record RedefinirSenhaRequest(string NovaSenha);
