import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../auth/presentation/auth_controller.dart';
import '../extras/data/extras_repository.dart';

/// Item de navegação do menu lateral.
class NavItem {
  final String rota;
  final IconData icone;
  final String rotulo;
  final bool somenteAdmin;
  const NavItem(this.rota, this.icone, this.rotulo, {this.somenteAdmin = false});
}

const _navItems = <NavItem>[
  NavItem('/', Icons.dashboard_outlined, 'Painel'),
  NavItem('/alertas', Icons.notifications_outlined, 'Alertas'),
  NavItem('/relatorios', Icons.bar_chart, 'Relatórios'),
  NavItem('/projecoes', Icons.trending_up, 'Projeções'),
  NavItem('/transacoes', Icons.swap_vert, 'Transações'),
  NavItem('/conciliacao', Icons.compare_arrows, 'Conciliação'),
  NavItem('/recorrencias', Icons.event_repeat, 'Recorrências'),
  NavItem('/contas', Icons.account_balance_wallet_outlined, 'Contas'),
  NavItem('/categorias', Icons.category_outlined, 'Categorias'),
  NavItem('/contrapartes', Icons.people_outline, 'Clientes/Fornec.'),
  NavItem('/produtos', Icons.inventory_2_outlined, 'Estoque'),
  NavItem('/formas-pagamento', Icons.payments_outlined, 'Formas de pag.'),
  NavItem('/auditoria', Icons.shield_outlined, 'Auditoria', somenteAdmin: true),
  NavItem('/usuarios', Icons.manage_accounts_outlined, 'Usuários', somenteAdmin: true),
];

/// Layout principal com menu lateral (navigation rail) para telas largas.
class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authControllerProvider).usuario;
    final location = GoRouterState.of(context).uri.path;

    final itens = _navItems.where((i) => !i.somenteAdmin || (usuario?.isAdmin ?? false)).toList();
    var selectedIndex = itens.indexWhere((i) =>
        i.rota == '/' ? location == '/' : location.startsWith(i.rota));
    if (selectedIndex < 0) selectedIndex = 0;

    return Scaffold(
      body: Row(
        children: [
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: NavigationRail(
            extended: MediaQuery.of(context).size.width > 1100,
            minExtendedWidth: 220,
            selectedIndex: selectedIndex,
            onDestinationSelected: (i) => context.go(itens[i].rota),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      backgroundImage: AssetImage('assets/images/logo.jpg'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (MediaQuery.of(context).size.width > 1100)
                    const Text(AppConfig.empresa,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    tooltip: 'Sair',
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () async {
                      await ref.read(authControllerProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ),
              ),
            ),
            destinations: itens
                .map((i) => NavigationRailDestination(
                      icon: Icon(i.icone),
                      label: Text(i.rotulo),
                    ))
                .toList(),
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1, color: AppColors.borda),
          Expanded(
            child: Column(
              children: [
                _TopBar(usuario: usuario?.nomeCompleto ?? ''),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  final String usuario;
  const _TopBar({required this.usuario});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qtdAlertas = ref.watch(alertasProvider).asData?.value.length ?? 0;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.borda)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borda),
              boxShadow: AppColors.sombraCard,
            ),
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              backgroundImage: AssetImage('assets/images/logo.jpg'),
            ),
          ),
          const SizedBox(width: 12),
          const Text(AppConfig.appName,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.marrom)),
          const SizedBox(width: 8),
          const Text('· Quitandas da Badia',
              style: TextStyle(fontSize: 14, color: AppColors.marromSuave)),
          const Spacer(),
          IconButton(
            tooltip: 'Alertas',
            onPressed: () => context.go('/alertas'),
            icon: Badge(
              isLabelVisible: qtdAlertas > 0,
              label: Text('$qtdAlertas'),
              backgroundColor: AppColors.saida,
              child: const Icon(Icons.notifications_outlined, color: AppColors.marrom),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.account_circle, color: AppColors.terracota),
          const SizedBox(width: 8),
          Text(usuario, style: const TextStyle(color: AppColors.marrom)),
        ],
      ),
    );
  }
}
