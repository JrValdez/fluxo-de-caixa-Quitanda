import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/estados.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../cadastros/presentation/widgets/cadastro_scaffold.dart';
import '../data/transacoes_repository.dart';
import '../domain/transacao_models.dart';
import 'transacao_dialog.dart';

class TransacoesPage extends ConsumerWidget {
  const TransacoesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(transacoesProvider);
    final podeEditar = ref.watch(authControllerProvider).usuario?.podeEditar ?? false;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Transações',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.marrom)),
              const Spacer(),
              if (podeEditar)
                FilledButton.icon(
                  onPressed: () => _dialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Novo lançamento'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const _FiltroBar(),
          const SizedBox(height: 16),
          Expanded(
            child: async.when(
              loading: () => const EsqueletoLista(linhas: 6),
              error: (e, _) => Center(child: Text('Erro ao carregar: $e')),
              data: (txs) => txs.isEmpty
                  ? EstadoVazio(
                      icone: Icons.receipt_long_outlined,
                      titulo: 'Nenhuma transação encontrada',
                      mensagem: 'Ajuste os filtros ou registre o primeiro lançamento.',
                      rotuloAcao: podeEditar ? 'Novo lançamento' : null,
                      onAcao: podeEditar ? () => _dialog(context, ref) : null,
                    )
                  : Card(
                      child: SingleChildScrollView(
                        child: SizedBox(
                          width: double.infinity,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Data')),
                              DataColumn(label: Text('Descrição')),
                              DataColumn(label: Text('Categoria')),
                              DataColumn(label: Text('Conta')),
                              DataColumn(label: Text('Valor'), numeric: true),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Ações')),
                            ],
                            rows: txs.map((t) => _row(context, ref, t, podeEditar)).toList(),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _row(BuildContext context, WidgetRef ref, Transacao t, bool podeEditar) {
    final cor = t.isEntrada ? AppColors.entrada : AppColors.saida;
    return DataRow(cells: [
      DataCell(Text(Fmt.data(t.data))),
      DataCell(Text(t.descricao ?? '—')),
      DataCell(Text(t.categoriaNome)),
      DataCell(Text(t.contaNome)),
      DataCell(Text('${t.isEntrada ? '+' : '-'} ${Fmt.moeda(t.valor)}',
          style: TextStyle(color: cor, fontWeight: FontWeight.w600))),
      DataCell(_StatusChip(t.status)),
      DataCell(podeEditar
          ? Row(mainAxisSize: MainAxisSize.min, children: [
              if (t.status != 'Realizado')
                IconButton(
                  tooltip: 'Efetivar',
                  icon: const Icon(Icons.check_circle_outline, size: 20, color: AppColors.entrada),
                  onPressed: () => _efetivar(context, ref, t),
                ),
              IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _dialog(context, ref, transacao: t)),
              IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _excluir(context, ref, t)),
            ])
          : const SizedBox()),
    ]);
  }

  Future<void> _dialog(BuildContext context, WidgetRef ref, {Transacao? transacao}) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => TransacaoDialog(transacao: transacao));
    if (ok == true) _recarregar(ref);
  }

  Future<void> _efetivar(BuildContext context, WidgetRef ref, Transacao t) async {
    await ref.read(transacoesRepositoryProvider).efetivar(t.id);
    _recarregar(ref);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lançamento efetivado.')));
    }
  }

  Future<void> _excluir(BuildContext context, WidgetRef ref, Transacao t) async {
    if (await confirmarExclusao(context, t.descricao ?? 'esta transação') != true) return;
    try {
      await ref.read(transacoesRepositoryProvider).excluir(t.id);
      _recarregar(ref);
    } catch (e) {
      if (context.mounted) mostrarErroExclusao(context, e);
    }
  }

  void _recarregar(WidgetRef ref) {
    ref.invalidate(transacoesProvider);
    ref.invalidate(resumoProvider);
    ref.invalidate(agendaProvider);
  }
}

class _FiltroBar extends ConsumerWidget {
  const _FiltroBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtro = ref.watch(transacaoFiltroProvider);
    final notifier = ref.read(transacaoFiltroProvider.notifier);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 220,
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Buscar descrição',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onSubmitted: (v) => notifier.state = filtro.copyWith(texto: v),
          ),
        ),
        _DropFiltro(
          label: 'Tipo',
          valor: filtro.tipo,
          opcoes: tipoMovimentoLabels,
          onChanged: (v) => notifier.state = filtro.copyWith(tipo: v),
        ),
        _DropFiltro(
          label: 'Status',
          valor: filtro.status,
          opcoes: statusTransacaoLabels,
          onChanged: (v) => notifier.state = filtro.copyWith(status: v),
        ),
        TextButton.icon(
          onPressed: () => notifier.state = const TransacaoFiltro(),
          icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
          label: const Text('Limpar filtros'),
        ),
      ],
    );
  }
}

class _DropFiltro extends StatelessWidget {
  final String label;
  final String? valor;
  final Map<String, String> opcoes;
  final void Function(String?) onChanged;
  const _DropFiltro({required this.label, required this.valor, required this.opcoes, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: DropdownButtonFormField<String>(
        initialValue: valor,
        isDense: true,
        decoration: InputDecoration(labelText: label, isDense: true),
        items: [
          const DropdownMenuItem(value: null, child: Text('Todos')),
          ...opcoes.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final cor = switch (status) {
      'Realizado' => AppColors.entrada,
      'Previsto' => AppColors.alerta,
      'Atrasado' => AppColors.saida,
      _ => AppColors.marromSuave,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: cor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(statusTransacaoLabels[status] ?? status,
          style: TextStyle(color: cor, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}
