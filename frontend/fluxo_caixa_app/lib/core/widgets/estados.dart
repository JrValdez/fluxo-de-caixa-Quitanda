import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Bloco de skeleton com pulso suave — usado enquanto dados carregam
/// (guideline: skeleton em vez de spinner para conteúdo estruturado).
class Esqueleto extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadiusGeometry borderRadius;
  const Esqueleto({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<Esqueleto> createState() => _EsqueletoState();
}

class _EsqueletoState extends State<Esqueleto> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    // Respeita prefers-reduced-motion: sem pulso quando o usuário desativa animações.
    final reduzir = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (!reduzir) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
      ),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.borda.withValues(alpha: 0.6),
          borderRadius: widget.borderRadius,
        ),
      ),
    );
  }
}

/// Skeleton no formato de um card de KPI do painel.
class EsqueletoKpi extends StatelessWidget {
  const EsqueletoKpi({super.key});

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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Esqueleto(width: 36, height: 36, borderRadius: BorderRadius.all(Radius.circular(10))),
          SizedBox(height: 16),
          Esqueleto(width: 110, height: 12),
          SizedBox(height: 8),
          Esqueleto(width: 140, height: 22),
        ],
      ),
    );
  }
}

/// Skeleton de linhas de tabela/lista.
class EsqueletoLista extends StatelessWidget {
  final int linhas;
  const EsqueletoLista({super.key, this.linhas = 5});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var i = 0; i < linhas; i++) ...[
              const Row(children: [
                Esqueleto(width: 80, height: 14),
                SizedBox(width: 16),
                Expanded(child: Esqueleto(height: 14)),
                SizedBox(width: 16),
                Esqueleto(width: 90, height: 14),
              ]),
              if (i < linhas - 1) const SizedBox(height: 18),
            ],
          ],
        ),
      ),
    );
  }
}

/// Estado vazio com ícone, mensagem e ação opcional
/// (guideline: nunca deixar tela em branco; orientar o próximo passo).
class EstadoVazio extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String mensagem;
  final String? rotuloAcao;
  final VoidCallback? onAcao;

  const EstadoVazio({
    super.key,
    required this.icone,
    required this.titulo,
    required this.mensagem,
    this.rotuloAcao,
    this.onAcao,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.terracota.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icone, size: 40, color: AppColors.terracotaClaro),
          ),
          const SizedBox(height: 16),
          Text(titulo,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.marrom)),
          const SizedBox(height: 6),
          Text(mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.marromSuave)),
          if (rotuloAcao != null && onAcao != null) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAcao,
              icon: const Icon(Icons.add),
              label: Text(rotuloAcao!),
            ),
          ],
        ],
      ),
    );
  }
}
