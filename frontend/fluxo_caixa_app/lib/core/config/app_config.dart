/// Configurações globais do aplicativo.
class AppConfig {
  /// URL base da API. Pode ser sobrescrita em build via --dart-define=API_URL=...
  static const String apiBaseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://localhost:5080');

  static const String appName = 'Fluxo de Caixa';
  static const String empresa = 'Quitandas da Badia';
}
