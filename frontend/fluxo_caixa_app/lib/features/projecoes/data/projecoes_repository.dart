import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/projecao_models.dart';

class ProjecoesRepository {
  final Dio _dio;
  ProjecoesRepository(this._dio);

  Future<Projecao> caixa({required int dias, required bool incluirSimulacoes}) async {
    final r = await _dio.get('/projecoes/caixa', queryParameters: {
      'dias': dias,
      'incluirSimulacoes': incluirSimulacoes,
    });
    return Projecao.fromJson(r.data as Map<String, dynamic>);
  }

  Future<CapitalGiro> capitalGiro() async {
    final r = await _dio.get('/projecoes/capital-giro');
    return CapitalGiro.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<Simulacao>> simulacoes() async {
    final r = await _dio.get('/simulacoes');
    return (r.data as List).map((e) => Simulacao.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> criarSimulacao(Map<String, dynamic> body) => _dio.post('/simulacoes', data: body);
  Future<void> excluirSimulacao(String id) => _dio.delete('/simulacoes/$id');
  Future<void> limparSimulacoes() => _dio.delete('/simulacoes');
}

final projecoesRepositoryProvider =
    Provider<ProjecoesRepository>((ref) => ProjecoesRepository(ref.watch(dioProvider)));

/// Estado dos controles da tela de projeção.
class ProjecaoConfig {
  final int dias;
  final bool incluirSimulacoes;
  const ProjecaoConfig({this.dias = 13, this.incluirSimulacoes = false});
  ProjecaoConfig copyWith({int? dias, bool? incluirSimulacoes}) =>
      ProjecaoConfig(dias: dias ?? this.dias, incluirSimulacoes: incluirSimulacoes ?? this.incluirSimulacoes);
}

final projecaoConfigProvider = StateProvider<ProjecaoConfig>((ref) => const ProjecaoConfig());

final projecaoProvider = FutureProvider.autoDispose<Projecao>((ref) {
  final cfg = ref.watch(projecaoConfigProvider);
  return ref.watch(projecoesRepositoryProvider).caixa(dias: cfg.dias, incluirSimulacoes: cfg.incluirSimulacoes);
});

final capitalGiroProvider = FutureProvider.autoDispose<CapitalGiro>((ref) => ref.watch(projecoesRepositoryProvider).capitalGiro());

final simulacoesProvider = FutureProvider.autoDispose<List<Simulacao>>((ref) => ref.watch(projecoesRepositoryProvider).simulacoes());
