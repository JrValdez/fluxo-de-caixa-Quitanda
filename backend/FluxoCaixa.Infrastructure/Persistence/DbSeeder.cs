using FluxoCaixa.Domain.Constants;
using FluxoCaixa.Domain.Entities;
using FluxoCaixa.Infrastructure.Identity;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace FluxoCaixa.Infrastructure.Persistence;

/// <summary>Aplica migrations e cria dados iniciais (perfis, admin, formas de pagamento).</summary>
public static class DbSeeder
{
    public static async Task SeedAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var sp = scope.ServiceProvider;
        var logger = sp.GetRequiredService<ILogger<AppDbContext>>();
        var db = sp.GetRequiredService<AppDbContext>();
        var roleManager = sp.GetRequiredService<RoleManager<ApplicationRole>>();
        var userManager = sp.GetRequiredService<UserManager<ApplicationUser>>();
        var config = sp.GetRequiredService<IConfiguration>();

        await db.Database.MigrateAsync();

        // Perfis
        foreach (var role in Roles.Todos)
        {
            if (!await roleManager.RoleExistsAsync(role))
            {
                await roleManager.CreateAsync(new ApplicationRole(role));
                logger.LogInformation("Perfil criado: {Role}", role);
            }
        }

        // Usuário admin
        var adminEmail = config["Seed:AdminEmail"] ?? "junior322222@gmail.com";
        var adminSenha = config["Seed:AdminSenha"] ?? "123456";
        if (await userManager.FindByEmailAsync(adminEmail) is null)
        {
            var admin = new ApplicationUser
            {
                UserName = adminEmail,
                Email = adminEmail,
                EmailConfirmed = true,
                NomeCompleto = "Administrador",
                Ativo = true
            };
            var result = await userManager.CreateAsync(admin, adminSenha);
            if (result.Succeeded)
            {
                await userManager.AddToRoleAsync(admin, Roles.Admin);
                logger.LogInformation("Usuário admin criado: {Email}", adminEmail);
            }
            else
            {
                logger.LogError("Falha ao criar admin: {Erros}",
                    string.Join("; ", result.Errors.Select(e => e.Description)));
            }
        }

        // Formas de pagamento padrão
        if (!await db.FormasPagamento.AnyAsync())
        {
            db.FormasPagamento.AddRange(
                new FormaPagamento { Nome = "Dinheiro" },
                new FormaPagamento { Nome = "Pix" },
                new FormaPagamento { Nome = "Cartão de Débito" },
                new FormaPagamento { Nome = "Cartão de Crédito" },
                new FormaPagamento { Nome = "Boleto" },
                new FormaPagamento { Nome = "Transferência" });
            await db.SaveChangesAsync();
            logger.LogInformation("Formas de pagamento padrão criadas.");
        }
    }
}
