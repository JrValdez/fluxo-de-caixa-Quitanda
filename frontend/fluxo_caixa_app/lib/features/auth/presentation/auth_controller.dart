import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/usuario.dart';

/// Estado da autenticação.
class AuthState {
  final bool carregando;
  final Usuario? usuario;
  final String? erro;

  const AuthState({this.carregando = false, this.usuario, this.erro});

  bool get autenticado => usuario != null;

  AuthState copyWith({bool? carregando, Usuario? usuario, String? erro, bool limparErro = false}) =>
      AuthState(
        carregando: carregando ?? this.carregando,
        usuario: usuario ?? this.usuario,
        erro: limparErro ? null : (erro ?? this.erro),
      );
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  AuthController(this._repo) : super(const AuthState());

  /// Restaura a sessão a partir do token salvo (chamado no startup).
  Future<void> restaurarSessao() async {
    state = state.copyWith(carregando: true);
    final usuario = await _repo.me();
    state = AuthState(usuario: usuario, carregando: false);
  }

  Future<bool> login(String email, String senha) async {
    state = state.copyWith(carregando: true, limparErro: true);
    try {
      final usuario = await _repo.login(email, senha);
      state = AuthState(usuario: usuario, carregando: false);
      return true;
    } catch (_) {
      state = const AuthState(erro: 'E-mail ou senha inválidos.', carregando: false);
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
