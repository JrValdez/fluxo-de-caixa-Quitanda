namespace FluxoCaixa.Domain.Constants;

/// <summary>Perfis de acesso do sistema.</summary>
public static class Roles
{
    /// <summary>Acesso total, inclusive gestão de usuários.</summary>
    public const string Admin = "Admin";
    /// <summary>Lança e edita dados financeiros, sem gestão de usuários.</summary>
    public const string Operador = "Operador";
    /// <summary>Somente leitura (contador/visualizador).</summary>
    public const string Visualizador = "Visualizador";

    public static readonly string[] Todos = { Admin, Operador, Visualizador };
}
