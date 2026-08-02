import 'package:intl/intl.dart';

/// Formatadores pt-BR para moeda e datas.
class Fmt {
  static final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final _data = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final _dataHora = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

  static String moeda(num v) => _moeda.format(v);
  static String data(DateTime d) => _data.format(d);
  static String dataHora(DateTime d) => _dataHora.format(d);
}
