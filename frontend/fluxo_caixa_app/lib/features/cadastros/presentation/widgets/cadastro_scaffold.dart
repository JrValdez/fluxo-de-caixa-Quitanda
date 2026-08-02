import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/dialogos.dart';

/// Layout padrão das telas de cadastro: título, botão "Novo" e conteúdo.
class CadastroScaffold extends StatelessWidget {
  final String titulo;
  final VoidCallback? onNovo;
  final Widget child;
  const CadastroScaffold({super.key, required this.titulo, this.onNovo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(titulo,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.marrom)),
              const Spacer(),
              if (onNovo != null)
                FilledButton.icon(
                  onPressed: onNovo,
                  icon: const Icon(Icons.add),
                  label: const Text('Novo'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Diálogo de confirmação de exclusão.
Future<bool?> confirmarExclusao(BuildContext context, String nome) {
  return showDialog<bool>(
    context: context,
    builder: (dctx) => AlertDialog(
      title: const Text('Confirmar exclusão'),
      content: Text('Deseja realmente excluir "$nome"? Esta ação não pode ser desfeita.'),
      actions: [
        TextButton(onPressed: () => fecharDialogo(dctx, false), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.saida),
          onPressed: () => fecharDialogo(dctx, true),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
}

/// Mostra a mensagem de erro (ex.: 409 com registros vinculados) num SnackBar.
void mostrarErroExclusao(BuildContext context, Object erro) {
  var msg = 'Não foi possível excluir.';
  if (erro is DioException) {
    final data = erro.response?.data;
    if (data is Map && data['mensagem'] is String) msg = data['mensagem'] as String;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: AppColors.saida),
  );
}
