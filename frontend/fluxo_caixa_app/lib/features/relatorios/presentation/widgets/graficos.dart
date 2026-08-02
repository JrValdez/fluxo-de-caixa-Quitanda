import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../projecoes/domain/projecao_models.dart';
import '../../domain/relatorio_models.dart';

/// Card branco com título, usado como moldura dos gráficos.
class GraficoCard extends StatelessWidget {
  final String titulo;
  final Widget child;
  final double altura;
  const GraficoCard({super.key, required this.titulo, required this.child, this.altura = 260});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.marrom)),
            const SizedBox(height: 16),
            SizedBox(height: altura, child: child),
          ],
        ),
      ),
    );
  }
}

String _compacto(double v) {
  final abs = v.abs();
  if (abs >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (abs >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  return v.toStringAsFixed(0);
}

/// Gráfico de linha (CustomPaint) do saldo acumulado ao longo do período.
class SaldoLineChart extends StatelessWidget {
  final List<SaldoDiario> pontos;
  const SaldoLineChart({super.key, required this.pontos});

  @override
  Widget build(BuildContext context) {
    if (pontos.isEmpty) {
      return const Center(child: Text('Sem dados no período.', style: TextStyle(color: AppColors.marromSuave)));
    }
    return SizedBox.expand(child: CustomPaint(painter: _LinePainter(pontos)));
  }
}

class _LinePainter extends CustomPainter {
  final List<SaldoDiario> pontos;
  _LinePainter(this.pontos);

  @override
  void paint(Canvas canvas, Size size) {
    const padLeft = 52.0, padBottom = 22.0, padTop = 8.0, padRight = 8.0;
    final w = size.width - padLeft - padRight;
    final h = size.height - padBottom - padTop;
    if (w <= 0 || h <= 0) return;

    var minV = pontos.map((p) => p.saldoAcumulado).reduce((a, b) => a < b ? a : b);
    var maxV = pontos.map((p) => p.saldoAcumulado).reduce((a, b) => a > b ? a : b);
    if ((maxV - minV).abs() < 0.01) {
      final base = maxV.abs() < 1 ? 1.0 : maxV.abs() * 0.1;
      minV -= base;
      maxV += base;
    }
    final range = maxV - minV;

    final gridPaint = Paint()..color = AppColors.borda..strokeWidth = 1;
    final textStyle = const TextStyle(fontSize: 10, color: AppColors.marromSuave);

    // Linhas de grade horizontais + rótulos do eixo Y.
    const linhas = 4;
    for (var i = 0; i <= linhas; i++) {
      final y = padTop + h * i / linhas;
      canvas.drawLine(Offset(padLeft, y), Offset(padLeft + w, y), gridPaint);
      final valor = maxV - range * i / linhas;
      final tp = TextPainter(
        text: TextSpan(text: _compacto(valor), style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(padLeft - tp.width - 6, y - tp.height / 2));
    }

    double x(int i) => padLeft + (pontos.length == 1 ? w / 2 : w * i / (pontos.length - 1));
    double y(double v) => padTop + h * (1 - (v - minV) / range);

    // Área preenchida sob a linha.
    final area = Path()..moveTo(x(0), padTop + h);
    for (var i = 0; i < pontos.length; i++) {
      area.lineTo(x(i), y(pontos[i].saldoAcumulado));
    }
    area.lineTo(x(pontos.length - 1), padTop + h);
    area.close();
    canvas.drawPath(area, Paint()..color = AppColors.terracota.withValues(alpha: 0.12));

    // Linha do saldo.
    final linePaint = Paint()
      ..color = AppColors.terracota
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final linha = Path()..moveTo(x(0), y(pontos[0].saldoAcumulado));
    for (var i = 1; i < pontos.length; i++) {
      linha.lineTo(x(i), y(pontos[i].saldoAcumulado));
    }
    canvas.drawPath(linha, linePaint);

    // Rótulos de data (início, meio, fim).
    void dataLabel(int i) {
      if (i < 0 || i >= pontos.length) return;
      final d = pontos[i].data;
      final tp = TextPainter(
        text: TextSpan(text: '${d.day}/${d.month}', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((x(i) - tp.width / 2).clamp(padLeft, padLeft + w - tp.width), padTop + h + 6));
    }
    dataLabel(0);
    dataLabel(pontos.length ~/ 2);
    dataLabel(pontos.length - 1);
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => old.pontos != pontos;
}

/// Gráfico de linha da projeção de saldo, com linha do zero e destaque em vermelho abaixo dela.
class ProjecaoLineChart extends StatelessWidget {
  final List<ProjecaoPonto> pontos;
  const ProjecaoLineChart({super.key, required this.pontos});

  @override
  Widget build(BuildContext context) {
    if (pontos.isEmpty) {
      return const Center(child: Text('Sem dados.', style: TextStyle(color: AppColors.marromSuave)));
    }
    return SizedBox.expand(child: CustomPaint(painter: _ProjecaoPainter(pontos)));
  }
}

class _ProjecaoPainter extends CustomPainter {
  final List<ProjecaoPonto> pontos;
  _ProjecaoPainter(this.pontos);

  @override
  void paint(Canvas canvas, Size size) {
    const padLeft = 52.0, padBottom = 22.0, padTop = 8.0, padRight = 8.0;
    final w = size.width - padLeft - padRight;
    final h = size.height - padBottom - padTop;
    if (w <= 0 || h <= 0) return;

    var minV = pontos.map((p) => p.saldoProjetado).reduce((a, b) => a < b ? a : b);
    var maxV = pontos.map((p) => p.saldoProjetado).reduce((a, b) => a > b ? a : b);
    if (minV > 0) minV = 0; // sempre mostra a linha do zero
    if (maxV < 0) maxV = 0;
    if ((maxV - minV).abs() < 0.01) {
      maxV += 1;
      minV -= 1;
    }
    final range = maxV - minV;

    final textStyle = const TextStyle(fontSize: 10, color: AppColors.marromSuave);
    final gridPaint = Paint()..color = AppColors.borda..strokeWidth = 1;

    const linhas = 4;
    for (var i = 0; i <= linhas; i++) {
      final y = padTop + h * i / linhas;
      canvas.drawLine(Offset(padLeft, y), Offset(padLeft + w, y), gridPaint);
      final valor = maxV - range * i / linhas;
      final tp = TextPainter(text: TextSpan(text: _compacto(valor), style: textStyle), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(padLeft - tp.width - 6, y - tp.height / 2));
    }

    double x(int i) => padLeft + (pontos.length == 1 ? w / 2 : w * i / (pontos.length - 1));
    double y(double v) => padTop + h * (1 - (v - minV) / range);

    // Linha do zero destacada.
    final zeroY = y(0);
    canvas.drawLine(Offset(padLeft, zeroY), Offset(padLeft + w, zeroY),
        Paint()..color = AppColors.saida.withValues(alpha: 0.4)..strokeWidth = 1.2);

    // Área sob a linha (verde acima do zero, some abaixo).
    final area = Path()..moveTo(x(0), zeroY);
    for (var i = 0; i < pontos.length; i++) {
      area.lineTo(x(i), y(pontos[i].saldoProjetado));
    }
    area.lineTo(x(pontos.length - 1), zeroY);
    area.close();
    canvas.drawPath(area, Paint()..color = AppColors.terracota.withValues(alpha: 0.12));

    // Linha de projeção.
    final linePaint = Paint()
      ..color = AppColors.terracota
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final linha = Path()..moveTo(x(0), y(pontos[0].saldoProjetado));
    for (var i = 1; i < pontos.length; i++) {
      linha.lineTo(x(i), y(pontos[i].saldoProjetado));
    }
    canvas.drawPath(linha, linePaint);

    // Pontos que ficam negativos em vermelho.
    for (var i = 0; i < pontos.length; i++) {
      if (pontos[i].saldoProjetado < 0) {
        canvas.drawCircle(Offset(x(i), y(pontos[i].saldoProjetado)), 3, Paint()..color = AppColors.saida);
      }
    }

    void dataLabel(int i) {
      if (i < 0 || i >= pontos.length) return;
      final d = pontos[i].data;
      final tp = TextPainter(text: TextSpan(text: '${d.day}/${d.month}', style: textStyle), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset((x(i) - tp.width / 2).clamp(padLeft, padLeft + w - tp.width), padTop + h + 6));
    }
    dataLabel(0);
    dataLabel(pontos.length ~/ 2);
    dataLabel(pontos.length - 1);
  }

  @override
  bool shouldRepaint(covariant _ProjecaoPainter old) => old.pontos != pontos;
}

/// Gráfico de barras (CustomPaint): total por categoria.
class CategoriasBarChart extends StatelessWidget {
  final List<CategoriaResumo> dados;
  const CategoriasBarChart({super.key, required this.dados});

  @override
  Widget build(BuildContext context) {
    if (dados.isEmpty) {
      return const Center(child: Text('Sem dados no período.', style: TextStyle(color: AppColors.marromSuave)));
    }
    return SizedBox.expand(child: CustomPaint(painter: _BarPainter(dados.take(6).toList())));
  }
}

class _BarPainter extends CustomPainter {
  final List<CategoriaResumo> dados;
  _BarPainter(this.dados);

  @override
  void paint(Canvas canvas, Size size) {
    const padBottom = 40.0, padTop = 20.0;
    final h = size.height - padBottom - padTop;
    final w = size.width;
    if (h <= 0 || w <= 0 || dados.isEmpty) return;

    final maxTotal = dados.map((d) => d.total).reduce((a, b) => a > b ? a : b);
    final maxV = maxTotal <= 0 ? 1.0 : maxTotal;

    final slot = w / dados.length;
    final barW = (slot * 0.5).clamp(8.0, 48.0);

    for (var i = 0; i < dados.length; i++) {
      final d = dados[i];
      final cx = slot * i + slot / 2;
      final barH = h * (d.total / maxV);
      final top = padTop + (h - barH);
      final cor = d.tipo == 'Receita' ? AppColors.entrada : AppColors.saida;

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - barW / 2, top, barW, barH),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );
      canvas.drawRRect(rect, Paint()..color = cor);

      // Valor no topo da barra.
      final vtp = TextPainter(
        text: TextSpan(text: _compacto(d.total), style: TextStyle(fontSize: 10, color: cor, fontWeight: FontWeight.w600)),
        textDirection: TextDirection.ltr,
      )..layout();
      vtp.paint(canvas, Offset(cx - vtp.width / 2, top - vtp.height - 2));

      // Nome da categoria embaixo (truncado).
      final ntp = TextPainter(
        text: TextSpan(text: d.categoria, style: const TextStyle(fontSize: 9, color: AppColors.marromSuave)),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: slot - 4);
      ntp.paint(canvas, Offset(cx - ntp.width / 2, padTop + h + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) => old.dados != dados;
}
