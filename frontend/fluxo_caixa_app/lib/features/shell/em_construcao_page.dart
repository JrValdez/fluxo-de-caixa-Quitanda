import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Placeholder para telas que serão implementadas nas próximas fases.
class EmConstrucaoPage extends StatelessWidget {
  final String titulo;
  const EmConstrucaoPage({super.key, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.construction, size: 64, color: AppColors.terracotaClaro),
          const SizedBox(height: 16),
          Text(titulo,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.marrom)),
          const SizedBox(height: 8),
          const Text('Em construção — disponível em breve.',
              style: TextStyle(color: AppColors.marromSuave)),
        ],
      ),
    );
  }
}
