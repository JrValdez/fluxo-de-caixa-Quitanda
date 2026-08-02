import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/estados.dart';
import '../data/extras_repository.dart';
import '../domain/extras_models.dart';

Color corSeveridade(String s) => switch (s) {
      'Critico' => AppColors.saida,
      'Aviso' => AppColors.alerta,
      _ => AppColors.terracota,
    };

IconData iconeAlerta(String tipo) => switch (tipo) {
      'atraso' => Icons.warning_amber_rounded,
      'vencimento' => Icons.event,
      'saldo-negativo' => Icons.trending_down,
      'estoque' => Icons.inventory_2_outlined,
      _ => Icons.notifications_outlined,
    };

class AlertasPage extends ConsumerWidget {
  const AlertasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(alertasProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Alertas',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.marrom)),
          const SizedBox(height: 4),
          const Text('Vencimentos, atrasos, saldo projetado negativo e estoque baixo.',
              style: TextStyle(color: AppColors.marromSuave)),
          const SizedBox(height: 16),
          Expanded(
            child: async.when(
              loading: () => const EsqueletoLista(linhas: 3),
              error: (e, _) => Center(child: Text('Erro ao carregar: $e')),
              data: (alertas) => alertas.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: const [
                        Icon(Icons.check_circle_outline, size: 56, color: AppColors.entrada),
                        SizedBox(height: 12),
                        Text('Tudo em ordem! Nenhum alerta no momento.',
                            style: TextStyle(color: AppColors.marromSuave)),
                      ]),
                    )
                  : ListView.separated(
                      itemCount: alertas.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _AlertaTile(alertas[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertaTile extends StatelessWidget {
  final Alerta a;
  const _AlertaTile(this.a);

  @override
  Widget build(BuildContext context) {
    final cor = corSeveridade(a.severidade);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cor.withValues(alpha: 0.12),
          child: Icon(iconeAlerta(a.tipo), color: cor),
        ),
        title: Text(a.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(a.descricao),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: cor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
          child: Text(a.severidade, style: TextStyle(color: cor, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
      ),
    );
  }
}
