using FluxoCaixa.Domain.Common;
using FluxoCaixa.Domain.Enums;

namespace FluxoCaixa.Domain.Entities;

/// <summary>Modelo de lançamento que se repete automaticamente (aluguel, salários, assinaturas).</summary>
public class Recorrencia : BaseEntity
{
    public string Descricao { get; set; } = string.Empty;
    public FrequenciaRecorrencia Frequencia { get; set; }
    public TipoMovimento Tipo { get; set; }
    public decimal Valor { get; set; }
    public DateOnly DataInicio { get; set; }
    public DateOnly? DataFim { get; set; }
    public DateOnly? ProximaGeracao { get; set; }
    public bool Ativa { get; set; } = true;

    public Guid ContaId { get; set; }
    public Conta? Conta { get; set; }
    public Guid CategoriaId { get; set; }
    public Categoria? Categoria { get; set; }
    public Guid? ContraParteId { get; set; }
    public ContraParte? ContraParte { get; set; }

    public ICollection<Transacao> Transacoes { get; set; } = new List<Transacao>();
}
