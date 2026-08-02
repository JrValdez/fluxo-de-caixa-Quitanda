import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/cadastros/presentation/categorias_page.dart';
import '../features/cadastros/presentation/contas_page.dart';
import '../features/cadastros/presentation/contrapartes_page.dart';
import '../features/cadastros/presentation/formas_pagamento_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/estoque/presentation/produtos_page.dart';
import '../features/extras/presentation/alertas_page.dart';
import '../features/extras/presentation/auditoria_page.dart';
import '../features/extras/presentation/conciliacao_page.dart';
import '../features/projecoes/presentation/projecoes_page.dart';
import '../features/relatorios/presentation/relatorios_page.dart';
import '../features/shell/app_shell.dart';
import '../features/transacoes/presentation/recorrencias_page.dart';
import '../features/transacoes/presentation/transacoes_page.dart';
import '../features/usuarios/presentation/usuarios_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<AuthState>(ref.read(authControllerProvider));
  ref.onDispose(refresh.dispose);
  ref.listen(authControllerProvider, (_, next) => refresh.value = next);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final indoParaLogin = state.matchedLocation == '/login';
      if (!auth.autenticado) return indoParaLogin ? null : '/login';
      if (indoParaLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      ShellRoute(
        builder: (_, _, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const DashboardPage()),
          GoRoute(path: '/transacoes', builder: (_, _) => const TransacoesPage()),
          GoRoute(path: '/recorrencias', builder: (_, _) => const RecorrenciasPage()),
          GoRoute(path: '/relatorios', builder: (_, _) => const RelatoriosPage()),
          GoRoute(path: '/projecoes', builder: (_, _) => const ProjecoesPage()),
          GoRoute(path: '/contas', builder: (_, _) => const ContasPage()),
          GoRoute(path: '/categorias', builder: (_, _) => const CategoriasPage()),
          GoRoute(path: '/contrapartes', builder: (_, _) => const ContrapartesPage()),
          GoRoute(path: '/formas-pagamento', builder: (_, _) => const FormasPagamentoPage()),
          GoRoute(path: '/produtos', builder: (_, _) => const ProdutosPage()),
          GoRoute(path: '/alertas', builder: (_, _) => const AlertasPage()),
          GoRoute(path: '/conciliacao', builder: (_, _) => const ConciliacaoPage()),
          GoRoute(path: '/auditoria', builder: (_, _) => const AuditoriaPage()),
          GoRoute(path: '/usuarios', builder: (_, _) => const UsuariosPage()),
        ],
      ),
    ],
  );
});
