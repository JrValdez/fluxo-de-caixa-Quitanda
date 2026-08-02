using FluxoCaixa.Application.Features.Transacoes;
using FluxoCaixa.Domain.Entities;
using FluxoCaixa.Infrastructure.Persistence;
using FluxoCaixa.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FluxoCaixa.Api.Controllers;

[ApiController]
[Route("api/recorrencias")]
[Authorize]
public class RecorrenciasController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly ManutencaoService _manutencao;
    public RecorrenciasController(AppDbContext db, ManutencaoService manutencao)
    {
        _db = db;
        _manutencao = manutencao;
    }

    private static readonly System.Linq.Expressions.Expression<Func<Recorrencia, RecorrenciaDto>> ToDto =
        r => new RecorrenciaDto(
            r.Id, r.Descricao, r.Frequencia, r.Tipo, r.Valor, r.DataInicio, r.DataFim, r.ProximaGeracao, r.Ativa,
            r.ContaId, r.Conta!.Nome, r.CategoriaId, r.Categoria!.Nome,
            r.ContraParteId, r.ContraParte != null ? r.ContraParte.Nome : null);

    [HttpGet]
    public async Task<ActionResult<IEnumerable<RecorrenciaDto>>> Listar()
    {
        var lista = await _db.Recorrencias.AsNoTracking().OrderBy(r => r.Descricao).Select(ToDto).ToListAsync();
        return Ok(lista);
    }

    [HttpPost]
    [Authorize(Policy = "PodeEditar")]
    public async Task<ActionResult<RecorrenciaDto>> Criar([FromBody] RecorrenciaInput input)
    {
        var r = new Recorrencia();
        Aplicar(r, input);
        r.ProximaGeracao = input.DataInicio;
        _db.Recorrencias.Add(r);
        await _db.SaveChangesAsync();
        var dto = await _db.Recorrencias.AsNoTracking().Where(x => x.Id == r.Id).Select(ToDto).FirstAsync();
        return Ok(dto);
    }

    [HttpPut("{id:guid}")]
    [Authorize(Policy = "PodeEditar")]
    public async Task<IActionResult> Atualizar(Guid id, [FromBody] RecorrenciaInput input)
    {
        var r = await _db.Recorrencias.FindAsync(id);
        if (r is null) return NotFound();
        Aplicar(r, input);
        r.AtualizadoEm = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Policy = "PodeEditar")]
    public async Task<IActionResult> Excluir(Guid id)
    {
        var r = await _db.Recorrencias.FindAsync(id);
        if (r is null) return NotFound();
        _db.Recorrencias.Remove(r);
        await _db.SaveChangesAsync();
        return NoContent();
    }

    /// <summary>Gera as transações previstas das recorrências ativas até a data informada (padrão: hoje + 31 dias).</summary>
    [HttpPost("gerar")]
    [Authorize(Policy = "PodeEditar")]
    public async Task<IActionResult> Gerar([FromQuery] DateOnly? ate)
    {
        var limite = ate ?? DateOnly.FromDateTime(DateTime.Today).AddDays(31);
        var geradas = await _manutencao.GerarRecorrenciasAsync(limite);
        return Ok(new { geradas });
    }

    private static void Aplicar(Recorrencia r, RecorrenciaInput i)
    {
        r.Descricao = i.Descricao.Trim();
        r.Frequencia = i.Frequencia;
        r.Tipo = i.Tipo;
        r.Valor = i.Valor;
        r.DataInicio = i.DataInicio;
        r.DataFim = i.DataFim;
        r.Ativa = i.Ativa;
        r.ContaId = i.ContaId;
        r.CategoriaId = i.CategoriaId;
        r.ContraParteId = i.ContraParteId;
    }
}
