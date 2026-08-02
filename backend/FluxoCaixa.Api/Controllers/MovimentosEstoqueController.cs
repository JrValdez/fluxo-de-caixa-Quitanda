using FluxoCaixa.Application.Features.Estoque;
using FluxoCaixa.Domain.Entities;
using FluxoCaixa.Domain.Enums;
using FluxoCaixa.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FluxoCaixa.Api.Controllers;

[ApiController]
[Route("api/estoque/movimentos")]
[Authorize]
public class MovimentosEstoqueController : ControllerBase
{
    private readonly AppDbContext _db;
    public MovimentosEstoqueController(AppDbContext db) => _db = db;

    [HttpGet]
    public async Task<ActionResult<IEnumerable<MovimentoEstoqueDto>>> Listar([FromQuery] Guid? produtoId)
    {
        var q = _db.MovimentosEstoque.AsNoTracking().AsQueryable();
        if (produtoId is not null) q = q.Where(m => m.ProdutoId == produtoId);
        var lista = await q.OrderByDescending(m => m.Data).ThenByDescending(m => m.CriadoEm)
            .Select(m => new MovimentoEstoqueDto(
                m.Id, m.ProdutoId, m.Produto!.Nome, m.Tipo, m.Quantidade, m.CustoUnitario,
                m.Data, m.Observacao, m.TransacaoId, 0))
            .ToListAsync();
        return Ok(lista);
    }

    [HttpPost]
    [Authorize(Policy = "PodeEditar")]
    public async Task<ActionResult<MovimentoEstoqueDto>> Registrar([FromBody] MovimentoEstoqueInput input)
    {
        if (input.Quantidade <= 0 && input.Tipo != TipoMovimentoEstoque.Ajuste)
            return BadRequest(new { mensagem = "A quantidade deve ser maior que zero." });

        var produto = await _db.Produtos.FindAsync(input.ProdutoId);
        if (produto is null) return BadRequest(new { mensagem = "Produto inválido." });

        var atual = produto.QuantidadeAtual;
        decimal quantidadeMovida;

        switch (input.Tipo)
        {
            case TipoMovimentoEstoque.Entrada:
                var novaQtd = atual + input.Quantidade;
                // custo médio ponderado
                produto.CustoMedio = novaQtd > 0
                    ? Math.Round((atual * produto.CustoMedio + input.Quantidade * input.CustoUnitario) / novaQtd, 2)
                    : input.CustoUnitario;
                produto.QuantidadeAtual = novaQtd;
                quantidadeMovida = input.Quantidade;
                break;

            case TipoMovimentoEstoque.Saida:
                if (input.Quantidade > atual)
                    return BadRequest(new { mensagem = $"Estoque insuficiente. Disponível: {atual} {produto.UnidadeMedida}." });
                produto.QuantidadeAtual = atual - input.Quantidade;
                quantidadeMovida = input.Quantidade;
                break;

            default: // Ajuste: define o estoque para o valor informado
                quantidadeMovida = input.Quantidade - atual; // delta (pode ser negativo)
                produto.QuantidadeAtual = input.Quantidade;
                break;
        }
        produto.AtualizadoEm = DateTime.UtcNow;

        var movimento = new MovimentoEstoque
        {
            ProdutoId = produto.Id,
            Tipo = input.Tipo,
            Quantidade = quantidadeMovida,
            CustoUnitario = input.CustoUnitario,
            Data = input.Data,
            Observacao = input.Observacao
        };
        _db.MovimentosEstoque.Add(movimento);

        // Vínculo com o caixa (compra → saída; venda → entrada).
        if (input.GerarTransacao && input.Tipo != TipoMovimentoEstoque.Ajuste)
        {
            if (input.ContaId is null || input.CategoriaId is null)
                return BadRequest(new { mensagem = "Informe conta e categoria para gerar o lançamento no caixa." });

            var ehCompra = input.Tipo == TipoMovimentoEstoque.Entrada;
            var valor = input.ValorTransacao ??
                (ehCompra ? input.Quantidade * input.CustoUnitario : input.Quantidade * produto.PrecoVenda);

            var transacao = new Transacao
            {
                Tipo = ehCompra ? TipoMovimento.Saida : TipoMovimento.Entrada,
                Valor = Math.Round(valor, 2),
                Descricao = $"{(ehCompra ? "Compra" : "Venda")} de {input.Quantidade} {produto.UnidadeMedida} — {produto.Nome}",
                Data = input.Data,
                DataPagamento = input.Data,
                Status = StatusTransacao.Realizado,
                ContaId = input.ContaId.Value,
                CategoriaId = input.CategoriaId.Value,
                FormaPagamentoId = input.FormaPagamentoId,
                ContraParteId = input.ContraParteId
            };
            _db.Transacoes.Add(transacao);
            movimento.Transacao = transacao;
        }

        await _db.SaveChangesAsync();

        return Ok(new MovimentoEstoqueDto(
            movimento.Id, produto.Id, produto.Nome, movimento.Tipo, movimento.Quantidade,
            movimento.CustoUnitario, movimento.Data, movimento.Observacao, movimento.TransacaoId,
            produto.QuantidadeAtual));
    }
}
