using FluxoCaixa.Domain.Common;
using FluxoCaixa.Domain.Entities;
using FluxoCaixa.Domain.Enums;
using FluxoCaixa.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace FluxoCaixa.Infrastructure.Services;

/// <summary>Rotinas de manutenção do fluxo: marcação de atrasos e geração de recorrências.</summary>
public class ManutencaoService
{
    private readonly AppDbContext _db;
    public ManutencaoService(AppDbContext db) => _db = db;

    /// <summary>Marca como "Atrasado" transações previstas cujo vencimento já passou.</summary>
    public async Task<int> MarcarAtrasadosAsync()
    {
        var hoje = DateOnly.FromDateTime(DateTime.Today);
        return await _db.Transacoes
            .Where(t => t.Status == StatusTransacao.Previsto
                        && t.DataVencimento != null && t.DataVencimento < hoje)
            .ExecuteUpdateAsync(s => s.SetProperty(t => t.Status, StatusTransacao.Atrasado));
    }

    /// <summary>Gera transações previstas a partir das recorrências ativas até a data limite.</summary>
    public async Task<int> GerarRecorrenciasAsync(DateOnly ate)
    {
        var recorrencias = await _db.Recorrencias.Where(r => r.Ativa).ToListAsync();
        var geradas = 0;

        foreach (var r in recorrencias)
        {
            var data = r.ProximaGeracao ?? r.DataInicio;
            while (data <= ate && (r.DataFim is null || data <= r.DataFim))
            {
                _db.Transacoes.Add(new Transacao
                {
                    Tipo = r.Tipo,
                    Valor = r.Valor,
                    Descricao = r.Descricao,
                    Data = data,
                    DataVencimento = data,
                    Status = StatusTransacao.Previsto,
                    ContaId = r.ContaId,
                    CategoriaId = r.CategoriaId,
                    ContraParteId = r.ContraParteId,
                    RecorrenciaId = r.Id
                });
                geradas++;
                data = RecorrenciaHelper.ProximaData(data, r.Frequencia);
            }
            r.ProximaGeracao = data;
        }

        if (geradas > 0) await _db.SaveChangesAsync();
        return geradas;
    }
}
