using FluxoCaixa.Domain.Common;

namespace FluxoCaixa.Domain.Entities;

/// <summary>Forma de pagamento/recebimento (dinheiro, pix, cartão, boleto...).</summary>
public class FormaPagamento : BaseEntity
{
    public string Nome { get; set; } = string.Empty;
    public bool Ativa { get; set; } = true;

    public ICollection<Transacao> Transacoes { get; set; } = new List<Transacao>();
}
