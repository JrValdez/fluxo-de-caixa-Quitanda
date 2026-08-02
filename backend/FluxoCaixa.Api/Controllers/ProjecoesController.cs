using FluxoCaixa.Application.Features.Projecoes;
using FluxoCaixa.Domain.Enums;
using FluxoCaixa.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FluxoCaixa.Api.Controllers;

[ApiController]
[Route("api/projecoes")]
[Authorize]
public class ProjecoesController : ControllerBase
{
    private readonly AppDbContext _db;
    public ProjecoesController(AppDbContext db) => _db = db;

    /// <summary>
    /// Projeção de saldo para os próximos N dias (7/13/30/90), a partir do saldo atual,
    /// somando as contas a pagar/receber em aberto (e, opcionalmente, os lançamentos simulados).
    /// </summary>
    [HttpGet("caixa")]
    public async Task<ActionResult<ProjecaoDto>> Caixa([FromQuery] int dias = 13, [FromQuery] bool incluirSimulacoes = false)
    {
        dias = Math.Clamp(dias, 1, 365);
        var hoje = DateOnly.FromDateTime(DateTime.Today);
        var fim = hoje.AddDays(dias);

        var saldoInicialContas = await _db.Contas.SumAsync(c => (decimal?)c.SaldoInicial) ?? 0;
        var realizadoNet = await _db.Transacoes
            .Where(t => !t.Simulado && t.Status == StatusTransacao.Realizado)
            .SumAsync(t => (decimal?)(t.Tipo == TipoMovimento.Entrada ? t.Valor : -t.Valor)) ?? 0;
        var saldoAtual = saldoInicialContas + realizadoNet;

        // Abertas (previstas/atrasadas) + simuladas (opcional).
        var abertas = await _db.Transacoes
            .Where(t => t.Status == StatusTransacao.Previsto || t.Status == StatusTransacao.Atrasado)
            .Where(t => !t.Simulado || incluirSimulacoes)
            .Select(t => new { t.Tipo, t.Valor, t.Data, t.DataVencimento })
            .ToListAsync();

        var entradasPorDia = new Dictionary<DateOnly, decimal>();
        var saidasPorDia = new Dictionary<DateOnly, decimal>();
        foreach (var t in abertas)
        {
            var efetiva = t.DataVencimento ?? t.Data;
            if (efetiva < hoje) efetiva = hoje;   // vencidos entram imediatamente
            if (efetiva > fim) continue;          // fora do horizonte
            var mapa = t.Tipo == TipoMovimento.Entrada ? entradasPorDia : saidasPorDia;
            mapa[efetiva] = (mapa.TryGetValue(efetiva, out var v) ? v : 0) + t.Valor;
        }

        var pontos = new List<ProjecaoPontoDto>();
        var acumulado = saldoAtual;
        var menor = saldoAtual;
        DateOnly? primeiroNegativo = null;
        for (var d = hoje; d <= fim; d = d.AddDays(1))
        {
            var ent = entradasPorDia.TryGetValue(d, out var e) ? e : 0;
            var sai = saidasPorDia.TryGetValue(d, out var s) ? s : 0;
            acumulado += ent - sai;
            if (acumulado < menor) menor = acumulado;
            if (acumulado < 0 && primeiroNegativo is null) primeiroNegativo = d;
            pontos.Add(new ProjecaoPontoDto(d, ent, sai, acumulado));
        }

        return Ok(new ProjecaoDto(saldoAtual, dias, incluirSimulacoes, pontos, menor, primeiroNegativo));
    }

    /// <summary>Indicadores de capital de giro e ciclo financeiro no período (padrão: mês atual).</summary>
    [HttpGet("capital-giro")]
    public async Task<ActionResult<CapitalGiroDto>> CapitalGiro([FromQuery] DateOnly? de, [FromQuery] DateOnly? ate)
    {
        var hoje = DateOnly.FromDateTime(DateTime.Today);
        var inicio = de ?? new DateOnly(hoje.Year, hoje.Month, 1);
        var fim = ate ?? inicio.AddMonths(1).AddDays(-1);
        var diasPeriodo = Math.Max(1, fim.DayNumber - inicio.DayNumber + 1);

        var realizadas = await _db.Transacoes
            .Where(t => !t.Simulado && t.Status == StatusTransacao.Realizado && t.Data >= inicio && t.Data <= fim)
            .Select(t => new { t.Tipo, t.Valor, t.Data, t.DataPagamento })
            .ToListAsync();

        static double PrazoMedio(IEnumerable<(DateOnly Data, DateOnly? Pagamento)> itens)
        {
            var comPag = itens.Where(i => i.Pagamento is not null).ToList();
            return comPag.Count == 0 ? 0 : comPag.Average(i => (double)(i.Pagamento!.Value.DayNumber - i.Data.DayNumber));
        }

        var entradas = realizadas.Where(t => t.Tipo == TipoMovimento.Entrada).ToList();
        var saidas = realizadas.Where(t => t.Tipo == TipoMovimento.Saida).ToList();
        var pmr = PrazoMedio(entradas.Select(e => (e.Data, e.DataPagamento)));
        var pmp = PrazoMedio(saidas.Select(s => (s.Data, s.DataPagamento)));

        // Giro de estoque (PME) — depende dos produtos cadastrados (Fase 6).
        var valorEstoque = await _db.Produtos.SumAsync(p => (decimal?)(p.QuantidadeAtual * p.CustoMedio)) ?? 0;
        var totalSaidas = saidas.Sum(s => s.Valor);
        var cmvDiario = totalSaidas / diasPeriodo;
        var pme = cmvDiario > 0 ? (double)(valorEstoque / cmvDiario) : 0;

        var cicloOperacional = pme + pmr;
        var cicloFinanceiro = cicloOperacional - pmp;
        var desembolsoDiario = Math.Round(totalSaidas / diasPeriodo, 2);
        var ncg = Math.Round(desembolsoDiario * (decimal)Math.Max(0, cicloFinanceiro), 2);

        return Ok(new CapitalGiroDto(
            Math.Round(pmr, 1), Math.Round(pmp, 1), Math.Round(pme, 1),
            Math.Round(cicloOperacional, 1), Math.Round(cicloFinanceiro, 1),
            desembolsoDiario, ncg));
    }
}
