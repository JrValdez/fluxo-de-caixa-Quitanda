using System.Globalization;
using FluxoCaixa.Application.Features.Extras;
using FluxoCaixa.Domain.Entities;
using FluxoCaixa.Domain.Enums;
using FluxoCaixa.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FluxoCaixa.Api.Controllers;

/// <summary>Importação de extrato bancário (CSV) e conciliação com lançamentos previstos.</summary>
[ApiController]
[Route("api/conciliacao")]
[Authorize]
public class ConciliacaoController : ControllerBase
{
    private readonly AppDbContext _db;
    public ConciliacaoController(AppDbContext db) => _db = db;

    /// <summary>
    /// Recebe o conteúdo de um CSV (data;descrição;valor — valor negativo = saída) e devolve as linhas
    /// já com a correspondência sugerida a lançamentos previstos/atrasados da conta.
    /// </summary>
    [HttpPost("importar")]
    [Authorize(Policy = "PodeEditar")]
    public async Task<ActionResult<IEnumerable<LinhaExtratoDto>>> Importar([FromBody] ImportarExtratoRequest req)
    {
        if (!await _db.Contas.AnyAsync(c => c.Id == req.ContaId))
            return BadRequest(new { mensagem = "Conta inválida." });

        var linhas = Parse(req.Conteudo);
        if (linhas.Count == 0)
            return BadRequest(new { mensagem = "Nenhuma linha válida encontrada. Use: data;descrição;valor (valor negativo = saída)." });

        var abertas = await _db.Transacoes
            .Where(t => !t.Simulado && t.ContaId == req.ContaId
                && (t.Status == StatusTransacao.Previsto || t.Status == StatusTransacao.Atrasado))
            .Select(t => new { t.Id, t.Tipo, t.Valor, t.Descricao, t.Data, t.DataVencimento })
            .ToListAsync();

        var usadas = new HashSet<Guid>();
        var resultado = new List<LinhaExtratoDto>();
        foreach (var (data, descricao, valor) in linhas)
        {
            var tipo = valor >= 0 ? TipoMovimento.Entrada : TipoMovimento.Saida;
            var abs = Math.Abs(valor);
            // procura correspondência: mesmo tipo, mesmo valor, vencimento/data a ±5 dias
            var match = abertas.FirstOrDefault(t =>
                !usadas.Contains(t.Id) && t.Tipo == tipo && t.Valor == abs
                && Math.Abs(((t.DataVencimento ?? t.Data).DayNumber) - data.DayNumber) <= 5);
            if (match is not null) usadas.Add(match.Id);
            resultado.Add(new LinhaExtratoDto(data, descricao, abs, tipo, match?.Id, match?.Descricao));
        }
        return Ok(resultado);
    }

    /// <summary>Concilia uma linha: efetiva o lançamento correspondente ou cria um novo já realizado.</summary>
    [HttpPost("conciliar")]
    [Authorize(Policy = "PodeEditar")]
    public async Task<IActionResult> Conciliar([FromBody] ConciliarRequest req)
    {
        if (req.TransacaoCorrespondenteId is not null)
        {
            var t = await _db.Transacoes.FindAsync(req.TransacaoCorrespondenteId.Value);
            if (t is null) return NotFound();
            t.Status = StatusTransacao.Realizado;
            t.DataPagamento = req.Data;
            t.AtualizadoEm = DateTime.UtcNow;
            await _db.SaveChangesAsync();
            return Ok(new { conciliado = true, criado = false });
        }

        var nova = new Transacao
        {
            Tipo = req.Tipo,
            Valor = req.Valor,
            Descricao = req.Descricao,
            Data = req.Data,
            DataPagamento = req.Data,
            Status = StatusTransacao.Realizado,
            ContaId = req.ContaId,
            CategoriaId = req.CategoriaId
        };
        _db.Transacoes.Add(nova);
        await _db.SaveChangesAsync();
        return Ok(new { conciliado = true, criado = true });
    }

    private static List<(DateOnly Data, string Descricao, decimal Valor)> Parse(string conteudo)
    {
        var linhas = new List<(DateOnly, string, decimal)>();
        if (string.IsNullOrWhiteSpace(conteudo)) return linhas;

        foreach (var bruta in conteudo.Replace("\r", "").Split('\n'))
        {
            var linha = bruta.Trim();
            if (linha.Length == 0) continue;
            var sep = linha.Contains(';') ? ';' : ',';
            var partes = linha.Split(sep);
            if (partes.Length < 3) continue;

            if (!TentarData(partes[0].Trim(), out var data)) continue; // ignora cabeçalho/linhas inválidas
            var descricao = partes[1].Trim().Trim('"');
            if (!TentarValor(partes[2].Trim(), out var valor)) continue;
            linhas.Add((data, descricao, valor));
        }
        return linhas;
    }

    private static bool TentarData(string s, out DateOnly data)
    {
        string[] formatos = { "yyyy-MM-dd", "dd/MM/yyyy", "dd-MM-yyyy", "MM/dd/yyyy" };
        foreach (var f in formatos)
        {
            if (DateOnly.TryParseExact(s, f, CultureInfo.InvariantCulture, DateTimeStyles.None, out data))
                return true;
        }
        return DateOnly.TryParse(s, new CultureInfo("pt-BR"), DateTimeStyles.None, out data);
    }

    private static bool TentarValor(string s, out decimal valor)
    {
        s = s.Replace("R$", "").Trim();
        // aceita 1.234,56 (pt-BR) e 1234.56 (invariante)
        if (decimal.TryParse(s, NumberStyles.Number, new CultureInfo("pt-BR"), out valor)) return true;
        return decimal.TryParse(s, NumberStyles.Number, CultureInfo.InvariantCulture, out valor);
    }
}
