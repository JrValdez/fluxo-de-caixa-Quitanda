using FluxoCaixa.Domain.Common;
using FluxoCaixa.Domain.Enums;

namespace FluxoCaixa.Domain.Entities;

/// <summary>Categoria de receita/despesa, classificada conforme o DFC.</summary>
public class Categoria : BaseEntity
{
    public string Nome { get; set; } = string.Empty;
    public TipoCategoria Tipo { get; set; }
    public ClassificacaoCategoria Classificacao { get; set; } = ClassificacaoCategoria.Operacional;
    public bool Ativa { get; set; } = true;

    public ICollection<Subcategoria> Subcategorias { get; set; } = new List<Subcategoria>();
    public ICollection<Transacao> Transacoes { get; set; } = new List<Transacao>();
}
