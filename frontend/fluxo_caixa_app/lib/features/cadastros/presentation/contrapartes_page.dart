import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/estados.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/cadastros_repository.dart';
import '../domain/cadastro_models.dart';
import 'widgets/cadastro_scaffold.dart';
import '../../../core/utils/dialogos.dart';

class ContrapartesPage extends ConsumerWidget {
  const ContrapartesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(contrapartesProvider);
    final podeEditar = ref.watch(authControllerProvider).usuario?.podeEditar ?? false;

    return CadastroScaffold(
      titulo: 'Clientes / Fornecedores',
      onNovo: podeEditar ? () => _dialog(context, ref) : null,
      child: async.when(
        loading: () => const EsqueletoLista(linhas: 4),
        error: (e, _) => Center(child: Text('Erro ao carregar: $e')),
        data: (lista) => lista.isEmpty
            ? EstadoVazio(
                icone: Icons.people_outline,
                titulo: 'Nenhum cliente ou fornecedor',
                mensagem: 'Cadastre com quem você compra e para quem vende.',
                rotuloAcao: podeEditar ? 'Novo cadastro' : null,
                onAcao: podeEditar ? () => _dialog(context, ref) : null,
              )
            : Card(
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: double.infinity,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Nome')),
                        DataColumn(label: Text('Tipo')),
                        DataColumn(label: Text('Documento')),
                        DataColumn(label: Text('Contato')),
                        DataColumn(label: Text('Ações')),
                      ],
                      rows: lista
                          .map((c) => DataRow(cells: [
                                DataCell(Text(c.nome)),
                                DataCell(Text(tipoContraParteLabels[c.tipo] ?? c.tipo)),
                                DataCell(Text(c.documento ?? '—')),
                                DataCell(Text(c.email ?? c.telefone ?? '—')),
                                DataCell(podeEditar
                                    ? Row(children: [
                                        IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 20),
                                            onPressed: () => _dialog(context, ref, cp: c)),
                                        IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 20),
                                            onPressed: () => _excluir(context, ref, c)),
                                      ])
                                    : const SizedBox()),
                              ]))
                          .toList(),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _dialog(BuildContext context, WidgetRef ref, {ContraParte? cp}) async {
    await showDialog(context: context, builder: (_) => _ContraParteDialog(contraParte: cp));
    ref.invalidate(contrapartesProvider);
  }

  Future<void> _excluir(BuildContext context, WidgetRef ref, ContraParte c) async {
    if (await confirmarExclusao(context, c.nome) != true) return;
    try {
      await ref.read(cadastrosRepositoryProvider).excluirContraParte(c.id);
      ref.invalidate(contrapartesProvider);
    } catch (e) {
      if (context.mounted) mostrarErroExclusao(context, e);
    }
  }
}

class _ContraParteDialog extends ConsumerStatefulWidget {
  final ContraParte? contraParte;
  const _ContraParteDialog({this.contraParte});
  @override
  ConsumerState<_ContraParteDialog> createState() => _ContraParteDialogState();
}

class _ContraParteDialogState extends ConsumerState<_ContraParteDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nome, _doc, _email, _tel;
  late String _tipo;
  late bool _ativa;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final c = widget.contraParte;
    _nome = TextEditingController(text: c?.nome ?? '');
    _doc = TextEditingController(text: c?.documento ?? '');
    _email = TextEditingController(text: c?.email ?? '');
    _tel = TextEditingController(text: c?.telefone ?? '');
    _tipo = c?.tipo ?? 'Cliente';
    _ativa = c?.ativa ?? true;
  }

  @override
  void dispose() {
    _nome.dispose();
    _doc.dispose();
    _email.dispose();
    _tel.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      await ref.read(cadastrosRepositoryProvider).salvarContraParte({
        'nome': _nome.text.trim(),
        'tipo': _tipo,
        'documento': _doc.text.trim().isEmpty ? null : _doc.text.trim(),
        'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
        'telefone': _tel.text.trim().isEmpty ? null : _tel.text.trim(),
        'ativa': _ativa,
      }, id: widget.contraParte?.id);
      if (mounted) fecharDialogo(context);
    } catch (_) {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.contraParte == null ? 'Novo cadastro' : 'Editar cadastro'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: _nome,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _tipo,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: tipoContraParteLabels.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _tipo = v ?? 'Cliente'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _doc,
              decoration: const InputDecoration(labelText: 'Documento (CPF/CNPJ)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tel,
              decoration: const InputDecoration(labelText: 'Telefone'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Cadastro ativo'),
              value: _ativa,
              activeThumbColor: AppColors.terracota,
              onChanged: (v) => setState(() => _ativa = v),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => fecharDialogo(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _salvando ? null : _salvar,
          child: _salvando
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Salvar'),
        ),
      ],
    );
  }
}
