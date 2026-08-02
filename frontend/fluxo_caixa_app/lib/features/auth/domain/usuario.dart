/// Perfis de acesso (espelham os do backend).
class Perfil {
  static const admin = 'Admin';
  static const operador = 'Operador';
  static const visualizador = 'Visualizador';
}

/// Usuário autenticado.
class Usuario {
  final String email;
  final String nomeCompleto;
  final List<String> perfis;

  const Usuario({
    required this.email,
    required this.nomeCompleto,
    required this.perfis,
  });

  bool get isAdmin => perfis.contains(Perfil.admin);
  bool get podeEditar => perfis.contains(Perfil.admin) || perfis.contains(Perfil.operador);

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        email: json['email'] as String,
        nomeCompleto: (json['nomeCompleto'] ?? '') as String,
        perfis: (json['perfis'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );
}
