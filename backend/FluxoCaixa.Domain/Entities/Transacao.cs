using FluxoCaixa.Domain.Common;
using FluxoCaixa.Domain.Enums;

namespace FluxoCaixa.Domain.Entities;

/// <summary>
/// Movimentação financeira — entrada ou saída, prevista ou realizada.
/// É o registro central do fluxo de caixa.
/// </summary>
public class Transacao : BaseEntity
{
    public TipoMovimento Tipo { get; set; }
    public decimal Valor { get; set; }
    public string Moeda { get; set; } = "BRL";
    public string? Descricao { get; set; }

    /// <summary>Data de competência/lançamento.</summary>
    public DateOnly Data { get; set; }
    /// <summary>Vencimento (contas a pagar/receber). Null para lançamentos à vista.</summary>
    public DateOnly? DataVencimento { get; set; }
    /// <summary>Data em que efetivamente entrou/saiu do caixa.</summary>
    public DateOnly? DataPagamento { get; set; }

    public StatusTransacao Status { get; set; } = StatusTransacao.Previsto;

    public Guid ContaId { get; set; }
    public Conta? Conta { get; set; }

    public Guid CategoriaId { get; set; }
    public Categoria? Categoria { get; set; }

    public Guid? SubcategoriaId { get; set; }
    public Subcategoria? Subcategoria { get; set; }

    public Guid? ContraParteId { get; set; }
    public ContraParte? ContraParte { get; set; }

    public Guid? FormaPagamentoId { get; set; }
    public FormaPagamento? FormaPagamento { get; set; }

    public Guid? RecorrenciaId { get; set; }
    public Recorrencia? Recorrencia { get; set; }

    /// <summary>Indica que é um lançamento hipotético de simulação, não afeta o caixa real.</summary>
    public bool Simulado { get; set; }
}
