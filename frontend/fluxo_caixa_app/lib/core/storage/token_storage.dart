import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Armazena o token JWT de forma segura no navegador/dispositivo.
class TokenStorage {
  static const _kToken = 'fc_token';
  final FlutterSecureStorage _storage;

  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> salvar(String token) => _storage.write(key: _kToken, value: token);
  Future<String?> ler() => _storage.read(key: _kToken);
  Future<void> limpar() => _storage.delete(key: _kToken);
}
