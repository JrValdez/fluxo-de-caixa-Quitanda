using FluxoCaixa.Application.Features.Extras;
using FluxoCaixa.Domain.Enums;
using FluxoCaixa.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FluxoCaixa.Api.Controllers;

[ApiController]
[Route("api/alertas")]
[Authorize]
public class AlertasController : ControllerBase
{
    private readonly AppDbContext _db;
    public AlertasController(AppDbContext db) => _db = db;

    /// <summary>Alertas do negócio: vencimentos próximos, atrasos, saldo projetado negativo e estoque baixo.</summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<AlertaDto>>> Listar([FromQuery] int diasVencimento = 7)
    {
        var hoje = DateOnly.FromDateTime(DateTime.Today);
        var limite = hoje.AddDays(diasVencimento);
        var alertas = new List<AlertaDto>();

        // Atrasados
        var atrasados = await _db.Transacoes
            .Where(t => !t.Simulado && t.Status == StatusTransacao.Atrasado)
            .Select(t => new { t.Tipo, t.Valor, t.Descricao, t.DataVencimento, t.Data })
            .ToListAsync();
        foreach (var t in atrasados)
        {
            var venc = t.DataVencimento ?? t.Data;
            alertas.Add(new AlertaDto(
                "atraso", SeveridadeAlerta.Critico,
                t.Tipo == TipoMovimento.Entrada ? "Recebimento atrasado" : "Pagamento atrasado",
                $"{t.Descricao ?? "Lançamento"} — {t.Valor:C} venceu em {venc:dd/MM/yyyy}.", venc));
        }

        // Vencendo nos próximos dias
        var proximos = await _db.Transacoes
            .Where(t => !t.Simulado && t.Status == StatusTransacao.Previsto
                && t.DataVencimento != null && t.DataVencimento >= hoje && t.DataVencimento <= limite)
            .Select(t => new { t.Tipo, t.Valor, t.Descricao, t.DataVencimento })
            .ToListAsync();
        foreach (var t in proximos)
        {
            alertas.Add(new AlertaDto(
                "vencimento", SeveridadeAlerta.Aviso,
                t.Tipo == TipoMovimento.Entrada ? "Recebimento a vencer" : "Pagamento a vencer",
                $"{t.Descricao ?? "Lançamento"} — {t.Valor:C} vence em {t.DataVencimento:dd/MM/yyyy}.", t.DataVencimento));
        }

        // Saldo projetado negativo (30 dias)
        var (saldoAtual, primeiroNegativo, menor) = await ProjetarAsync(hoje, 30);
        if (primeiroNegativo is not null)
        {
            alertas.Add(new AlertaDto(
                "saldo-negativo", SeveridadeAlerta.Critico, "Saldo projetado negativo",
                $"O saldo deve ficar negativo em {primeiroNegativo:dd/MM/yyyy} (menor saldo previsto: {menor:C}).",
                primeiroNegativo));
        }

        // Estoque baixo
        var estoqueBaixo = await _db.Produtos
            .Where(p => p.Ativo && p.QuantidadeAtual <= p.EstoqueMinimo)
            .Select(p => new { p.Nome, p.QuantidadeAtual, p.UnidadeMedida })
            .ToListAsync();
        foreach (var p in estoqueBaixo)
        {
            alertas.Add(new AlertaDto(
                "estoque", SeveridadeAlerta.Aviso, "Estoque baixo",
                $"{p.Nome} está com {p.QuantidadeAtual:0.##} {p.UnidadeMedida} em estoque.", null));
        }

        // ordena por severidade (crítico primeiro) e data
        var ordenado = alertas
            .OrderByDescending(a => a.Severidade)
            .ThenBy(a => a.Data ?? DateOnly.MaxValue)
            .ToList();
        return Ok(ordenado);
    }

    private async Task<(decimal saldo, DateOnly? negativo, decimal menor)> ProjetarAsync(DateOnly hoje, int dias)
    {
        var fim = hoje.AddDays(dias);
        var saldoInicial = await _db.Contas.SumAsync(c => (decimal?)c.SaldoInicial) ?? 0;
        var realizado = await _db.Transacoes.Where(t => !t.Simulado && t.Status == StatusTransacao.Realizado)
            .SumAsync(t => (decimal?)(t.Tipo == TipoMovimento.Entrada ? t.Valor : -t.Valor)) ?? 0;
        var saldo = saldoInicial + realizado;

        var abertas = await _db.Transacoes
            .Where(t => !t.Simulado && (t.Status == StatusTransacao.Previsto || t.Status == StatusTransacao.Atrasado))
            .Select(t => new { t.Tipo, t.Valor, t.Data, t.DataVencimento })
            .ToListAsync();

        var porDia = new Dictionary<DateOnly, decimal>();
        foreach (var t in abertas)
        {
            var ef = t.DataVencimento ?? t.Data;
            if (ef < hoje) ef = hoje;
            if (ef > fim) continue;
            var delta = t.Tipo == TipoMovimento.Entrada ? t.Valor : -t.Valor;
            porDia[ef] = (porDia.TryGetValue(ef, out var v) ? v : 0) + delta;
        }

        var acumulado = saldo;
        var menor = saldo;
        DateOnly? negativo = null;
        for (var d = hoje; d <= fim; d = d.AddDays(1))
        {
            if (porDia.TryGetValue(d, out var delta)) acumulado += delta;
            if (acumulado < menor) menor = acumulado;
            if (acumulado < 0 && negativo is null) negativo = d;
        }
        return (saldo, negativo, menor);
    }
}
