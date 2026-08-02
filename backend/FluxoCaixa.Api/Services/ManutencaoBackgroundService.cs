using FluxoCaixa.Infrastructure.Services;

namespace FluxoCaixa.Api.Services;

/// <summary>
/// Roda periodicamente: marca contas atrasadas e gera lançamentos recorrentes.
/// </summary>
public class ManutencaoBackgroundService : BackgroundService
{
    private readonly IServiceProvider _sp;
    private readonly ILogger<ManutencaoBackgroundService> _logger;
    private static readonly TimeSpan Intervalo = TimeSpan.FromHours(6);

    public ManutencaoBackgroundService(IServiceProvider sp, ILogger<ManutencaoBackgroundService> logger)
    {
        _sp = sp;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ExecutarAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Falha na rotina de manutenção.");
            }
            await Task.Delay(Intervalo, stoppingToken);
        }
    }

    private async Task ExecutarAsync(CancellationToken ct)
    {
        using var scope = _sp.CreateScope();
        var manutencao = scope.ServiceProvider.GetRequiredService<ManutencaoService>();
        var limite = DateOnly.FromDateTime(DateTime.Today).AddDays(31);
        var geradas = await manutencao.GerarRecorrenciasAsync(limite);
        var atrasadas = await manutencao.MarcarAtrasadosAsync();
        if (geradas > 0 || atrasadas > 0)
            _logger.LogInformation("Manutenção: {Geradas} recorrências geradas, {Atrasadas} marcadas como atrasadas.", geradas, atrasadas);
    }
}
