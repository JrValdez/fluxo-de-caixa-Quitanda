import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

class UsuarioAdmin {
  final String id;
  final String email;
  final String nomeCompleto;
  final bool ativo;
  final List<String> perfis;

  UsuarioAdmin({
    required this.id,
    required this.email,
    required this.nomeCompleto,
    required this.ativo,
    required this.perfis,
  });

  String get perfil => perfis.isNotEmpty ? perfis.first : '';

  factory UsuarioAdmin.fromJson(Map<String, dynamic> j) => UsuarioAdmin(
        id: j['id'] as String,
        email: j['email'] as String,
        nomeCompleto: (j['nomeCompleto'] ?? '') as String,
        ativo: j['ativo'] as bool,
        perfis: (j['perfis'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );
}

class UsuariosRepository {
  final Dio _dio;
  UsuariosRepository(this._dio);

  Future<List<UsuarioAdmin>> listar() async {
    final resp = await _dio.get('/usuarios');
    return (resp.data as List)
        .map((e) => UsuarioAdmin.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> criar({
    required String email,
    required String nomeCompleto,
    required String senha,
    required String perfil,
  }) =>
      _dio.post('/usuarios', data: {
        'email': email,
        'nomeCompleto': nomeCompleto,
        'senha': senha,
        'perfil': perfil,
      });

  Future<void> atualizar({
    required String id,
    required String nomeCompleto,
    required bool ativo,
    required String perfil,
  }) =>
      _dio.put('/usuarios/$id', data: {
        'nomeCompleto': nomeCompleto,
        'ativo': ativo,
        'perfil': perfil,
      });

  Future<void> redefinirSenha(String id, String novaSenha) =>
      _dio.post('/usuarios/$id/redefinir-senha', data: {'novaSenha': novaSenha});

  Future<void> excluir(String id) => _dio.delete('/usuarios/$id');
}

final usuariosRepositoryProvider =
    Provider<UsuariosRepository>((ref) => UsuariosRepository(ref.watch(dioProvider)));

final usuariosListProvider = FutureProvider.autoDispose<List<UsuarioAdmin>>((ref) {
  return ref.watch(usuariosRepositoryProvider).listar();
});
