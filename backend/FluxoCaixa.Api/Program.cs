using System.Text;
using FluxoCaixa.Domain.Constants;
using FluxoCaixa.Infrastructure;
using FluxoCaixa.Infrastructure.Auth;
using FluxoCaixa.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Serilog;

// Licença community do QuestPDF (gratuita) para geração de PDF.
QuestPDF.Settings.License = QuestPDF.Infrastructure.LicenseType.Community;

var builder = WebApplication.CreateBuilder(args);

// Logging
builder.Host.UseSerilog((context, cfg) => cfg
    .ReadFrom.Configuration(context.Configuration)
    .WriteTo.Console());

// Serviços de infraestrutura (EF Core, Identity, JWT token service)
builder.Services.AddInfrastructure(builder.Configuration);

// Rotina periódica de manutenção (atrasos + recorrências)
builder.Services.AddHostedService<FluxoCaixa.Api.Services.ManutencaoBackgroundService>();

// Usuário atual (para auditoria)
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<FluxoCaixa.Application.Common.Interfaces.ICurrentUser, FluxoCaixa.Api.Services.CurrentUser>();

// Autenticação JWT
var jwt = builder.Configuration.GetSection(JwtSettings.SectionName).Get<JwtSettings>()!;
builder.Services
    .AddAuthentication(options =>
    {
        options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    })
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwt.Emissor,
            ValidAudience = jwt.Audiencia,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt.Chave)),
            ClockSkew = TimeSpan.FromMinutes(1)
        };
    });

// Políticas de autorização por perfil
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("PodeEditar", p => p.RequireRole(Roles.Admin, Roles.Operador));
    options.AddPolicy("SomenteAdmin", p => p.RequireRole(Roles.Admin));
});

builder.Services
    .AddControllers()
    .AddJsonOptions(o =>
        o.JsonSerializerOptions.Converters.Add(new System.Text.Json.Serialization.JsonStringEnumConverter()));
builder.Services.AddEndpointsApiExplorer();

// Swagger com suporte a Bearer
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Fluxo de Caixa — Quitandas da Badia",
        Version = "v1",
        Description = "API de gestão de fluxo de caixa."
    });
    var scheme = new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Informe o token JWT.",
        Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
    };
    c.AddSecurityDefinition("Bearer", scheme);
    c.AddSecurityRequirement(new OpenApiSecurityRequirement { [scheme] = Array.Empty<string>() });
});

// CORS
const string CorsPolicy = "FluxoCaixaCors";
builder.Services.AddCors(options =>
{
    options.AddPolicy(CorsPolicy, policy =>
        policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
});

var app = builder.Build();

app.UseSerilogRequestLogging();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "Fluxo de Caixa v1"));
}

app.UseCors(CorsPolicy);
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapGet("/health", () => Results.Ok(new { status = "ok", app = "FluxoCaixa", hora = DateTime.UtcNow }))
   .AllowAnonymous();

// Migrations + seed
await DbSeeder.SeedAsync(app.Services);

app.Run();
