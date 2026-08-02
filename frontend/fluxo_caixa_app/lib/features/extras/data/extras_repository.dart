import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/utils/download_web.dart';
import '../domain/extras_models.dart';

class ExtrasRepository {
  final Dio _dio;
  ExtrasRepository(this._dio);

  Future<List<Alerta>> alertas() async {
    final r = await _dio.get('/alertas');
    return (r.data as List).map((e) => Alerta.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AuditLogItem>> auditoria() async {
    final r = await _dio.get('/auditoria', queryParameters: {'limite': 200});
    return (r.data as List).map((e) => AuditLogItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<LinhaExtrato>> importarExtrato(String contaId, String conteudo) async {
    final r = await _dio.post('/conciliacao/importar', data: {'contaId': contaId, 'conteudo': conteudo});
    return (r.data as List).map((e) => LinhaExtrato.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> conciliar(Map<String, dynamic> body) => _dio.post('/conciliacao/conciliar', data: body);

  Future<void> baixarBackup() async {
    final r = await _dio.get<List<int>>('/admin/backup', options: Options(responseType: ResponseType.bytes));
    baixarArquivo(r.data ?? const [], 'backup_fluxocaixa.json', 'application/json');
  }
}

final extrasRepositoryProvider = Provider<ExtrasRepository>((ref) => ExtrasRepository(ref.watch(dioProvider)));

final alertasProvider = FutureProvider.autoDispose<List<Alerta>>((ref) => ref.watch(extrasRepositoryProvider).alertas());
final auditoriaProvider = FutureProvider.autoDispose<List<AuditLogItem>>((ref) => ref.watch(extrasRepositoryProvider).auditoria());
