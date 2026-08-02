using FluxoCaixa.Application.Features.Transacoes;
using FluxoCaixa.Domain.Entities;
using FluxoCaixa.Domain.Enums;
using FluxoCaixa.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FluxoCaixa.Api.Controllers;

[ApiController]
[Route("api/transacoes")]
[Authorize]
public class TransacoesController : ControllerBase
{
    private readonly AppDbContext _db;
    public TransacoesController(AppDbContext db) => _db = db;

    private static readonly System.Linq.Expressions.Expression<Func<Transacao, TransacaoDto>> ToDto =
        t => new TransacaoDto(
            t.Id, t.Tipo, t.Valor, t.Descricao, t.Data, t.DataVencimento, t.DataPagamento, t.Status,
            t.ContaId, t.Conta!.Nome,
            t.CategoriaId, t.Categoria!.Nome,
            t.SubcategoriaId, t.Subcategoria != null ? t.Subcategoria.Nome : null,
            t.ContraParteId, t.ContraParte != null ? t.ContraParte.Nome : null,
            t.FormaPagamentoId, t.FormaPagamento != null ? t.FormaPagamento.Nome : null);

    [HttpGet]
    public async Task<ActionResult<IEnumerable<TransacaoDto>>> Listar(
        [FromQuery] DateOnly? de, [FromQuery] DateOnly? ate,
        [FromQuery] TipoMovimento? tipo, [FromQuery] StatusTransacao? status,
        [FromQuery] Guid? contaId, [FromQuery] Guid? categoriaId, [FromQuery] Guid? contraParteId,
        [FromQuery] string? texto)
    {
        var q = _db.Transacoes.AsNoTracking().Where(t => !t.Simulado);
        if (de is not null) q = q.Where(t => t.Data >= de);
        if (ate is not null) q = q.Where(t => t.Data <= ate);
        if (tipo is not null) q = q.Where(t => t.Tipo == tipo);
        if (status is not null) q = q.Where(t => t.Status == status);
        if (contaId is not null) q = q.Where(t => t.ContaId == contaId);
        if (categoriaId is not null) q = q.Where(t => t.CategoriaId == categoriaId);
        if (contraParteId is not null) q = q.Where(t => t.ContraParteId == contraParteId);
        if (!string.IsNullOrWhiteSpace(texto))
            q = q.Where(t => t.Descricao != null && EF.Functions.ILike(t.Descricao, $"%{texto}%"));

        var lista = await q.OrderByDescending(t => t.Data).ThenByDescending(t => t.CriadoEm)
            .Select(ToDto).ToListAsync();
        return Ok(lista);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<TransacaoDto>> Obter(Guid id)
    {
        var dto = await _db.Transacoes.AsNoTracking().Where(t => t.Id == id).Select(ToDto).FirstOrDefaultAsync();
        return dto is null ? NotFound() : Ok(dto);
    }

    [HttpPost]
    [Authorize(Policy = "PodeEditar")]
    public async Task<ActionResult<TransacaoDto>> Criar([FromBody] TransacaoInput input)
    {
        var erro = await ValidarVinculos(input);
        if (erro is not null) return BadRequest(new { mensagem = erro });

        var t = new Transacao();
        Aplicar(t, input);
        _db.Transacoes.Add(t);
        await _db.SaveChangesAsync();
        var dto = await _db.Transacoes.AsNoTracking().Where(x => x.Id == t.Id).Select(ToDto).FirstAsync();
        return CreatedAtAction(nameof(Obter), new { id = t.Id }, dto);
    }

    [HttpPut("{id:guid}")]
    [Authorize(Policy = "PodeEditar")]
    public async Task<IActionResult> Atualizar(Guid id, [FromBody] TransacaoInput input)
    {
        var t = await _db.Transacoes.FindAsync(id);
        if (t is null) return NotFound();
        var erro = await ValidarVinculos(input);
        if (erro is not null) return BadRequest(new { mensagem = erro });

        Aplicar(t, input);
        t.AtualizadoEm = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Policy = "PodeEditar")]
    public async Task<IActionResult> Excluir(Guid id)
    {
        var t = await _db.Transacoes.FindAsync(id);
        if (t is null) return NotFound();
        _db.Transacoes.Remove(t);
        await _db.SaveChangesAsync();
        return NoContent();
    }

    /// <summary>Marca uma transação prevista/atrasada como realizada (efetivada no caixa).</summary>
    [HttpPost("{id:guid}/efetivar")]
    [Authorize(Policy = "PodeEditar")]
    public async Task<IActionResult> Efetivar(Guid id, [FromBody] EfetivarInput input)
    {
        var t = await _db.Transacoes.FindAsync(id);
        if (t is null) return NotFound();
        t.Status = StatusTransacao.Realizado;
        t.DataPagamento = input.DataPagamento ?? DateOnly.FromDateTime(DateTime.Today);
        t.AtualizadoEm = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return NoContent();
    }

    /// <summary>Resumo do fluxo de caixa no período informado (padrão: mês atual).</summary>
    [HttpGet("resumo")]
    public async Task<ActionResult<ResumoDto>> Resumo([FromQuery] DateOnly? de, [FromQuery] DateOnly? ate)
    {
        var hoje = DateOnly.FromDateTime(DateTime.Today);
        var inicio = de ?? new DateOnly(hoje.Year, hoje.Month, 1);
        var fim = ate ?? inicio.AddMonths(1).AddDays(-1);

        var saldoInicialContas = await _db.Contas.SumAsync(c => (decimal?)c.SaldoInicial) ?? 0;
        var realizadas = _db.Transacoes.Where(t => !t.Simulado && t.Status == StatusTransacao.Realizado);
        var totEntradasReal = await realizadas.Where(t => t.Tipo == TipoMovimento.Entrada).SumAsync(t => (decimal?)t.Valor) ?? 0;
        var totSaidasReal = await realizadas.Where(t => t.Tipo == TipoMovimento.Saida).SumAsync(t => (decimal?)t.Valor) ?? 0;
        var saldoTotal = saldoInicialContas + totEntradasReal - totSaidasReal;

        var noPeriodo = realizadas.Where(t => t.Data >= inicio && t.Data <= fim);
        var entradasPeriodo = await noPeriodo.Where(t => t.Tipo == TipoMovimento.Entrada).SumAsync(t => (decimal?)t.Valor) ?? 0;
        var saidasPeriodo = await noPeriodo.Where(t => t.Tipo == TipoMovimento.Saida).SumAsync(t => (decimal?)t.Valor) ?? 0;

        var abertas = _db.Transacoes.Where(t => !t.Simulado &&
            (t.Status == StatusTransacao.Previsto || t.Status == StatusTransacao.Atrasado));
        var aReceber = await abertas.Where(t => t.Tipo == TipoMovimento.Entrada).SumAsync(t => (decimal?)t.Valor) ?? 0;
        var aPagar = await abertas.Where(t => t.Tipo == TipoMovimento.Saida).SumAsync(t => (decimal?)t.Valor) ?? 0;
        var receberAtraso = await abertas.Where(t => t.Tipo == TipoMovimento.Entrada && t.Status == StatusTransacao.Atrasado).SumAsync(t => (decimal?)t.Valor) ?? 0;
        var pagarAtraso = await abertas.Where(t => t.Tipo == TipoMovimento.Saida && t.Status == StatusTransacao.Atrasado).SumAsync(t => (decimal?)t.Valor) ?? 0;

        return Ok(new ResumoDto(saldoTotal, entradasPeriodo, saidasPeriodo,
            entradasPeriodo - saidasPeriodo, aReceber, aPagar, receberAtraso, pagarAtraso));
    }

    /// <summary>Contas a pagar/receber em aberto (previstas/atrasadas), ordenadas por vencimento.</summary>
    [HttpGet("agenda")]
    public async Task<ActionResult<IEnumerable<TransacaoDto>>> Agenda([FromQuery] DateOnly? ate)
    {
        var q = _db.Transacoes.AsNoTracking().Where(t => !t.Simulado &&
            (t.Status == StatusTransacao.Previsto || t.Status == StatusTransacao.Atrasado));
        if (ate is not null) q = q.Where(t => (t.DataVencimento ?? t.Data) <= ate);
        var lista = await q.OrderBy(t => t.DataVencimento ?? t.Data).Select(ToDto).ToListAsync();
        return Ok(lista);
    }

    // ----- helpers -----
    private async Task<string?> ValidarVinculos(TransacaoInput input)
    {
        if (input.Valor <= 0) return "O valor deve ser maior que zero.";
        if (!await _db.Contas.AnyAsync(c => c.Id == input.ContaId)) return "Conta inválida.";
        if (!await _db.Categorias.AnyAsync(c => c.Id == input.CategoriaId)) return "Categoria inválida.";
        return null;
    }

    private static void Aplicar(Transacao t, TransacaoInput i)
    {
        t.Tipo = i.Tipo;
        t.Valor = i.Valor;
        t.Descricao = i.Descricao;
        t.Data = i.Data;
        t.DataVencimento = i.DataVencimento;
        t.DataPagamento = i.Status == StatusTransacao.Realizado
            ? (i.DataPagamento ?? i.Data)
            : i.DataPagamento;
        t.Status = i.Status;
        t.ContaId = i.ContaId;
        t.CategoriaId = i.CategoriaId;
        t.SubcategoriaId = i.SubcategoriaId;
        t.ContraParteId = i.ContraParteId;
        t.FormaPagamentoId = i.FormaPagamentoId;
    }
}
