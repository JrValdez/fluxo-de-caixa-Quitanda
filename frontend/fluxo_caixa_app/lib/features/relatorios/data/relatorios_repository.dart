import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/utils/download_web.dart';
import '../domain/relatorio_models.dart';

class RelatoriosRepository {
  final Dio _dio;
  RelatoriosRepository(this._dio);

  Future<List<SaldoDiario>> saldoDiario({DateTime? de, DateTime? ate}) async {
    final r = await _dio.get('/relatorios/saldo-diario', queryParameters: _periodo(de, ate));
    return (r.data as List).map((e) => SaldoDiario.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<CategoriaResumo>> porCategoria({DateTime? de, DateTime? ate}) async {
    final r = await _dio.get('/relatorios/categorias', queryParameters: _periodo(de, ate));
    return (r.data as List).map((e) => CategoriaResumo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Dre> dre({DateTime? de, DateTime? ate}) async {
    final r = await _dio.get('/relatorios/dre', queryParameters: _periodo(de, ate));
    return Dre.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Kpis> kpis({DateTime? de, DateTime? ate}) async {
    final r = await _dio.get('/relatorios/kpis', queryParameters: _periodo(de, ate));
    return Kpis.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> exportarTransacoesXlsx({DateTime? de, DateTime? ate}) => _baixar(
        '/relatorios/exportar/transacoes.xlsx', _periodo(de, ate),
        'transacoes.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

  Future<void> exportarDrePdf({DateTime? de, DateTime? ate}) => _baixar(
        '/relatorios/exportar/dre.pdf', _periodo(de, ate), 'dre.pdf', 'application/pdf');

  Future<void> _baixar(String path, Map<String, dynamic> params, String nome, String mime) async {
    final r = await _dio.get<List<int>>(path,
        queryParameters: params, options: Options(responseType: ResponseType.bytes));
    baixarArquivo(r.data ?? const [], nome, mime);
  }

  Map<String, dynamic> _periodo(DateTime? de, DateTime? ate) => {
        'de': ?de?.toIso8601String().substring(0, 10),
        'ate': ?ate?.toIso8601String().substring(0, 10),
      };
}

final relatoriosRepositoryProvider =
    Provider<RelatoriosRepository>((ref) => RelatoriosRepository(ref.watch(dioProvider)));

final saldoDiarioProvider = FutureProvider.autoDispose((ref) => ref.watch(relatoriosRepositoryProvider).saldoDiario());
final porCategoriaProvider = FutureProvider.autoDispose((ref) => ref.watch(relatoriosRepositoryProvider).porCategoria());
final dreProvider = FutureProvider.autoDispose((ref) => ref.watch(relatoriosRepositoryProvider).dre());
final kpisProvider = FutureProvider.autoDispose((ref) => ref.watch(relatoriosRepositoryProvider).kpis());
