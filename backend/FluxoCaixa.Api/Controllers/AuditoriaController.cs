using FluxoCaixa.Application.Features.Extras;
using FluxoCaixa.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FluxoCaixa.Api.Controllers;

[ApiController]
[Route("api/auditoria")]
[Authorize(Policy = "SomenteAdmin")]
public class AuditoriaController : ControllerBase
{
    private readonly AppDbContext _db;
    public AuditoriaController(AppDbContext db) => _db = db;

    [HttpGet]
    public async Task<ActionResult<IEnumerable<AuditLogDto>>> Listar([FromQuery] int limite = 200, [FromQuery] string? entidade = null)
    {
        var q = _db.AuditLogs.AsNoTracking().AsQueryable();
        if (!string.IsNullOrWhiteSpace(entidade)) q = q.Where(a => a.Entidade == entidade);
        var logs = await q.OrderByDescending(a => a.CriadoEm)
            .Take(Math.Clamp(limite, 1, 1000))
            .Select(a => new AuditLogDto(a.Id, a.Entidade, a.EntidadeId, a.Acao, a.Usuario, a.DadosDepois, a.CriadoEm))
            .ToListAsync();
        return Ok(logs);
    }
}
