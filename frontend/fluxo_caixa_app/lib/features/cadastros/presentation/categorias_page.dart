import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/estados.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/cadastros_repository.dart';
import '../domain/cadastro_models.dart';
import 'widgets/cadastro_scaffold.dart';
import '../../../core/utils/dialogos.dart';

class CategoriasPage extends ConsumerWidget {
  const CategoriasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(categoriasProvider);
    final podeEditar = ref.watch(authControllerProvider).usuario?.podeEditar ?? false;

    return CadastroScaffold(
      titulo: 'Categorias',
      onNovo: podeEditar ? () => _dialogCategoria(context, ref) : null,
      child: async.when(
        loading: () => const EsqueletoLista(linhas: 4),
        error: (e, _) => Center(child: Text('Erro ao carregar: $e')),
        data: (cats) => cats.isEmpty
            ? EstadoVazio(
                icone: Icons.category_outlined,
                titulo: 'Nenhuma categoria cadastrada',
                mensagem: 'Separe receitas e despesas por categoria para organizar o fluxo.',
                rotuloAcao: podeEditar ? 'Nova categoria' : null,
                onAcao: podeEditar ? () => _dialogCategoria(context, ref) : null,
              )
            : ListView.separated(
                itemCount: cats.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _CategoriaCard(categoria: cats[i], podeEditar: podeEditar),
              ),
      ),
    );
  }

  static Future<void> _dialogCategoria(BuildContext context, WidgetRef ref, {Categoria? cat}) async {
    await showDialog(context: context, builder: (_) => _CategoriaDialog(categoria: cat));
    ref.invalidate(categoriasProvider);
  }
}

class _CategoriaCard extends ConsumerWidget {
  final Categoria categoria;
  final bool podeEditar;
  const _CategoriaCard({required this.categoria, required this.podeEditar});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReceita = categoria.tipo == 'Receita';
    return Card(
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: CircleAvatar(
          backgroundColor: (isReceita ? AppColors.entrada : AppColors.saida).withValues(alpha: 0.12),
          child: Icon(isReceita ? Icons.south_west : Icons.north_east,
              color: isReceita ? AppColors.entrada : AppColors.saida, size: 20),
        ),
        title: Text(categoria.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${tipoCategoriaLabels[categoria.tipo]} · ${classificacaoLabels[categoria.classificacao]}'),
        trailing: podeEditar
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => CategoriasPage._dialogCategoria(context, ref, cat: categoria)),
                IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _excluir(context, ref)),
                const SizedBox(width: 8),
                const Icon(Icons.expand_more),
              ])
            : const Icon(Icons.expand_more),
        children: [
          ...categoria.subcategorias.map((s) => ListTile(
                dense: true,
                contentPadding: const EdgeInsets.only(left: 72, right: 16),
                title: Text(s.nome),
                trailing: podeEditar
                    ? Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => _dialogSub(context, ref, sub: s)),
                        IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () => _excluirSub(context, ref, s)),
                      ])
                    : null,
              )),
          if (podeEditar)
            Padding(
              padding: const EdgeInsets.only(left: 72, bottom: 12, top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Adicionar subcategoria'),
                  onPressed: () => _dialogSub(context, ref),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _excluir(BuildContext context, WidgetRef ref) async {
    if (await confirmarExclusao(context, categoria.nome) != true) return;
    try {
      await ref.read(cadastrosRepositoryProvider).excluirCategoria(categoria.id);
      ref.invalidate(categoriasProvider);
    } catch (e) {
      if (context.mounted) mostrarErroExclusao(context, e);
    }
  }

  Future<void> _dialogSub(BuildContext context, WidgetRef ref, {Subcategoria? sub}) async {
    final ctrl = TextEditingController(text: sub?.nome ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(sub == null ? 'Nova subcategoria' : 'Editar subcategoria'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        actions: [
          TextButton(onPressed: () => fecharDialogo(dctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => fecharDialogo(dctx, true), child: const Text('Salvar')),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await ref.read(cadastrosRepositoryProvider).salvarSubcategoria(
        categoria.id,
        {'nome': ctrl.text.trim(), 'ativa': true},
        subId: sub?.id,
      );
      ref.invalidate(categoriasProvider);
    }
  }

  Future<void> _excluirSub(BuildContext context, WidgetRef ref, Subcategoria s) async {
    if (await confirmarExclusao(context, s.nome) != true) return;
    try {
      await ref.read(cadastrosRepositoryProvider).excluirSubcategoria(s.id);
      ref.invalidate(categoriasProvider);
    } catch (e) {
      if (context.mounted) mostrarErroExclusao(context, e);
    }
  }
}

class _CategoriaDialog extends ConsumerStatefulWidget {
  final Categoria? categoria;
  const _CategoriaDialog({this.categoria});
  @override
  ConsumerState<_CategoriaDialog> createState() => _CategoriaDialogState();
}

class _CategoriaDialogState extends ConsumerState<_CategoriaDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late String _tipo;
  late String _classificacao;
  late bool _ativa;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final c = widget.categoria;
    _nome = TextEditingController(text: c?.nome ?? '');
    _tipo = c?.tipo ?? 'Despesa';
    _classificacao = c?.classificacao ?? 'Operacional';
    _ativa = c?.ativa ?? true;
  }

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      await ref.read(cadastrosRepositoryProvider).salvarCategoria({
        'nome': _nome.text.trim(),
        'tipo': _tipo,
        'classificacao': _classificacao,
        'ativa': _ativa,
      }, id: widget.categoria?.id);
      if (mounted) fecharDialogo(context);
    } catch (_) {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.categoria == null ? 'Nova categoria' : 'Editar categoria'),
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
              items: tipoCategoriaLabels.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _tipo = v ?? 'Despesa'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _classificacao,
              decoration: const InputDecoration(labelText: 'Classificação (DFC)'),
              items: classificacaoLabels.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _classificacao = v ?? 'Operacional'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Categoria ativa'),
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
