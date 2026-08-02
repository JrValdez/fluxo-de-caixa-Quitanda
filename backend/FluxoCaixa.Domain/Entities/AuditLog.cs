using FluxoCaixa.Domain.Common;

namespace FluxoCaixa.Domain.Entities;

/// <summary>Registro de auditoria: quem alterou o quê e quando.</summary>
public class AuditLog : BaseEntity
{
    public string Entidade { get; set; } = string.Empty;
    public string EntidadeId { get; set; } = string.Empty;
    public string Acao { get; set; } = string.Empty; // Criar/Atualizar/Excluir
    public string? Usuario { get; set; }
    public string? DadosAntes { get; set; }
    public string? DadosDepois { get; set; }
}
