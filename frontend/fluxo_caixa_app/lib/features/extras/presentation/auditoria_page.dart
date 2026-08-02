import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/estados.dart';
import '../data/extras_repository.dart';

class AuditoriaPage extends ConsumerWidget {
  const AuditoriaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(auditoriaProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Auditoria & Backup',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.marrom)),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _backup(context, ref),
              icon: const Icon(Icons.download_outlined),
              label: const Text('Baixar backup (JSON)'),
            ),
          ]),
          const SizedBox(height: 4),
          const Text('Registro de quem alterou o quê e quando.', style: TextStyle(color: AppColors.marromSuave)),
          const SizedBox(height: 16),
          Expanded(
            child: async.when(
              loading: () => const EsqueletoLista(linhas: 6),
              error: (e, _) => Center(child: Text('Erro ao carregar: $e')),
              data: (logs) => logs.isEmpty
                  ? const EstadoVazio(
                      icone: Icons.shield_outlined,
                      titulo: 'Nenhum registro de auditoria',
                      mensagem: 'As alterações feitas no sistema aparecerão aqui automaticamente.',
                    )
                  : Card(
                      child: SingleChildScrollView(
                        child: SizedBox(
                          width: double.infinity,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Data/Hora')),
                              DataColumn(label: Text('Ação')),
                              DataColumn(label: Text('Entidade')),
                              DataColumn(label: Text('Usuário')),
                            ],
                            rows: logs.map((l) => DataRow(cells: [
                                  DataCell(Text(Fmt.dataHora(l.criadoEm.toLocal()))),
                                  DataCell(_AcaoChip(l.acao)),
                                  DataCell(Text(l.entidade)),
                                  DataCell(Text(l.usuario ?? '—')),
                                ])).toList(),
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

  Future<void> _backup(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(extrasRepositoryProvider).baixarBackup();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao gerar backup.'), backgroundColor: AppColors.saida));
      }
    }
  }
}

class _AcaoChip extends StatelessWidget {
  final String acao;
  const _AcaoChip(this.acao);
  @override
  Widget build(BuildContext context) {
    final cor = switch (acao) {
      'Criar' => AppColors.entrada,
      'Excluir' => AppColors.saida,
      _ => AppColors.terracota,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: cor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(acao, style: TextStyle(color: cor, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}
