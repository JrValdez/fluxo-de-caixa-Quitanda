using System.Text;
using System.Text.Json;
using FluxoCaixa.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FluxoCaixa.Api.Controllers;

[ApiController]
[Route("api/admin")]
[Authorize(Policy = "SomenteAdmin")]
public class AdminController : ControllerBase
{
    private readonly AppDbContext _db;
    public AdminController(AppDbContext db) => _db = db;

    /// <summary>Backup completo dos dados de negócio em JSON (para download).</summary>
    [HttpGet("backup")]
    public async Task<IActionResult> Backup()
    {
        var dados = new
        {
            geradoEm = DateTime.UtcNow,
            contas = await _db.Contas.AsNoTracking().ToListAsync(),
            categorias = await _db.Categorias.AsNoTracking().ToListAsync(),
            subcategorias = await _db.Subcategorias.AsNoTracking().ToListAsync(),
            contrapartes = await _db.ContraPartes.AsNoTracking().ToListAsync(),
            formasPagamento = await _db.FormasPagamento.AsNoTracking().ToListAsync(),
            transacoes = await _db.Transacoes.AsNoTracking().ToListAsync(),
            recorrencias = await _db.Recorrencias.AsNoTracking().ToListAsync(),
            produtos = await _db.Produtos.AsNoTracking().ToListAsync(),
            movimentosEstoque = await _db.MovimentosEstoque.AsNoTracking().ToListAsync(),
        };

        var opcoes = new JsonSerializerOptions
        {
            WriteIndented = true,
            ReferenceHandler = System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles
        };
        var json = JsonSerializer.Serialize(dados, opcoes);
        var bytes = Encoding.UTF8.GetBytes(json);
        return File(bytes, "application/json", $"backup_fluxocaixa_{DateTime.Now:yyyyMMdd_HHmm}.json");
    }
}
