using System.Text.Json;
using FluxoCaixa.Application.Common.Interfaces;
using FluxoCaixa.Domain.Common;
using FluxoCaixa.Domain.Entities;
using FluxoCaixa.Infrastructure.Identity;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace FluxoCaixa.Infrastructure.Persistence;

/// <summary>Contexto EF Core do sistema, incluindo as tabelas do Identity.</summary>
public class AppDbContext : IdentityDbContext<ApplicationUser, ApplicationRole, Guid>
{
    private readonly ICurrentUser? _currentUser;

    public AppDbContext(DbContextOptions<AppDbContext> options, ICurrentUser? currentUser = null) : base(options)
        => _currentUser = currentUser;

    public DbSet<Conta> Contas => Set<Conta>();
    public DbSet<Categoria> Categorias => Set<Categoria>();
    public DbSet<Subcategoria> Subcategorias => Set<Subcategoria>();
    public DbSet<ContraParte> ContraPartes => Set<ContraParte>();
    public DbSet<FormaPagamento> FormasPagamento => Set<FormaPagamento>();
    public DbSet<Transacao> Transacoes => Set<Transacao>();
    public DbSet<Recorrencia> Recorrencias => Set<Recorrencia>();
    public DbSet<Produto> Produtos => Set<Produto>();
    public DbSet<MovimentoEstoque> MovimentosEstoque => Set<MovimentoEstoque>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();

    public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        var logs = GerarAuditoria();
        if (logs.Count > 0) AuditLogs.AddRange(logs);
        return await base.SaveChangesAsync(cancellationToken);
    }

    /// <summary>Gera registros de auditoria a partir das mudanças rastreadas nas entidades de domínio.</summary>
    private List<AuditLog> GerarAuditoria()
    {
        var entries = ChangeTracker.Entries()
            .Where(e => e.Entity is BaseEntity && e.Entity is not AuditLog
                        && e.State is EntityState.Added or EntityState.Modified or EntityState.Deleted)
            .ToList();

        var usuario = _currentUser?.Email;
        var logs = new List<AuditLog>();
        foreach (var e in entries)
        {
            var acao = e.State switch
            {
                EntityState.Added => "Criar",
                EntityState.Modified => "Atualizar",
                _ => "Excluir"
            };
            var dados = e.State == EntityState.Deleted ? Serializar(e.OriginalValues) : Serializar(e.CurrentValues);
            logs.Add(new AuditLog
            {
                Entidade = e.Entity.GetType().Name,
                EntidadeId = ((BaseEntity)e.Entity).Id.ToString(),
                Acao = acao,
                Usuario = usuario,
                DadosDepois = dados
            });
        }
        return logs;
    }

    private static string Serializar(Microsoft.EntityFrameworkCore.ChangeTracking.PropertyValues values)
    {
        var dict = new Dictionary<string, object?>();
        foreach (var p in values.Properties)
        {
            if (p.Name is "CriadoEm" or "AtualizadoEm" or "CriadoPor" or "AtualizadoPor") continue;
            dict[p.Name] = values[p.Name];
        }
        return JsonSerializer.Serialize(dict);
    }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        // Precisão monetária para todos os decimais.
        foreach (var property in builder.Model.GetEntityTypes()
                     .SelectMany(t => t.GetProperties())
                     .Where(p => p.ClrType == typeof(decimal) || p.ClrType == typeof(decimal?)))
        {
            property.SetPrecision(18);
            property.SetScale(2);
        }

        builder.Entity<Conta>(e =>
        {
            e.Property(x => x.Nome).IsRequired().HasMaxLength(120);
            e.Property(x => x.Moeda).HasMaxLength(3);
        });

        builder.Entity<Categoria>(e =>
        {
            e.Property(x => x.Nome).IsRequired().HasMaxLength(120);
            e.HasMany(x => x.Subcategorias)
                .WithOne(x => x.Categoria)
                .HasForeignKey(x => x.CategoriaId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        builder.Entity<Subcategoria>(e => e.Property(x => x.Nome).IsRequired().HasMaxLength(120));

        builder.Entity<ContraParte>(e =>
        {
            e.Property(x => x.Nome).IsRequired().HasMaxLength(160);
            e.Property(x => x.Documento).HasMaxLength(30);
            e.Property(x => x.Email).HasMaxLength(160);
        });

        builder.Entity<FormaPagamento>(e => e.Property(x => x.Nome).IsRequired().HasMaxLength(80));

        builder.Entity<Transacao>(e =>
        {
            e.Property(x => x.Moeda).HasMaxLength(3);
            e.HasIndex(x => x.Data);
            e.HasIndex(x => x.Status);
            e.HasOne(x => x.Conta).WithMany(c => c.Transacoes)
                .HasForeignKey(x => x.ContaId).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(x => x.Categoria).WithMany(c => c.Transacoes)
                .HasForeignKey(x => x.CategoriaId).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(x => x.Subcategoria).WithMany(c => c.Transacoes)
                .HasForeignKey(x => x.SubcategoriaId).OnDelete(DeleteBehavior.SetNull);
            e.HasOne(x => x.ContraParte).WithMany(c => c.Transacoes)
                .HasForeignKey(x => x.ContraParteId).OnDelete(DeleteBehavior.SetNull);
            e.HasOne(x => x.FormaPagamento).WithMany(c => c.Transacoes)
                .HasForeignKey(x => x.FormaPagamentoId).OnDelete(DeleteBehavior.SetNull);
            e.HasOne(x => x.Recorrencia).WithMany(c => c.Transacoes)
                .HasForeignKey(x => x.RecorrenciaId).OnDelete(DeleteBehavior.SetNull);
        });

        builder.Entity<Produto>(e =>
        {
            e.Property(x => x.Nome).IsRequired().HasMaxLength(160);
            e.Property(x => x.Sku).HasMaxLength(60);
            e.Property(x => x.UnidadeMedida).HasMaxLength(10);
        });

        builder.Entity<MovimentoEstoque>(e =>
        {
            e.HasOne(x => x.Produto).WithMany(p => p.Movimentos)
                .HasForeignKey(x => x.ProdutoId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(x => x.Transacao).WithMany()
                .HasForeignKey(x => x.TransacaoId).OnDelete(DeleteBehavior.SetNull);
        });

        // Renomeia tabelas do Identity para nomes mais curtos.
        builder.Entity<ApplicationUser>().ToTable("usuarios");
        builder.Entity<ApplicationRole>().ToTable("perfis");
        builder.Entity<IdentityUserRole<Guid>>().ToTable("usuario_perfis");
        builder.Entity<IdentityUserClaim<Guid>>().ToTable("usuario_claims");
        builder.Entity<IdentityUserLogin<Guid>>().ToTable("usuario_logins");
        builder.Entity<IdentityRoleClaim<Guid>>().ToTable("perfil_claims");
        builder.Entity<IdentityUserToken<Guid>>().ToTable("usuario_tokens");
    }
}
