import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formata a entrada como moeda enquanto o usuário digita: cada dígito conta
/// como centavo, sem precisar digitar vírgula ou ponto.
/// Ex.: "4" → 0,04 · "4500" → 45,00 · "123456" → 1.234,56
class MoedaInputFormatter extends TextInputFormatter {
  static final NumberFormat _fmt = NumberFormat('#,##0.00', 'pt_BR');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digitos = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }
    // limita a 13 dígitos (até ~99 bilhões) para evitar overflow
    final limitado = digitos.length > 13 ? digitos.substring(0, 13) : digitos;
    final valor = int.parse(limitado) / 100.0;
    final texto = _fmt.format(valor);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

/// Converte o texto formatado (ou digitado) de volta para double.
/// Trata "1.234,56", "45,00" e também "45.00"/"45".
double parseMoeda(String texto) {
  final digitos = texto.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitos.isEmpty) return 0;
  return int.parse(digitos) / 100.0;
}

/// Texto inicial já formatado para preencher um campo de moeda em edição.
/// Retorna vazio para valores zerados (campo começa limpo em cadastros novos).
String moedaInicial(double valor) {
  if (valor == 0) return '';
  return MoedaInputFormatter._fmt.format(valor);
}
