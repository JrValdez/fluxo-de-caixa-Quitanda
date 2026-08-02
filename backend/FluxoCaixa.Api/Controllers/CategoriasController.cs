using FluxoCaixa.Application.Features.Cadastros;
using FluxoCaixa.Domain.Entities;
using FluxoCaixa.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FluxoCaixa.Api.Controllers;

[ApiController]
[Route("api/categorias")]
[Authorize]
public class CategoriasController : ControllerBase
{
    private readonly AppDbContext _db;
    public CategoriasController(AppDbContext db) => _db = db;

    private static CategoriaDto Map(Categoria c) => new(
        c.Id, c.Nome, c.Tipo, c.Classificacao, c.Ativa,
        c.Subcategorias.OrderBy(s => s.Nome)
            .Select(s => new SubcategoriaDto(s.Id, s.Nome, s.Ativa)).ToList());

    [HttpGet]
    public async Task<ActionResult<IEnumerable<CategoriaDto>>> Listar()
    {
        var cats = await _db.Categorias.AsNoTracking()
            .Include(c => c.Subcategorias)
            .OrderBy(c => c.Tipo).ThenBy(c => c.Nome)
            .ToListAsync();
        return Ok(cats.Select(Map));
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<CategoriaDto>> Obter(Guid id)
    {
        var c = await _db.Categorias.Include(x => x.Subcategorias).FirstOrDefaultAsync(x => x.Id == id);
        return c is null ? NotFound() : Ok(Map(c));
    }

    [HttpPost]
    [Authorize(Policy = "PodeEditar")]
    public async Task<ActionResult<CategoriaDto>> Criar([FromBody] CategoriaInput input)
    {
        var c = new Categoria
        {
            Nome = input.Nome.Trim(),
            Tipo = input.Tipo,
            Classificacao = input.Classificacao,
            Ativa = input.Ativa
        };
        _db.Categorias.Add(c);
        await _db.SaveChangesAsync();
        return CreatedAtAction(nameof(Obter), new { id = c.Id }, Map(c));
    }

    [HttpPut("{id:guid}")]
    [Authorize(Policy = "PodeEditar")]
    public async Task<IActionResult> Atualizar(Guid id, [FromBody] CategoriaInput input)
    {
        var c = await _db.Categorias.FindAsync(id);
        if (c is null) return NotFound();
        c.Nome = input.Nome.Trim();
        c.Tipo = input.Tipo;
        c.Classificacao = input.Classificacao;
        c.Ativa = input.Ativa;
        c.AtualizadoEm = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Policy = "PodeEditar")]
    public async Task<IActionResult> Excluir(Guid id)
    {
        var c = await _db.Categorias.FindAsync(id);
        if (c is null) return NotFound();
        if (await _db.Transacoes.AnyAsync(t => t.CategoriaId == id))
            return Conflict(new { mensagem = "Não é possível excluir: existem transações vinculadas. Desative a categoria." });
        _db.Categorias.Remove(c);
        await _db.SaveChangesAsync();
        return NoContent();
    }

    // ----- Subcategorias -----
    [HttpPost("{id:guid}/subcategorias")]
    [Authorize(Policy = "PodeEditar")]
    public async Task<ActionResult<SubcategoriaDto>> CriarSubcategoria(Guid id, [FromBody] SubcategoriaInput input)
    {
        if (!await _db.Categorias.AnyAsync(c => c.Id == id)) return NotFound();
        var s = new Subcategoria { Nome = input.Nome.Trim(), Ativa = input.Ativa, CategoriaId = id };
        _db.Subcategorias.Add(s);
        await _db.SaveChangesAsync();
        return Ok(new SubcategoriaDto(s.Id, s.Nome, s.Ativa));
    }

    [HttpPut("subcategorias/{subId:guid}")]
    [Authorize(Policy = "PodeEditar")]
    public async Task<IActionResult> AtualizarSubcategoria(Guid subId, [FromBody] SubcategoriaInput input)
    {
        var s = await _db.Subcategorias.FindAsync(subId);
        if (s is null) return NotFound();
        s.Nome = input.Nome.Trim();
        s.Ativa = input.Ativa;
        await _db.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("subcategorias/{subId:guid}")]
    [Authorize(Policy = "PodeEditar")]
    public async Task<IActionResult> ExcluirSubcategoria(Guid subId)
    {
        var s = await _db.Subcategorias.FindAsync(subId);
        if (s is null) return NotFound();
        if (await _db.Transacoes.AnyAsync(t => t.SubcategoriaId == subId))
            return Conflict(new { mensagem = "Existem transações vinculadas a esta subcategoria." });
        _db.Subcategorias.Remove(s);
        await _db.SaveChangesAsync();
        return NoContent();
    }
}
