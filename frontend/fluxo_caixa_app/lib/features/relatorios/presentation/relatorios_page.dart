import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/estados.dart';
import '../data/relatorios_repository.dart';
import '../domain/relatorio_models.dart';

const _grupoLabels = {
  'Operacional': 'Operacional',
  'Investimento': 'Investimento',
  'Financiamento': 'Financiamento',
};

class RelatoriosPage extends ConsumerWidget {
  const RelatoriosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dre = ref.watch(dreProvider);
    final kpis = ref.watch(kpisProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Relatórios',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.marrom)),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () => _exportar(context, () => ref.read(relatoriosRepositoryProvider).exportarTransacoesXlsx()),
              icon: const Icon(Icons.table_chart_outlined),
              label: const Text('Excel (transações)'),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () => _exportar(context, () => ref.read(relatoriosRepositoryProvider).exportarDrePdf()),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('PDF (DRE)'),
            ),
          ]),
          const SizedBox(height: 8),
          const Text('Período: mês atual', style: TextStyle(color: AppColors.marromSuave)),
          const SizedBox(height: 24),
          const Text('Indicadores', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.marrom)),
          const SizedBox(height: 12),
          kpis.when(
            loading: () => const Wrap(spacing: 16, runSpacing: 16, children: [
              EsqueletoKpi(), EsqueletoKpi(), EsqueletoKpi(), EsqueletoKpi(), EsqueletoKpi(), EsqueletoKpi(),
            ]),
            error: (e, _) => Text('Erro: $e'),
            data: (k) => Wrap(spacing: 16, runSpacing: 16, children: [
              _KpiTile('Ticket médio', Fmt.moeda(k.ticketMedio), Icons.receipt_long),
              _KpiTile('Prazo médio recebimento', '${k.prazoMedioRecebimento.toStringAsFixed(0)} dias', Icons.call_received),
              _KpiTile('Prazo médio pagamento', '${k.prazoMedioPagamento.toStringAsFixed(0)} dias', Icons.call_made),
              _KpiTile('Inadimplência', '${k.inadimplenciaPercent.toStringAsFixed(1)}%', Icons.warning_amber,
                  cor: k.inadimplenciaPercent > 0 ? AppColors.saida : AppColors.entrada),
              _KpiTile('Índice de liquidez', k.indiceLiquidez.toStringAsFixed(2), Icons.water_drop_outlined),
              _KpiTile('Transações no mês', '${k.qtdTransacoesPeriodo}', Icons.swap_vert),
            ]),
          ),
          const SizedBox(height: 32),
          const Text('DRE simplificado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.marrom)),
          const SizedBox(height: 12),
          dre.when(
            loading: () => const EsqueletoLista(linhas: 4),
            error: (e, _) => Text('Erro: $e'),
            data: (d) => _DreTabela(dre: d),
          ),
        ],
      ),
    );
  }

  Future<void> _exportar(BuildContext context, Future<void> Function() acao) async {
    try {
      await acao();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao exportar.'), backgroundColor: AppColors.saida),
        );
      }
    }
  }
}

class _DreTabela extends StatelessWidget {
  final Dre dre;
  const _DreTabela({required this.dre});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Classificação')),
              DataColumn(label: Text('Receitas'), numeric: true),
              DataColumn(label: Text('Despesas'), numeric: true),
              DataColumn(label: Text('Resultado'), numeric: true),
            ],
            rows: [
              ...dre.linhas.map((l) => DataRow(cells: [
                    DataCell(Text(_grupoLabels[l.grupo] ?? l.grupo)),
                    DataCell(Text(Fmt.moeda(l.receitas), style: const TextStyle(color: AppColors.entrada))),
                    DataCell(Text(Fmt.moeda(l.despesas), style: const TextStyle(color: AppColors.saida))),
                    DataCell(Text(Fmt.moeda(l.resultado),
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: l.resultado >= 0 ? AppColors.entrada : AppColors.saida))),
                  ])),
              DataRow(
                color: WidgetStatePropertyAll(AppColors.creme),
                cells: [
                  const DataCell(Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(Fmt.moeda(dre.totalReceitas), style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(Fmt.moeda(dre.totalDespesas), style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(Fmt.moeda(dre.resultadoLiquido),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: dre.resultadoLiquido >= 0 ? AppColors.entrada : AppColors.saida))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final Color? cor;
  const _KpiTile(this.titulo, this.valor, this.icone, {this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borda),
        boxShadow: AppColors.sombraCard,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icone, color: cor ?? AppColors.terracota),
        const SizedBox(height: 12),
        Text(titulo, style: const TextStyle(color: AppColors.marromSuave, fontSize: 13)),
        const SizedBox(height: 4),
        Text(valor, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cor ?? AppColors.marrom)),
      ]),
    );
  }
}
