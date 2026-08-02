import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/estados.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../relatorios/data/relatorios_repository.dart';
import '../../relatorios/presentation/widgets/graficos.dart';
import '../../transacoes/data/transacoes_repository.dart';
import '../../transacoes/domain/transacao_models.dart';

/// Painel inicial com KPIs do fluxo de caixa (gráficos chegam na Fase 4).
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authControllerProvider).usuario;
    final resumo = ref.watch(resumoProvider);
    final agenda = ref.watch(agendaProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Olá, ${usuario?.nomeCompleto ?? ''}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.marrom)),
          const SizedBox(height: 4),
          const Text('Resumo do fluxo de caixa da Quitandas da Badia (mês atual).',
              style: TextStyle(color: AppColors.marromSuave)),
          const SizedBox(height: 24),
          resumo.when(
            loading: () => const Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [EsqueletoKpi(), EsqueletoKpi(), EsqueletoKpi(), EsqueletoKpi(), EsqueletoKpi(), EsqueletoKpi()],
            ),
            error: (e, _) => Text('Erro ao carregar indicadores: $e'),
            data: (r) => Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _KpiCard(titulo: 'Saldo em contas', valor: Fmt.moeda(r.saldoTotalContas), icone: Icons.account_balance, cor: AppColors.terracota),
                _KpiCard(titulo: 'Entradas (mês)', valor: Fmt.moeda(r.entradasRealizadas), icone: Icons.south_west, cor: AppColors.entrada),
                _KpiCard(titulo: 'Saídas (mês)', valor: Fmt.moeda(r.saidasRealizadas), icone: Icons.north_east, cor: AppColors.saida),
                _KpiCard(
                  titulo: 'Resultado (mês)',
                  valor: Fmt.moeda(r.resultadoPeriodo),
                  icone: r.resultadoPeriodo >= 0 ? Icons.trending_up : Icons.trending_down,
                  cor: r.resultadoPeriodo >= 0 ? AppColors.entrada : AppColors.saida,
                ),
                _KpiCard(titulo: 'A receber', valor: Fmt.moeda(r.aReceber), icone: Icons.schedule, cor: AppColors.alerta,
                    destaque: r.receberAtrasado > 0 ? '${Fmt.moeda(r.receberAtrasado)} atrasado' : null),
                _KpiCard(titulo: 'A pagar', valor: Fmt.moeda(r.aPagar), icone: Icons.event_note, cor: AppColors.saida,
                    destaque: r.pagarAtrasado > 0 ? '${Fmt.moeda(r.pagarAtrasado)} atrasado' : null),
              ],
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(builder: (context, c) {
            final larguraCard = c.maxWidth > 900 ? (c.maxWidth - 16) / 2 : c.maxWidth;
            return Wrap(spacing: 16, runSpacing: 16, children: [
              SizedBox(width: larguraCard, child: const _SaldoChart()),
              SizedBox(width: larguraCard, child: const _CategoriasChart()),
            ]);
          }),
          const SizedBox(height: 24),
          const Text('Próximos vencimentos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.marrom)),
          const SizedBox(height: 12),
          agenda.when(
            loading: () => const EsqueletoLista(linhas: 3),
            error: (e, _) => Text('Erro: $e'),
            data: (itens) => itens.isEmpty
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: EstadoVazio(
                        icone: Icons.event_available_outlined,
                        titulo: 'Agenda em dia',
                        mensagem: 'Nenhuma conta a pagar ou receber em aberto.',
                      ),
                    ),
                  )
                : Card(
                    child: Column(
                      children: itens.take(8).map((t) => _AgendaTile(t)).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SaldoChart extends ConsumerWidget {
  const _SaldoChart();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(saldoDiarioProvider);
    return GraficoCard(
      titulo: 'Saldo ao longo do mês',
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (pontos) => SaldoLineChart(pontos: pontos),
      ),
    );
  }
}

class _CategoriasChart extends ConsumerWidget {
  const _CategoriasChart();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(porCategoriaProvider);
    return GraficoCard(
      titulo: 'Movimentação por categoria',
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (dados) => CategoriasBarChart(dados: dados),
      ),
    );
  }
}

class _AgendaTile extends StatelessWidget {
  final Transacao t;
  const _AgendaTile(this.t);

  @override
  Widget build(BuildContext context) {
    final cor = t.isEntrada ? AppColors.entrada : AppColors.saida;
    final atrasado = t.status == 'Atrasado';
    final venc = t.dataVencimento ?? t.data;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cor.withValues(alpha: 0.12),
        child: Icon(t.isEntrada ? Icons.south_west : Icons.north_east, color: cor, size: 20),
      ),
      title: Text(t.descricao ?? t.categoriaNome),
      subtitle: Text('Vence em ${Fmt.data(venc)}${atrasado ? ' · ATRASADO' : ''}',
          style: TextStyle(color: atrasado ? AppColors.saida : AppColors.marromSuave)),
      trailing: Text('${t.isEntrada ? '+' : '-'} ${Fmt.moeda(t.valor)}',
          style: TextStyle(color: cor, fontWeight: FontWeight.w600)),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final Color cor;
  final String? destaque;
  const _KpiCard({required this.titulo, required this.valor, required this.icone, required this.cor, this.destaque});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borda),
        boxShadow: AppColors.sombraCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: cor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icone, color: cor),
          ),
          const SizedBox(height: 16),
          Text(titulo, style: const TextStyle(color: AppColors.marromSuave)),
          const SizedBox(height: 4),
          Text(valor, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.marrom)),
          if (destaque != null) ...[
            const SizedBox(height: 4),
            Text(destaque!, style: const TextStyle(color: AppColors.saida, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}
