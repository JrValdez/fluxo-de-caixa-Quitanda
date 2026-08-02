using FluxoCaixa.Application.Features.Cadastros;
using FluxoCaixa.Domain.Entities;
using FluxoCaixa.Domain.Enums;
using FluxoCaixa.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FluxoCaixa.Api.Controllers;

[ApiController]
[Route("api/contas")]
[Authorize]
public class ContasController : ControllerBase
{
    private readonly AppDbContext _db;
    public ContasController(AppDbContext db) => _db = db;

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ContaDto>>> Listar()
    {
        var contas = await _db.Contas.AsNoTracking().OrderBy(c => c.Nome).ToListAsync();

        // Saldo atual = saldo inicial + entradas realizadas - saídas realizadas.
        var movimentos = await _db.Transacoes
            .Where(t => t.Status == StatusTransacao.Realizado && !t.Simulado)
            .GroupBy(t => t.ContaId)
            .Select(g => new
            {
                ContaId = g.Key,
                Saldo = g.Sum(t => t.Tipo == TipoMovimento.Entrada ? t.Valor : -t.Valor)
            })
            .ToDictionaryAsync(x => x.ContaId, x => x.Saldo);

        var result = contas.Select(c => new ContaDto(
            c.Id, c.Nome, c.Tipo, c.Moeda, c.SaldoInicial,
            c.SaldoInicial + (movimentos.TryGetValue(c.Id, out var s) ? s : 0),
            c.Ativa, c.Observacao));

        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ContaDto>> Obter(Guid id)
    {
        var c = await _db.Contas.FindAsync(id);
        if (c is null) return NotFound();
        return Ok(new ContaDto(c.Id, c.Nome, c.Tipo, c.Moeda, c.SaldoInicial, c.SaldoInicial, c.Ativa, c.Observacao));
    }

    [HttpPost]
    [Authorize(Policy = "PodeEditar")]
    public async Task<ActionResult<ContaDto>> Criar([FromBody] ContaInput input)
    {
        var c = new Conta
        {
            Nome = input.Nome.Trim(),
            Tipo = input.Tipo,
            Moeda = string.IsNullOrWhiteSpace(input.Moeda) ? "BRL" : input.Moeda.Trim().ToUpperInvariant(),
            SaldoInicial = input.SaldoInicial,
            Ativa = input.Ativa,
            Observacao = input.Observacao
        };
        _db.Contas.Add(c);
        await _db.SaveChangesAsync();
        return CreatedAtAction(nameof(Obter), new { id = c.Id },
            new ContaDto(c.Id, c.Nome, c.Tipo, c.Moeda, c.SaldoInicial, c.SaldoInicial, c.Ativa, c.Observacao));
    }

    [HttpPut("{id:guid}")]
    [Authorize(Policy = "PodeEditar")]
    public async Task<IActionResult> Atualizar(Guid id, [FromBody] ContaInput input)
    {
        var c = await _db.Contas.FindAsync(id);
        if (c is null) return NotFound();
        c.Nome = input.Nome.Trim();
        c.Tipo = input.Tipo;
        c.Moeda = string.IsNullOrWhiteSpace(input.Moeda) ? "BRL" : input.Moeda.Trim().ToUpperInvariant();
        c.SaldoInicial = input.SaldoInicial;
        c.Ativa = input.Ativa;
        c.Observacao = input.Observacao;
        c.AtualizadoEm = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Policy = "PodeEditar")]
    public async Task<IActionResult> Excluir(Guid id)
    {
        var c = await _db.Contas.FindAsync(id);
        if (c is null) return NotFound();
        if (await _db.Transacoes.AnyAsync(t => t.ContaId == id))
            return Conflict(new { mensagem = "Não é possível excluir: existem transações vinculadas. Desative a conta." });
        _db.Contas.Remove(c);
        await _db.SaveChangesAsync();
        return NoContent();
    }
}
