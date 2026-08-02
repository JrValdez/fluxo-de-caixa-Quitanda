using ClosedXML.Excel;
using FluxoCaixa.Domain.Enums;
using FluxoCaixa.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

namespace FluxoCaixa.Api.Controllers;

[ApiController]
[Route("api/relatorios/exportar")]
[Authorize]
public class ExportacaoController : ControllerBase
{
    private readonly AppDbContext _db;
    public ExportacaoController(AppDbContext db) => _db = db;

    private static (DateOnly de, DateOnly ate) Periodo(DateOnly? de, DateOnly? ate)
    {
        var hoje = DateOnly.FromDateTime(DateTime.Today);
        var inicio = de ?? new DateOnly(hoje.Year, hoje.Month, 1);
        var fim = ate ?? inicio.AddMonths(1).AddDays(-1);
        return (inicio, fim);
    }

    /// <summary>Exporta as transações do período em planilha Excel (.xlsx).</summary>
    [HttpGet("transacoes.xlsx")]
    public async Task<IActionResult> Transacoes([FromQuery] DateOnly? de, [FromQuery] DateOnly? ate)
    {
        var (inicio, fim) = Periodo(de, ate);
        var txs = await _db.Transacoes.AsNoTracking()
            .Where(t => !t.Simulado && t.Data >= inicio && t.Data <= fim)
            .OrderBy(t => t.Data)
            .Select(t => new
            {
                t.Data, t.Tipo, t.Descricao, Categoria = t.Categoria!.Nome, Conta = t.Conta!.Nome,
                t.Valor, t.Status, ContraParte = t.ContraParte != null ? t.ContraParte.Nome : ""
            })
            .ToListAsync();

        using var wb = new XLWorkbook();
        var ws = wb.Worksheets.Add("Transações");
        var cols = new[] { "Data", "Tipo", "Descrição", "Categoria", "Conta", "Cliente/Fornecedor", "Valor", "Status" };
        for (var i = 0; i < cols.Length; i++)
        {
            var cell = ws.Cell(1, i + 1);
            cell.Value = cols[i];
            cell.Style.Font.Bold = true;
            cell.Style.Fill.BackgroundColor = XLColor.FromHtml("#BE5E24");
            cell.Style.Font.FontColor = XLColor.White;
        }

        var row = 2;
        foreach (var t in txs)
        {
            ws.Cell(row, 1).Value = t.Data.ToDateTime(TimeOnly.MinValue);
            ws.Cell(row, 1).Style.DateFormat.Format = "dd/MM/yyyy";
            ws.Cell(row, 2).Value = t.Tipo == TipoMovimento.Entrada ? "Entrada" : "Saída";
            ws.Cell(row, 3).Value = t.Descricao ?? "";
            ws.Cell(row, 4).Value = t.Categoria;
            ws.Cell(row, 5).Value = t.Conta;
            ws.Cell(row, 6).Value = t.ContraParte;
            ws.Cell(row, 7).Value = t.Valor;
            ws.Cell(row, 7).Style.NumberFormat.Format = "#,##0.00";
            ws.Cell(row, 8).Value = t.Status.ToString();
            row++;
        }
        ws.Columns().AdjustToContents();

        using var ms = new MemoryStream();
        wb.SaveAs(ms);
        return File(ms.ToArray(),
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            $"transacoes_{inicio:yyyyMMdd}_{fim:yyyyMMdd}.xlsx");
    }

    /// <summary>Exporta o DRE simplificado do período em PDF.</summary>
    [HttpGet("dre.pdf")]
    public async Task<IActionResult> DrePdf([FromQuery] DateOnly? de, [FromQuery] DateOnly? ate)
    {
        var (inicio, fim) = Periodo(de, ate);
        var dados = await _db.Transacoes.AsNoTracking()
            .Where(t => !t.Simulado && t.Status == StatusTransacao.Realizado && t.Data >= inicio && t.Data <= fim)
            .Select(t => new { t.Categoria!.Classificacao, t.Tipo, t.Valor })
            .ToListAsync();

        var linhas = Enum.GetValues<ClassificacaoCategoria>().Select(g =>
        {
            var doGrupo = dados.Where(d => d.Classificacao == g).ToList();
            var rec = doGrupo.Where(d => d.Tipo == TipoMovimento.Entrada).Sum(d => d.Valor);
            var desp = doGrupo.Where(d => d.Tipo == TipoMovimento.Saida).Sum(d => d.Valor);
            return (Grupo: g.ToString(), Receitas: rec, Despesas: desp, Resultado: rec - desp);
        }).ToList();

        var totRec = linhas.Sum(l => l.Receitas);
        var totDesp = linhas.Sum(l => l.Despesas);
        var terracota = "#BE5E24";

        var pdf = Document.Create(doc =>
        {
            doc.Page(page =>
            {
                page.Margin(40);
                page.Size(PageSizes.A4);
                page.DefaultTextStyle(x => x.FontSize(11));

                page.Header().Column(col =>
                {
                    col.Item().Text("Quitandas da Badia").FontSize(18).Bold().FontColor(terracota);
                    col.Item().Text("DRE simplificado — Fluxo de caixa").FontSize(13).SemiBold();
                    col.Item().Text($"Período: {inicio:dd/MM/yyyy} a {fim:dd/MM/yyyy}").FontColor(Colors.Grey.Darken1);
                    col.Item().PaddingTop(8).LineHorizontal(1).LineColor(Colors.Grey.Lighten1);
                });

                page.Content().PaddingVertical(16).Table(table =>
                {
                    table.ColumnsDefinition(c =>
                    {
                        c.RelativeColumn(3);
                        c.RelativeColumn(2);
                        c.RelativeColumn(2);
                        c.RelativeColumn(2);
                    });

                    void Head(string t) => table.Cell().Background(terracota).Padding(6)
                        .Text(t).FontColor(Colors.White).Bold();
                    Head("Classificação");
                    Head("Receitas");
                    Head("Despesas");
                    Head("Resultado");

                    foreach (var l in linhas)
                    {
                        table.Cell().Padding(6).Text(l.Grupo);
                        table.Cell().Padding(6).Text(l.Receitas.ToString("C", new System.Globalization.CultureInfo("pt-BR")));
                        table.Cell().Padding(6).Text(l.Despesas.ToString("C", new System.Globalization.CultureInfo("pt-BR")));
                        table.Cell().Padding(6).Text(l.Resultado.ToString("C", new System.Globalization.CultureInfo("pt-BR")));
                    }

                    table.Cell().Background(Colors.Grey.Lighten3).Padding(6).Text("TOTAL").Bold();
                    table.Cell().Background(Colors.Grey.Lighten3).Padding(6).Text(totRec.ToString("C", new System.Globalization.CultureInfo("pt-BR"))).Bold();
                    table.Cell().Background(Colors.Grey.Lighten3).Padding(6).Text(totDesp.ToString("C", new System.Globalization.CultureInfo("pt-BR"))).Bold();
                    table.Cell().Background(Colors.Grey.Lighten3).Padding(6).Text((totRec - totDesp).ToString("C", new System.Globalization.CultureInfo("pt-BR"))).Bold();
                });

                page.Footer().AlignRight().Text($"Gerado em {DateTime.Now:dd/MM/yyyy HH:mm}").FontSize(9).FontColor(Colors.Grey.Darken1);
            });
        });

        var bytes = pdf.GeneratePdf();
        return File(bytes, "application/pdf", $"dre_{inicio:yyyyMMdd}_{fim:yyyyMMdd}.pdf");
    }
}
