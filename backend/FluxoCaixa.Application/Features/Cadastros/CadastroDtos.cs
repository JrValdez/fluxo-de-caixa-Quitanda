using FluxoCaixa.Domain.Enums;

namespace FluxoCaixa.Application.Features.Cadastros;

// ----- Contas -----
public record ContaDto(Guid Id, string Nome, TipoConta Tipo, string Moeda,
    decimal SaldoInicial, decimal SaldoAtual, bool Ativa, string? Observacao);

public record ContaInput(string Nome, TipoConta Tipo, string Moeda,
    decimal SaldoInicial, bool Ativa, string? Observacao);

// ----- Categorias / Subcategorias -----
public record SubcategoriaDto(Guid Id, string Nome, bool Ativa);

public record CategoriaDto(Guid Id, string Nome, TipoCategoria Tipo,
    ClassificacaoCategoria Classificacao, bool Ativa, IReadOnlyList<SubcategoriaDto> Subcategorias);

public record CategoriaInput(string Nome, TipoCategoria Tipo,
    ClassificacaoCategoria Classificacao, bool Ativa);

public record SubcategoriaInput(string Nome, bool Ativa);

// ----- Contrapartes -----
public record ContraParteDto(Guid Id, string Nome, TipoContraParte Tipo,
    string? Documento, string? Email, string? Telefone, bool Ativa);

public record ContraParteInput(string Nome, TipoContraParte Tipo,
    string? Documento, string? Email, string? Telefone, bool Ativa);

// ----- Formas de pagamento -----
public record FormaPagamentoDto(Guid Id, string Nome, bool Ativa);

public record FormaPagamentoInput(string Nome, bool Ativa);
