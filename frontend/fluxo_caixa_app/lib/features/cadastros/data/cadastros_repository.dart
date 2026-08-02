import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/cadastro_models.dart';

class CadastrosRepository {
  final Dio _dio;
  CadastrosRepository(this._dio);

  // ---- Contas ----
  Future<List<Conta>> contas() async {
    final r = await _dio.get('/contas');
    return (r.data as List).map((e) => Conta.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> salvarConta(Map<String, dynamic> body, {String? id}) =>
      id == null ? _dio.post('/contas', data: body) : _dio.put('/contas/$id', data: body);

  Future<void> excluirConta(String id) => _dio.delete('/contas/$id');

  // ---- Categorias ----
  Future<List<Categoria>> categorias() async {
    final r = await _dio.get('/categorias');
    return (r.data as List).map((e) => Categoria.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> salvarCategoria(Map<String, dynamic> body, {String? id}) =>
      id == null ? _dio.post('/categorias', data: body) : _dio.put('/categorias/$id', data: body);

  Future<void> excluirCategoria(String id) => _dio.delete('/categorias/$id');

  Future<void> salvarSubcategoria(String categoriaId, Map<String, dynamic> body, {String? subId}) =>
      subId == null
          ? _dio.post('/categorias/$categoriaId/subcategorias', data: body)
          : _dio.put('/categorias/subcategorias/$subId', data: body);

  Future<void> excluirSubcategoria(String subId) => _dio.delete('/categorias/subcategorias/$subId');

  // ---- Contrapartes ----
  Future<List<ContraParte>> contrapartes() async {
    final r = await _dio.get('/contrapartes');
    return (r.data as List).map((e) => ContraParte.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> salvarContraParte(Map<String, dynamic> body, {String? id}) =>
      id == null ? _dio.post('/contrapartes', data: body) : _dio.put('/contrapartes/$id', data: body);

  Future<void> excluirContraParte(String id) => _dio.delete('/contrapartes/$id');

  // ---- Formas de pagamento ----
  Future<List<FormaPagamento>> formasPagamento() async {
    final r = await _dio.get('/formas-pagamento');
    return (r.data as List).map((e) => FormaPagamento.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> salvarFormaPagamento(Map<String, dynamic> body, {String? id}) =>
      id == null ? _dio.post('/formas-pagamento', data: body) : _dio.put('/formas-pagamento/$id', data: body);

  Future<void> excluirFormaPagamento(String id) => _dio.delete('/formas-pagamento/$id');
}

final cadastrosRepositoryProvider =
    Provider<CadastrosRepository>((ref) => CadastrosRepository(ref.watch(dioProvider)));

final contasProvider = FutureProvider.autoDispose((ref) => ref.watch(cadastrosRepositoryProvider).contas());
final categoriasProvider = FutureProvider.autoDispose((ref) => ref.watch(cadastrosRepositoryProvider).categorias());
final contrapartesProvider = FutureProvider.autoDispose((ref) => ref.watch(cadastrosRepositoryProvider).contrapartes());
final formasPagamentoProvider = FutureProvider.autoDispose((ref) => ref.watch(cadastrosRepositoryProvider).formasPagamento());
