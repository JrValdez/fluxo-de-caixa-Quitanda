using FluxoCaixa.Application.Features.Estoque;
using FluxoCaixa.Domain.Entities;
using FluxoCaixa.Domain.Enums;
using FluxoCaixa.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FluxoCaixa.Api.Controllers;

[ApiController]
[Route("api/produtos")]
[Authorize]
public class ProdutosController : ControllerBase
{
    private readonly AppDbContext _db;
    public ProdutosController(AppDbContext db) => _db = db;

    private static ProdutoDto Map(Produto p) => new(
        p.Id, p.Nome, p.Sku, p.UnidadeMedida, p.CustoMedio, p.PrecoVenda,
        p.QuantidadeAtual, p.EstoqueMinimo, p.Ativo,
        p.QuantidadeAtual <= p.EstoqueMinimo);

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ProdutoDto>>> Listar()
    {
        var lista = await _db.Produtos.AsNoTracking().OrderBy(p => p.Nome).ToListAsync();
        return Ok(lista.Select(Map));
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ProdutoDto>> Obter(Guid id)
    {
        var p = await _db.Produtos.FindAsync(id);
        return p is null ? NotFound() : Ok(Map(p));
    }

    [HttpPost]
    [Authorize(Policy = "PodeEditar")]
    public async Task<ActionResult<ProdutoDto>> Criar([FromBody] ProdutoInput input)
    {
        var p = new Produto
        {
            Nome = input.Nome.Trim(),
            Sku = input.Sku,
            UnidadeMedida = string.IsNullOrWhiteSpace(input.UnidadeMedida) ? "un" : input.UnidadeMedida.Trim(),
            PrecoVenda = input.PrecoVenda,
            EstoqueMinimo = input.EstoqueMinimo,
            Ativo = input.Ativo,
            CustoMedio = input.CustoMedio,
            QuantidadeAtual = input.QuantidadeInicial
        };
        _db.Produtos.Add(p);

        if (input.QuantidadeInicial > 0)
        {
            _db.MovimentosEstoque.Add(new MovimentoEstoque
            {
                ProdutoId = p.Id,
                Tipo = TipoMovimentoEstoque.Entrada,
                Quantidade = input.QuantidadeInicial,
                CustoUnitario = input.CustoMedio,
                Data = DateOnly.FromDateTime(DateTime.Today),
                Observacao = "Estoque inicial"
            });
        }

        await _db.SaveChangesAsync();
        return CreatedAtAction(nameof(Obter), new { id = p.Id }, Map(p));
    }

    [HttpPut("{id:guid}")]
    [Authorize(Policy = "PodeEditar")]
    public async Task<IActionResult> Atualizar(Guid id, [FromBody] ProdutoInput input)
    {
        var p = await _db.Produtos.FindAsync(id);
        if (p is null) return NotFound();
        // Quantidade/custo médio são geridos pelos movimentos (use "Ajuste"); aqui só o cadastro.
        p.Nome = input.Nome.Trim();
        p.Sku = input.Sku;
        p.UnidadeMedida = string.IsNullOrWhiteSpace(input.UnidadeMedida) ? "un" : input.UnidadeMedida.Trim();
        p.PrecoVenda = input.PrecoVenda;
        p.EstoqueMinimo = input.EstoqueMinimo;
        p.Ativo = input.Ativo;
        p.AtualizadoEm = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Policy = "PodeEditar")]
    public async Task<IActionResult> Excluir(Guid id)
    {
        var p = await _db.Produtos.FindAsync(id);
        if (p is null) return NotFound();
        if (await _db.MovimentosEstoque.AnyAsync(m => m.ProdutoId == id))
            return Conflict(new { mensagem = "Não é possível excluir: existem movimentos de estoque. Desative o produto." });
        _db.Produtos.Remove(p);
        await _db.SaveChangesAsync();
        return NoContent();
    }
}
