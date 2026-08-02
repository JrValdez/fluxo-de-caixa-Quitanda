import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  final container = ProviderContainer();
  // Restaura a sessão a partir do token salvo antes de exibir a UI.
  await container.read(authControllerProvider.notifier).restaurarSessao();

  runApp(UncontrolledProviderScope(container: container, child: const FluxoCaixaApp()));
}

class FluxoCaixaApp extends ConsumerWidget {
  const FluxoCaixaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: '${AppConfig.appName} — ${AppConfig.empresa}',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
