import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/estados.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/cadastros_repository.dart';
import '../domain/cadastro_models.dart';
import 'widgets/cadastro_scaffold.dart';
import '../../../core/utils/dialogos.dart';

class FormasPagamentoPage extends ConsumerWidget {
  const FormasPagamentoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(formasPagamentoProvider);
    final podeEditar = ref.watch(authControllerProvider).usuario?.podeEditar ?? false;

    return CadastroScaffold(
      titulo: 'Formas de pagamento',
      onNovo: podeEditar ? () => _dialog(context, ref) : null,
      child: async.when(
        loading: () => const EsqueletoLista(linhas: 4),
        error: (e, _) => Center(child: Text('Erro ao carregar: $e')),
        data: (lista) => lista.isEmpty
            ? EstadoVazio(
                icone: Icons.payments_outlined,
                titulo: 'Nenhuma forma de pagamento',
                mensagem: 'Cadastre as formas de receber e pagar: dinheiro, Pix, cartão...',
                rotuloAcao: podeEditar ? 'Nova forma' : null,
                onAcao: podeEditar ? () => _dialog(context, ref) : null,
              )
            : Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: lista.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.borda),
                  itemBuilder: (_, i) {
                    final f = lista[i];
                    return ListTile(
                      leading: const Icon(Icons.payments_outlined, color: AppColors.terracota),
                      title: Text(f.nome),
                      subtitle: Text(f.ativa ? 'Ativa' : 'Inativa'),
                      trailing: podeEditar
                          ? Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  onPressed: () => _dialog(context, ref, forma: f)),
                              IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  onPressed: () => _excluir(context, ref, f)),
                            ])
                          : null,
                    );
                  },
                ),
              ),
      ),
    );
  }

  Future<void> _dialog(BuildContext context, WidgetRef ref, {FormaPagamento? forma}) async {
    final ctrl = TextEditingController(text: forma?.nome ?? '');
    var ativa = forma?.ativa ?? true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(forma == null ? 'Nova forma de pagamento' : 'Editar'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: ctrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nome')),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ativa'),
              value: ativa,
              activeThumbColor: AppColors.terracota,
              onChanged: (v) => setState(() => ativa = v),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => fecharDialogo(context, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => fecharDialogo(context, true), child: const Text('Salvar')),
          ],
        ),
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await ref.read(cadastrosRepositoryProvider).salvarFormaPagamento(
        {'nome': ctrl.text.trim(), 'ativa': ativa},
        id: forma?.id,
      );
      ref.invalidate(formasPagamentoProvider);
    }
  }

  Future<void> _excluir(BuildContext context, WidgetRef ref, FormaPagamento f) async {
    if (await confirmarExclusao(context, f.nome) != true) return;
    try {
      await ref.read(cadastrosRepositoryProvider).excluirFormaPagamento(f.id);
      ref.invalidate(formasPagamentoProvider);
    } catch (e) {
      if (context.mounted) mostrarErroExclusao(context, e);
    }
  }
}
