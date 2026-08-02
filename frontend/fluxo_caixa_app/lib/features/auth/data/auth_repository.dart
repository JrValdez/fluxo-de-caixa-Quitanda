import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/usuario.dart';

class AuthRepository {
  final Dio _dio;
  final TokenStorage _storage;

  AuthRepository(this._dio, this._storage);

  /// Faz login, persiste o token e retorna o usuário autenticado.
  Future<Usuario> login(String email, String senha) async {
    final resp = await _dio.post('/auth/login', data: {'email': email, 'senha': senha});
    final data = resp.data as Map<String, dynamic>;
    await _storage.salvar(data['token'] as String);
    return Usuario.fromJson(data);
  }

  /// Recupera o usuário atual a partir do token salvo.
  Future<Usuario?> me() async {
    final token = await _storage.ler();
    if (token == null || token.isEmpty) return null;
    try {
      final resp = await _dio.get('/auth/me');
      return Usuario.fromJson(resp.data as Map<String, dynamic>);
    } on DioException {
      await _storage.limpar();
      return null;
    }
  }

  Future<void> logout() => _storage.limpar();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider), ref.watch(tokenStorageProvider));
});
