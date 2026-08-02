using FluxoCaixa.Application.Features.Projecoes;
using FluxoCaixa.Domain.Entities;
using FluxoCaixa.Domain.Enums;
using FluxoCaixa.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FluxoCaixa.Api.Controllers;

/// <summary>Lançamentos hipotéticos ("e se") — não afetam o caixa real, só as projeções.</summary>
[ApiController]
[Route("api/simulacoes")]
[Authorize]
public class SimulacoesController : ControllerBase
{
    private readonly AppDbContext _db;
    public SimulacoesController(AppDbContext db) => _db = db;

    private static readonly System.Linq.Expressions.Expression<Func<Transacao, SimulacaoDto>> ToDto =
        t => new SimulacaoDto(t.Id, t.Tipo, t.Valor, t.Descricao, t.Data,
            t.ContaId, t.Conta!.Nome, t.CategoriaId, t.Categoria!.Nome);

    [HttpGet]
    public async Task<ActionResult<IEnumerable<SimulacaoDto>>> Listar()
    {
        var lista = await _db.Transacoes.AsNoTracking()
            .Where(t => t.Simulado)
            .OrderBy(t => t.Data)
            .Select(ToDto)
            .ToListAsync();
        return Ok(lista);
    }

    [HttpPost]
    [Authorize(Policy = "PodeEditar")]
    public async Task<ActionResult<SimulacaoDto>> Criar([FromBody] SimulacaoInput input)
    {
        if (input.Valor <= 0) return BadRequest(new { mensagem = "O valor deve ser maior que zero." });
        if (!await _db.Contas.AnyAsync(c => c.Id == input.ContaId)) return BadRequest(new { mensagem = "Conta inválida." });
        if (!await _db.Categorias.AnyAsync(c => c.Id == input.CategoriaId)) return BadRequest(new { mensagem = "Categoria inválida." });

        var t = new Transacao
        {
            Tipo = input.Tipo,
            Valor = input.Valor,
            Descricao = input.Descricao,
            Data = input.Data,
            DataVencimento = input.Data,
            Status = StatusTransacao.Previsto,
            ContaId = input.ContaId,
            CategoriaId = input.CategoriaId,
            Simulado = true
        };
        _db.Transacoes.Add(t);
        await _db.SaveChangesAsync();
        var dto = await _db.Transacoes.AsNoTracking().Where(x => x.Id == t.Id).Select(ToDto).FirstAsync();
        return Ok(dto);
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Policy = "PodeEditar")]
    public async Task<IActionResult> Excluir(Guid id)
    {
        var t = await _db.Transacoes.FirstOrDefaultAsync(x => x.Id == id && x.Simulado);
        if (t is null) return NotFound();
        _db.Transacoes.Remove(t);
        await _db.SaveChangesAsync();
        return NoContent();
    }

    /// <summary>Remove todos os lançamentos simulados (limpar cenário).</summary>
    [HttpDelete]
    [Authorize(Policy = "PodeEditar")]
    public async Task<IActionResult> Limpar()
    {
        await _db.Transacoes.Where(t => t.Simulado).ExecuteDeleteAsync();
        return NoContent();
    }
}
