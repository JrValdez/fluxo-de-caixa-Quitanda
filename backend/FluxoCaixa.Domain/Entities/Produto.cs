using FluxoCaixa.Domain.Common;

namespace FluxoCaixa.Domain.Entities;

/// <summary>Produto controlado em estoque (ex.: pão de queijo congelado).</summary>
public class Produto : BaseEntity
{
    public string Nome { get; set; } = string.Empty;
    public string? Sku { get; set; }
    public string UnidadeMedida { get; set; } = "un";
    public decimal CustoMedio { get; set; }
    public decimal PrecoVenda { get; set; }
    public decimal QuantidadeAtual { get; set; }
    public decimal EstoqueMinimo { get; set; }
    public bool Ativo { get; set; } = true;

    public ICollection<MovimentoEstoque> Movimentos { get; set; } = new List<MovimentoEstoque>();
}
