import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Callback disparado quando a API responde 401 (token expirado/ inválido).
typedef OnUnauthorized = void Function();

final onUnauthorizedProvider = Provider<OnUnauthorized?>((ref) => null);

/// Cliente Dio configurado com base URL e injeção automática do token JWT.
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);

  final dio = Dio(BaseOptions(
    baseUrl: '${AppConfig.apiBaseUrl}/api',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.ler();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (e, handler) {
      if (e.response?.statusCode == 401) {
        ref.read(onUnauthorizedProvider)?.call();
      }
      handler.next(e);
    },
  ));

  return dio;
});
