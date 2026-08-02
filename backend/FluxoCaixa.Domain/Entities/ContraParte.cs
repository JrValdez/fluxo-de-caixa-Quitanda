using FluxoCaixa.Domain.Common;
using FluxoCaixa.Domain.Enums;

namespace FluxoCaixa.Domain.Entities;

/// <summary>Cliente ou fornecedor associado às transações.</summary>
public class ContraParte : BaseEntity
{
    public string Nome { get; set; } = string.Empty;
    public TipoContraParte Tipo { get; set; }
    public string? Documento { get; set; }
    public string? Email { get; set; }
    public string? Telefone { get; set; }
    public bool Ativa { get; set; } = true;

    public ICollection<Transacao> Transacoes { get; set; } = new List<Transacao>();
}
