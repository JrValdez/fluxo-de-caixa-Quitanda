using FluxoCaixa.Application.Features.Relatorios;
using FluxoCaixa.Domain.Enums;
using FluxoCaixa.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FluxoCaixa.Api.Controllers;

[ApiController]
[Route("api/relatorios")]
[Authorize]
public class RelatoriosController : ControllerBase
{
    private readonly AppDbContext _db;
    public RelatoriosController(AppDbContext db) => _db = db;

    private static (DateOnly de, DateOnly ate) Periodo(DateOnly? de, DateOnly? ate)
    {
        var hoje = DateOnly.FromDateTime(DateTime.Today);
        var inicio = de ?? new DateOnly(hoje.Year, hoje.Month, 1);
        var fim = ate ?? inicio.AddMonths(1).AddDays(-1);
        return (inicio, fim);
    }

    /// <summary>Série de entradas/saídas realizadas por dia e saldo acumulado.</summary>
    [HttpGet("saldo-diario")]
    public async Task<ActionResult<IEnumerable<SaldoDiarioDto>>> SaldoDiario([FromQuery] DateOnly? de, [FromQuery] DateOnly? ate)
    {
        var (inicio, fim) = Periodo(de, ate);

        var saldoInicialContas = await _db.Contas.SumAsync(c => (decimal?)c.SaldoInicial) ?? 0;
        var realizadas = _db.Transacoes.Where(t => !t.Simulado && t.Status == StatusTransacao.Realizado);

        var anteriores = await realizadas.Where(t => t.Data < inicio)
            .SumAsync(t => (decimal?)(t.Tipo == TipoMovimento.Entrada ? t.Valor : -t.Valor)) ?? 0;

        var doPeriodo = await realizadas.Where(t => t.Data >= inicio && t.Data <= fim)
            .Select(t => new { t.Data, t.Tipo, t.Valor })
            .ToListAsync();

        var porDia = doPeriodo.GroupBy(t => t.Data).ToDictionary(
            g => g.Key,
            g => (
                Entradas: g.Where(x => x.Tipo == TipoMovimento.Entrada).Sum(x => x.Valor),
                Saidas: g.Where(x => x.Tipo == TipoMovimento.Saida).Sum(x => x.Valor)));

        var serie = new List<SaldoDiarioDto>();
        var acumulado = saldoInicialContas + anteriores;
        for (var d = inicio; d <= fim; d = d.AddDays(1))
        {
            var (ent, sai) = porDia.TryGetValue(d, out var v) ? v : (0m, 0m);
            acumulado += ent - sai;
            serie.Add(new SaldoDiarioDto(d, ent, sai, acumulado));
        }
        return Ok(serie);
    }

    /// <summary>Total realizado por categoria no período.</summary>
    [HttpGet("categorias")]
    public async Task<ActionResult<IEnumerable<CategoriaResumoDto>>> PorCategoria([FromQuery] DateOnly? de, [FromQuery] DateOnly? ate)
    {
        var (inicio, fim) = Periodo(de, ate);
        // Projeta antes de agrupar; o GroupBy é feito em memória porque o EF Core não
        // traduz agrupamento por propriedades de navegação (Categoria.Nome/Tipo).
        var dados = await _db.Transacoes
            .Where(t => !t.Simulado && t.Status == StatusTransacao.Realizado && t.Data >= inicio && t.Data <= fim)
            .Select(t => new { t.CategoriaId, Nome = t.Categoria!.Nome, t.Categoria.Tipo, t.Valor })
            .ToListAsync();

        var result = dados
            .GroupBy(x => new { x.CategoriaId, x.Nome, x.Tipo })
            .Select(g => new CategoriaResumoDto(g.Key.CategoriaId, g.Key.Nome, g.Key.Tipo, g.Sum(x => x.Valor)))
            .OrderByDescending(x => x.Total)
            .ToList();
        return Ok(result);
    }

    /// <summary>DRE simplificado por classificação (operacional/investimento/financiamento).</summary>
    [HttpGet("dre")]
    public async Task<ActionResult<DreDto>> Dre([FromQuery] DateOnly? de, [FromQuery] DateOnly? ate)
    {
        var (inicio, fim) = Periodo(de, ate);
        var dados = await _db.Transacoes
            .Where(t => !t.Simulado && t.Status == StatusTransacao.Realizado && t.Data >= inicio && t.Data <= fim)
            .Select(t => new { t.Categoria!.Classificacao, t.Tipo, t.Valor })
            .ToListAsync();

        var linhas = new List<DreLinhaDto>();
        foreach (var grupo in Enum.GetValues<ClassificacaoCategoria>())
        {
            var doGrupo = dados.Where(d => d.Classificacao == grupo).ToList();
            var receitas = doGrupo.Where(d => d.Tipo == TipoMovimento.Entrada).Sum(d => d.Valor);
            var despesas = doGrupo.Where(d => d.Tipo == TipoMovimento.Saida).Sum(d => d.Valor);
            linhas.Add(new DreLinhaDto(grupo.ToString(), receitas, despesas, receitas - despesas));
        }

        var totRec = linhas.Sum(l => l.Receitas);
        var totDesp = linhas.Sum(l => l.Despesas);
        return Ok(new DreDto(inicio, fim, linhas, totRec, totDesp, totRec - totDesp));
    }

    /// <summary>Indicadores-chave (KPIs) do período.</summary>
    [HttpGet("kpis")]
    public async Task<ActionResult<KpisDto>> Kpis([FromQuery] DateOnly? de, [FromQuery] DateOnly? ate)
    {
        var (inicio, fim) = Periodo(de, ate);
        var realizadasPeriodo = await _db.Transacoes
            .Where(t => !t.Simulado && t.Status == StatusTransacao.Realizado && t.Data >= inicio && t.Data <= fim)
            .Select(t => new { t.Tipo, t.Valor, t.Data, t.DataPagamento })
            .ToListAsync();

        var entradas = realizadasPeriodo.Where(t => t.Tipo == TipoMovimento.Entrada).ToList();
        var saidas = realizadasPeriodo.Where(t => t.Tipo == TipoMovimento.Saida).ToList();

        var ticketMedio = entradas.Count > 0 ? entradas.Average(e => e.Valor) : 0m;

        static double PrazoMedio(IEnumerable<(DateOnly Data, DateOnly? Pagamento)> itens)
        {
            var comPagamento = itens.Where(i => i.Pagamento is not null).ToList();
            if (comPagamento.Count == 0) return 0;
            return comPagamento.Average(i => (double)(i.Pagamento!.Value.DayNumber - i.Data.DayNumber));
        }

        var pmr = PrazoMedio(entradas.Select(e => (e.Data, e.DataPagamento)));
        var pmp = PrazoMedio(saidas.Select(s => (s.Data, s.DataPagamento)));

        var abertasReceber = _db.Transacoes.Where(t => !t.Simulado && t.Tipo == TipoMovimento.Entrada &&
            (t.Status == StatusTransacao.Previsto || t.Status == StatusTransacao.Atrasado));
        var totalReceber = await abertasReceber.SumAsync(t => (decimal?)t.Valor) ?? 0;
        var receberAtraso = await abertasReceber.Where(t => t.Status == StatusTransacao.Atrasado).SumAsync(t => (decimal?)t.Valor) ?? 0;
        var inadimplencia = totalReceber > 0 ? Math.Round(receberAtraso / totalReceber * 100, 2) : 0;

        var saldoInicial = await _db.Contas.SumAsync(c => (decimal?)c.SaldoInicial) ?? 0;
        var netRealizado = await _db.Transacoes.Where(t => !t.Simulado && t.Status == StatusTransacao.Realizado)
            .SumAsync(t => (decimal?)(t.Tipo == TipoMovimento.Entrada ? t.Valor : -t.Valor)) ?? 0;
        var saldoTotal = saldoInicial + netRealizado;
        var totalPagar = await _db.Transacoes.Where(t => !t.Simulado && t.Tipo == TipoMovimento.Saida &&
            (t.Status == StatusTransacao.Previsto || t.Status == StatusTransacao.Atrasado)).SumAsync(t => (decimal?)t.Valor) ?? 0;
        var liquidez = totalPagar > 0 ? Math.Round((saldoTotal + totalReceber) / totalPagar, 2) : 0;

        return Ok(new KpisDto(Math.Round(ticketMedio, 2), Math.Round(pmr, 1), Math.Round(pmp, 1),
            inadimplencia, liquidez, realizadasPeriodo.Count));
    }
}
