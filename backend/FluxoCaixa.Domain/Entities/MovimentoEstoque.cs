using FluxoCaixa.Domain.Common;
using FluxoCaixa.Domain.Enums;

namespace FluxoCaixa.Domain.Entities;

/// <summary>Movimento de estoque, opcionalmente vinculado a uma transação de caixa.</summary>
public class MovimentoEstoque : BaseEntity
{
    public TipoMovimentoEstoque Tipo { get; set; }
    public decimal Quantidade { get; set; }
    public decimal CustoUnitario { get; set; }
    public DateOnly Data { get; set; }
    public string? Observacao { get; set; }

    public Guid ProdutoId { get; set; }
    public Produto? Produto { get; set; }

    public Guid? TransacaoId { get; set; }
    public Transacao? Transacao { get; set; }
}
