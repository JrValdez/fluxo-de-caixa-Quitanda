import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/transacao_models.dart';

class RecorrenciasRepository {
  final Dio _dio;
  RecorrenciasRepository(this._dio);

  Future<List<Recorrencia>> listar() async {
    final r = await _dio.get('/recorrencias');
    return (r.data as List).map((e) => Recorrencia.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> salvar(Map<String, dynamic> body, {String? id}) =>
      id == null ? _dio.post('/recorrencias', data: body) : _dio.put('/recorrencias/$id', data: body);

  Future<void> excluir(String id) => _dio.delete('/recorrencias/$id');

  Future<int> gerar() async {
    final r = await _dio.post('/recorrencias/gerar');
    return (r.data as Map<String, dynamic>)['geradas'] as int;
  }
}

final recorrenciasRepositoryProvider =
    Provider<RecorrenciasRepository>((ref) => RecorrenciasRepository(ref.watch(dioProvider)));

final recorrenciasProvider =
    FutureProvider.autoDispose<List<Recorrencia>>((ref) => ref.watch(recorrenciasRepositoryProvider).listar());
