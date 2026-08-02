using FluxoCaixa.Application.Common.Interfaces;
using FluxoCaixa.Infrastructure.Auth;
using FluxoCaixa.Infrastructure.Identity;
using FluxoCaixa.Infrastructure.Persistence;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace FluxoCaixa.Infrastructure;

/// <summary>Registro dos serviços da camada de infraestrutura.</summary>
public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration config)
    {
        var connectionString = config.GetConnectionString("Postgres")
            ?? throw new InvalidOperationException("ConnectionStrings:Postgres não configurada.");

        services.AddDbContext<AppDbContext>(options =>
            options.UseNpgsql(connectionString, npg => npg.MigrationsAssembly(typeof(AppDbContext).Assembly.FullName)));

        services.AddIdentityCore<ApplicationUser>(options =>
            {
                options.User.RequireUniqueEmail = true;
                options.Password.RequiredLength = 8;
                options.Password.RequireNonAlphanumeric = false;
            })
            .AddRoles<ApplicationRole>()
            .AddEntityFrameworkStores<AppDbContext>()
            .AddDefaultTokenProviders();

        services.Configure<JwtSettings>(opt => config.GetSection(JwtSettings.SectionName).Bind(opt));
        services.AddScoped<ITokenService, TokenService>();
        services.AddScoped<Services.ManutencaoService>();

        return services;
    }
}
