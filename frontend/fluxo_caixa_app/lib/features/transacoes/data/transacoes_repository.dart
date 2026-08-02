import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/transacao_models.dart';

class TransacoesRepository {
  final Dio _dio;
  TransacoesRepository(this._dio);

  Future<List<Transacao>> listar({
    DateTime? de,
    DateTime? ate,
    String? tipo,
    String? status,
    String? contaId,
    String? categoriaId,
    String? texto,
  }) async {
    String? d(DateTime? x) => x?.toIso8601String().substring(0, 10);
    final params = <String, dynamic>{
      'de': ?d(de),
      'ate': ?d(ate),
      'tipo': ?tipo,
      'status': ?status,
      'contaId': ?contaId,
      'categoriaId': ?categoriaId,
      'texto': ?(texto != null && texto.isNotEmpty ? texto : null),
    };
    final r = await _dio.get('/transacoes', queryParameters: params);
    return (r.data as List).map((e) => Transacao.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Resumo> resumo({DateTime? de, DateTime? ate}) async {
    String? d(DateTime? x) => x?.toIso8601String().substring(0, 10);
    final r = await _dio.get('/transacoes/resumo', queryParameters: {
      'de': ?d(de),
      'ate': ?d(ate),
    });
    return Resumo.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<Transacao>> agenda({DateTime? ate}) async {
    final r = await _dio.get('/transacoes/agenda', queryParameters: {
      'ate': ?ate?.toIso8601String().substring(0, 10),
    });
    return (r.data as List).map((e) => Transacao.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> salvar(Map<String, dynamic> body, {String? id}) =>
      id == null ? _dio.post('/transacoes', data: body) : _dio.put('/transacoes/$id', data: body);

  Future<void> excluir(String id) => _dio.delete('/transacoes/$id');

  Future<void> efetivar(String id, {DateTime? dataPagamento}) => _dio.post(
        '/transacoes/$id/efetivar',
        data: {'dataPagamento': dataPagamento?.toIso8601String().substring(0, 10)},
      );
}

final transacoesRepositoryProvider =
    Provider<TransacoesRepository>((ref) => TransacoesRepository(ref.watch(dioProvider)));

/// Filtros aplicados na listagem de transações.
class TransacaoFiltro {
  final DateTime? de;
  final DateTime? ate;
  final String? tipo;
  final String? status;
  final String? contaId;
  final String? texto;
  const TransacaoFiltro({this.de, this.ate, this.tipo, this.status, this.contaId, this.texto});

  TransacaoFiltro copyWith({
    DateTime? de,
    DateTime? ate,
    Object? tipo = _sentinel,
    Object? status = _sentinel,
    Object? contaId = _sentinel,
    Object? texto = _sentinel,
  }) =>
      TransacaoFiltro(
        de: de ?? this.de,
        ate: ate ?? this.ate,
        tipo: tipo == _sentinel ? this.tipo : tipo as String?,
        status: status == _sentinel ? this.status : status as String?,
        contaId: contaId == _sentinel ? this.contaId : contaId as String?,
        texto: texto == _sentinel ? this.texto : texto as String?,
      );

  static const _sentinel = Object();
}

final transacaoFiltroProvider = StateProvider<TransacaoFiltro>((ref) => const TransacaoFiltro());

final transacoesProvider = FutureProvider.autoDispose<List<Transacao>>((ref) {
  final f = ref.watch(transacaoFiltroProvider);
  return ref.watch(transacoesRepositoryProvider).listar(
        de: f.de,
        ate: f.ate,
        tipo: f.tipo,
        status: f.status,
        contaId: f.contaId,
        texto: f.texto,
      );
});

final resumoProvider = FutureProvider.autoDispose<Resumo>((ref) => ref.watch(transacoesRepositoryProvider).resumo());

final agendaProvider = FutureProvider.autoDispose<List<Transacao>>((ref) => ref.watch(transacoesRepositoryProvider).agenda());
