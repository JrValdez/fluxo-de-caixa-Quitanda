import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/estados.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../relatorios/presentation/widgets/graficos.dart';
import '../data/projecoes_repository.dart';
import '../domain/projecao_models.dart';
import 'simulacao_dialog.dart';

class ProjecoesPage extends ConsumerWidget {
  const ProjecoesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(projecaoConfigProvider);
    final projecao = ref.watch(projecaoProvider);
    final podeEditar = ref.watch(authControllerProvider).usuario?.podeEditar ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Projeções & Simulações',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.marrom)),
          const SizedBox(height: 4),
          const Text('Projete o saldo futuro e simule cenários "e se" sem afetar o caixa real.',
              style: TextStyle(color: AppColors.marromSuave)),
          const SizedBox(height: 20),
          // Controles
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 7, label: Text('7 dias')),
                  ButtonSegment(value: 13, label: Text('13 dias')),
                  ButtonSegment(value: 30, label: Text('30 dias')),
                  ButtonSegment(value: 90, label: Text('90 dias')),
                ],
                selected: {cfg.dias},
                onSelectionChanged: (s) =>
                    ref.read(projecaoConfigProvider.notifier).state = cfg.copyWith(dias: s.first),
              ),
              FilterChip(
                label: const Text('Incluir simulações'),
                selected: cfg.incluirSimulacoes,
                selectedColor: AppColors.terracota.withValues(alpha: 0.18),
                checkmarkColor: AppColors.terracota,
                onSelected: (v) =>
                    ref.read(projecaoConfigProvider.notifier).state = cfg.copyWith(incluirSimulacoes: v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          projecao.when(
            loading: () => const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [EsqueletoKpi(), SizedBox(width: 16), EsqueletoKpi()]),
              SizedBox(height: 16),
              EsqueletoLista(linhas: 5),
            ]),
            error: (e, _) => Text('Erro ao carregar projeção: $e'),
            data: (p) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.primeiroDiaNegativo != null) _AlertaNegativo(p),
                Row(children: [
                  _MiniInfo('Saldo atual', Fmt.moeda(p.saldoInicial), AppColors.terracota),
                  const SizedBox(width: 16),
                  _MiniInfo('Menor saldo projetado', Fmt.moeda(p.menorSaldo),
                      p.menorSaldo < 0 ? AppColors.saida : AppColors.entrada),
                ]),
                const SizedBox(height: 16),
                GraficoCard(
                  titulo: 'Projeção de saldo — ${p.dias} dias',
                  altura: 300,
                  child: ProjecaoLineChart(pontos: p.pontos),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const _CapitalGiroSecao(),
          const SizedBox(height: 28),
          _SimuladorSecao(podeEditar: podeEditar),
        ],
      ),
    );
  }
}

class _AlertaNegativo extends StatelessWidget {
  final Projecao p;
  const _AlertaNegativo(this.p);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.saida.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.saida.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: AppColors.saida),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Atenção: o saldo projetado fica negativo em ${Fmt.data(p.primeiroDiaNegativo!)} '
            '(menor saldo: ${Fmt.moeda(p.menorSaldo)}). Antecipe recebimentos ou renegocie pagamentos.',
            style: const TextStyle(color: AppColors.saida, fontWeight: FontWeight.w500),
          ),
        ),
      ]),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color cor;
  const _MiniInfo(this.titulo, this.valor, this.cor);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borda),
        boxShadow: AppColors.sombraCard,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo, style: const TextStyle(color: AppColors.marromSuave, fontSize: 12)),
        const SizedBox(height: 4),
        Text(valor, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cor)),
      ]),
    );
  }
}

class _CapitalGiroSecao extends ConsumerWidget {
  const _CapitalGiroSecao();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cg = ref.watch(capitalGiroProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Capital de giro (mês atual)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.marrom)),
        const SizedBox(height: 12),
        cg.when(
          loading: () => const Wrap(spacing: 16, runSpacing: 16, children: [EsqueletoKpi(), EsqueletoKpi(), EsqueletoKpi()]),
          error: (e, _) => Text('Erro: $e'),
          data: (c) => Wrap(spacing: 16, runSpacing: 16, children: [
            _CgCard('Prazo médio recebimento', '${c.prazoMedioRecebimento.toStringAsFixed(0)} dias', Icons.call_received),
            _CgCard('Prazo médio pagamento', '${c.prazoMedioPagamento.toStringAsFixed(0)} dias', Icons.call_made),
            _CgCard('Giro de estoque', '${c.prazoMedioEstoque.toStringAsFixed(0)} dias', Icons.inventory_2_outlined),
            _CgCard('Ciclo operacional', '${c.cicloOperacional.toStringAsFixed(0)} dias', Icons.sync),
            _CgCard('Ciclo financeiro', '${c.cicloFinanceiro.toStringAsFixed(0)} dias', Icons.timelapse),
            _CgCard('Necessidade de capital de giro', Fmt.moeda(c.necessidadeCapitalGiro), Icons.savings_outlined),
          ]),
        ),
      ],
    );
  }
}

class _CgCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  const _CgCard(this.titulo, this.valor, this.icone);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borda),
          boxShadow: AppColors.sombraCard),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icone, color: AppColors.terracota, size: 22),
        const SizedBox(height: 10),
        Text(titulo, style: const TextStyle(color: AppColors.marromSuave, fontSize: 12)),
        const SizedBox(height: 4),
        Text(valor, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.marrom)),
      ]),
    );
  }
}

class _SimuladorSecao extends ConsumerWidget {
  final bool podeEditar;
  const _SimuladorSecao({required this.podeEditar});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sims = ref.watch(simulacoesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('Simulador "e se"',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.marrom)),
          const Spacer(),
          if (podeEditar) ...[
            TextButton.icon(
              onPressed: () => _limpar(context, ref),
              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
              label: const Text('Limpar'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => _adicionar(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Novo cenário'),
            ),
          ],
        ]),
        const SizedBox(height: 4),
        const Text('Lançamentos hipotéticos. Marque "Incluir simulações" acima para vê-los na projeção.',
            style: TextStyle(color: AppColors.marromSuave)),
        const SizedBox(height: 12),
        sims.when(
          loading: () => const EsqueletoLista(linhas: 2),
          error: (e, _) => Text('Erro: $e'),
          data: (lista) => lista.isEmpty
              ? Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: EstadoVazio(
                      icone: Icons.science_outlined,
                      titulo: 'Nenhum cenário simulado',
                      mensagem: 'Crie um lançamento hipotético e veja o impacto na projeção sem afetar o caixa real.',
                      rotuloAcao: podeEditar ? 'Novo cenário' : null,
                      onAcao: podeEditar ? () => _adicionar(context, ref) : null,
                    ),
                  ),
                )
              : Card(
                  child: Column(
                    children: lista.map((s) {
                      final cor = s.isEntrada ? AppColors.entrada : AppColors.saida;
                      return ListTile(
                        leading: Icon(s.isEntrada ? Icons.south_west : Icons.north_east, color: cor),
                        title: Text(s.descricao ?? s.categoriaNome),
                        subtitle: Text('${Fmt.data(s.data)} · ${s.contaNome}'),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('${s.isEntrada ? '+' : '-'} ${Fmt.moeda(s.valor)}',
                              style: TextStyle(color: cor, fontWeight: FontWeight.w600)),
                          if (podeEditar)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () async {
                                await ref.read(projecoesRepositoryProvider).excluirSimulacao(s.id);
                                _recarregar(ref);
                              },
                            ),
                        ]),
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _adicionar(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => const SimulacaoDialog());
    if (ok == true) _recarregar(ref);
  }

  Future<void> _limpar(BuildContext context, WidgetRef ref) async {
    await ref.read(projecoesRepositoryProvider).limparSimulacoes();
    _recarregar(ref);
  }

  void _recarregar(WidgetRef ref) {
    ref.invalidate(simulacoesProvider);
    ref.invalidate(projecaoProvider);
  }
}
