using FluxoCaixa.Domain.Common;

namespace FluxoCaixa.Domain.Entities;

/// <summary>Detalhamento opcional de uma categoria.</summary>
public class Subcategoria : BaseEntity
{
    public string Nome { get; set; } = string.Empty;
    public bool Ativa { get; set; } = true;

    public Guid CategoriaId { get; set; }
    public Categoria? Categoria { get; set; }

    public ICollection<Transacao> Transacoes { get; set; } = new List<Transacao>();
}
