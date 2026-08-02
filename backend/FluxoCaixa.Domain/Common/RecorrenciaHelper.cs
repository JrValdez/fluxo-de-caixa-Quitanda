using FluxoCaixa.Domain.Enums;

namespace FluxoCaixa.Domain.Common;

/// <summary>Cálculo da próxima data de um lançamento recorrente.</summary>
public static class RecorrenciaHelper
{
    public static DateOnly ProximaData(DateOnly atual, FrequenciaRecorrencia frequencia) => frequencia switch
    {
        FrequenciaRecorrencia.Diaria => atual.AddDays(1),
        FrequenciaRecorrencia.Semanal => atual.AddDays(7),
        FrequenciaRecorrencia.Quinzenal => atual.AddDays(15),
        FrequenciaRecorrencia.Mensal => atual.AddMonths(1),
        FrequenciaRecorrencia.Bimestral => atual.AddMonths(2),
        FrequenciaRecorrencia.Trimestral => atual.AddMonths(3),
        FrequenciaRecorrencia.Semestral => atual.AddMonths(6),
        FrequenciaRecorrencia.Anual => atual.AddYears(1),
        _ => atual.AddMonths(1)
    };
}
