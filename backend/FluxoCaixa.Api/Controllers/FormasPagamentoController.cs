using FluxoCaixa.Application.Features.Cadastros;
using FluxoCaixa.Domain.Entities;
using FluxoCaixa.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FluxoCaixa.Api.Controllers;

[ApiController]
[Route("api/formas-pagamento")]
[Authorize]
public class FormasPagamentoController : ControllerBase
{
    private readonly AppDbContext _db;
    public FormasPagamentoController(AppDbContext db) => _db = db;

    [HttpGet]
    public async Task<ActionResult<IEnumerable<FormaPagamentoDto>>> Listar()
    {
        var lista = await _db.FormasPagamento.AsNoTracking().OrderBy(f => f.Nome).ToListAsync();
        return Ok(lista.Select(f => new FormaPagamentoDto(f.Id, f.Nome, f.Ativa)));
    }

    [HttpPost]
    [Authorize(Policy = "PodeEditar")]
    public async Task<ActionResult<FormaPagamentoDto>> Criar([FromBody] FormaPagamentoInput input)
    {
        var f = new FormaPagamento { Nome = input.Nome.Trim(), Ativa = input.Ativa };
        _db.FormasPagamento.Add(f);
        await _db.SaveChangesAsync();
        return Ok(new FormaPagamentoDto(f.Id, f.Nome, f.Ativa));
    }

    [HttpPut("{id:guid}")]
    [Authorize(Policy = "PodeEditar")]
    public async Task<IActionResult> Atualizar(Guid id, [FromBody] FormaPagamentoInput input)
    {
        var f = await _db.FormasPagamento.FindAsync(id);
        if (f is null) return NotFound();
        f.Nome = input.Nome.Trim();
        f.Ativa = input.Ativa;
        await _db.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Policy = "PodeEditar")]
    public async Task<IActionResult> Excluir(Guid id)
    {
        var f = await _db.FormasPagamento.FindAsync(id);
        if (f is null) return NotFound();
        if (await _db.Transacoes.AnyAsync(t => t.FormaPagamentoId == id))
            return Conflict(new { mensagem = "Existem transações vinculadas a esta forma de pagamento." });
        _db.FormasPagamento.Remove(f);
        await _db.SaveChangesAsync();
        return NoContent();
    }
}
