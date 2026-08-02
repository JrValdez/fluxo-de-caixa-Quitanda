using FluxoCaixa.Domain.Common;
using FluxoCaixa.Domain.Enums;

namespace FluxoCaixa.Domain.Entities;

/// <summary>Conta/caixa onde os recursos ficam (banco, caixa físico, carteira digital).</summary>
public class Conta : BaseEntity
{
    public string Nome { get; set; } = string.Empty;
    public TipoConta Tipo { get; set; }
    public string Moeda { get; set; } = "BRL";
    public decimal SaldoInicial { get; set; }
    public bool Ativa { get; set; } = true;
    public string? Observacao { get; set; }

    public ICollection<Transacao> Transacoes { get; set; } = new List<Transacao>();
}
