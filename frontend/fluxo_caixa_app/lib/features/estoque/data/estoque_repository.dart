import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/estoque_models.dart';

class EstoqueRepository {
  final Dio _dio;
  EstoqueRepository(this._dio);

  Future<List<Produto>> produtos() async {
    final r = await _dio.get('/produtos');
    return (r.data as List).map((e) => Produto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> salvarProduto(Map<String, dynamic> body, {String? id}) =>
      id == null ? _dio.post('/produtos', data: body) : _dio.put('/produtos/$id', data: body);

  Future<void> excluirProduto(String id) => _dio.delete('/produtos/$id');

  Future<void> registrarMovimento(Map<String, dynamic> body) => _dio.post('/estoque/movimentos', data: body);

  Future<List<MovimentoEstoque>> movimentos(String produtoId) async {
    final r = await _dio.get('/estoque/movimentos', queryParameters: {'produtoId': produtoId});
    return (r.data as List).map((e) => MovimentoEstoque.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final estoqueRepositoryProvider = Provider<EstoqueRepository>((ref) => EstoqueRepository(ref.watch(dioProvider)));

final produtosProvider = FutureProvider.autoDispose<List<Produto>>((ref) => ref.watch(estoqueRepositoryProvider).produtos());

final movimentosProvider = FutureProvider.autoDispose.family<List<MovimentoEstoque>, String>(
    (ref, produtoId) => ref.watch(estoqueRepositoryProvider).movimentos(produtoId));
