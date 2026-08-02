using FluxoCaixa.Application.Features.Cadastros;
using FluxoCaixa.Domain.Entities;
using FluxoCaixa.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FluxoCaixa.Api.Controllers;

[ApiController]
[Route("api/contrapartes")]
[Authorize]
public class ContraPartesController : ControllerBase
{
    private readonly AppDbContext _db;
    public ContraPartesController(AppDbContext db) => _db = db;

    private static ContraParteDto Map(ContraParte c) =>
        new(c.Id, c.Nome, c.Tipo, c.Documento, c.Email, c.Telefone, c.Ativa);

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ContraParteDto>>> Listar()
    {
        var lista = await _db.ContraPartes.AsNoTracking().OrderBy(c => c.Nome).ToListAsync();
        return Ok(lista.Select(Map));
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ContraParteDto>> Obter(Guid id)
    {
        var c = await _db.ContraPartes.FindAsync(id);
        return c is null ? NotFound() : Ok(Map(c));
    }

    [HttpPost]
    [Authorize(Policy = "PodeEditar")]
    public async Task<ActionResult<ContraParteDto>> Criar([FromBody] ContraParteInput input)
    {
        var c = new ContraParte
        {
            Nome = input.Nome.Trim(),
            Tipo = input.Tipo,
            Documento = input.Documento,
            Email = input.Email,
            Telefone = input.Telefone,
            Ativa = input.Ativa
        };
        _db.ContraPartes.Add(c);
        await _db.SaveChangesAsync();
        return CreatedAtAction(nameof(Obter), new { id = c.Id }, Map(c));
    }

    [HttpPut("{id:guid}")]
    [Authorize(Policy = "PodeEditar")]
    public async Task<IActionResult> Atualizar(Guid id, [FromBody] ContraParteInput input)
    {
        var c = await _db.ContraPartes.FindAsync(id);
        if (c is null) return NotFound();
        c.Nome = input.Nome.Trim();
        c.Tipo = input.Tipo;
        c.Documento = input.Documento;
        c.Email = input.Email;
        c.Telefone = input.Telefone;
        c.Ativa = input.Ativa;
        c.AtualizadoEm = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Policy = "PodeEditar")]
    public async Task<IActionResult> Excluir(Guid id)
    {
        var c = await _db.ContraPartes.FindAsync(id);
        if (c is null) return NotFound();
        if (await _db.Transacoes.AnyAsync(t => t.ContraParteId == id))
            return Conflict(new { mensagem = "Não é possível excluir: existem transações vinculadas. Desative o cadastro." });
        _db.ContraPartes.Remove(c);
        await _db.SaveChangesAsync();
        return NoContent();
    }
}
