import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/estados.dart';
import '../../auth/domain/usuario.dart';
import '../data/usuarios_repository.dart';
import '../../../core/utils/dialogos.dart';

class UsuariosPage extends ConsumerWidget {
  const UsuariosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(usuariosListProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Usuários',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.marrom)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _abrirDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Novo usuário'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: async.when(
              loading: () => const EsqueletoLista(linhas: 3),
              error: (e, _) => Center(child: Text('Erro ao carregar: $e')),
              data: (usuarios) => Card(
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: double.infinity,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Nome')),
                        DataColumn(label: Text('E-mail')),
                        DataColumn(label: Text('Perfil')),
                        DataColumn(label: Text('Ativo')),
                        DataColumn(label: Text('Ações')),
                      ],
                      rows: usuarios
                          .map((u) => DataRow(cells: [
                                DataCell(Text(u.nomeCompleto)),
                                DataCell(Text(u.email)),
                                DataCell(_ChipPerfil(u.perfil)),
                                DataCell(Icon(
                                  u.ativo ? Icons.check_circle : Icons.cancel,
                                  color: u.ativo ? AppColors.entrada : AppColors.saida,
                                  size: 20,
                                )),
                                DataCell(Row(
                                  children: [
                                    IconButton(
                                      tooltip: 'Editar',
                                      icon: const Icon(Icons.edit_outlined, size: 20),
                                      onPressed: () => _abrirDialog(context, ref, usuario: u),
                                    ),
                                    IconButton(
                                      tooltip: 'Redefinir senha',
                                      icon: const Icon(Icons.key_outlined, size: 20),
                                      onPressed: () => _redefinirSenha(context, ref, u),
                                    ),
                                  ],
                                )),
                              ]))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirDialog(BuildContext context, WidgetRef ref, {UsuarioAdmin? usuario}) async {
    await showDialog(
      context: context,
      builder: (_) => _UsuarioDialog(usuario: usuario),
    );
    ref.invalidate(usuariosListProvider);
  }

  Future<void> _redefinirSenha(BuildContext context, WidgetRef ref, UsuarioAdmin u) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text('Redefinir senha de ${u.nomeCompleto}'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Nova senha (mín. 8 caracteres)'),
        ),
        actions: [
          TextButton(onPressed: () => fecharDialogo(dctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => fecharDialogo(dctx, true), child: const Text('Salvar')),
        ],
      ),
    );
    if (ok == true && ctrl.text.length >= 8) {
      await ref.read(usuariosRepositoryProvider).redefinirSenha(u.id, ctrl.text);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha redefinida.')),
        );
      }
    }
  }
}

class _ChipPerfil extends StatelessWidget {
  final String perfil;
  const _ChipPerfil(this.perfil);

  @override
  Widget build(BuildContext context) {
    final cor = switch (perfil) {
      Perfil.admin => AppColors.terracota,
      Perfil.operador => AppColors.entrada,
      _ => AppColors.marromSuave,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(perfil, style: TextStyle(color: cor, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

class _UsuarioDialog extends ConsumerStatefulWidget {
  final UsuarioAdmin? usuario;
  const _UsuarioDialog({this.usuario});

  @override
  ConsumerState<_UsuarioDialog> createState() => _UsuarioDialogState();
}

class _UsuarioDialogState extends ConsumerState<_UsuarioDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _email;
  final _senha = TextEditingController();
  late String _perfil;
  late bool _ativo;
  bool _salvando = false;
  String? _erro;

  bool get _edicao => widget.usuario != null;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.usuario?.nomeCompleto ?? '');
    _email = TextEditingController(text: widget.usuario?.email ?? '');
    _perfil = widget.usuario?.perfil.isNotEmpty == true ? widget.usuario!.perfil : Perfil.operador;
    _ativo = widget.usuario?.ativo ?? true;
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _salvando = true; _erro = null; });
    try {
      final repo = ref.read(usuariosRepositoryProvider);
      if (_edicao) {
        await repo.atualizar(
          id: widget.usuario!.id,
          nomeCompleto: _nome.text.trim(),
          ativo: _ativo,
          perfil: _perfil,
        );
      } else {
        await repo.criar(
          email: _email.text.trim(),
          nomeCompleto: _nome.text.trim(),
          senha: _senha.text,
          perfil: _perfil,
        );
      }
      if (mounted) fecharDialogo(context);
    } catch (e) {
      setState(() => _erro = 'Não foi possível salvar. Verifique os dados.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_edicao ? 'Editar usuário' : 'Novo usuário'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nome,
                decoration: const InputDecoration(labelText: 'Nome completo'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                enabled: !_edicao,
                decoration: const InputDecoration(labelText: 'E-mail'),
                validator: (v) => (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
              ),
              if (!_edicao) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _senha,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Senha (mín. 8 caracteres)'),
                  validator: (v) => (v == null || v.length < 8) ? 'Mínimo 8 caracteres' : null,
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _perfil,
                decoration: const InputDecoration(labelText: 'Perfil'),
                items: const [
                  DropdownMenuItem(value: Perfil.admin, child: Text('Administrador')),
                  DropdownMenuItem(value: Perfil.operador, child: Text('Operador')),
                  DropdownMenuItem(value: Perfil.visualizador, child: Text('Visualizador')),
                ],
                onChanged: (v) => setState(() => _perfil = v ?? Perfil.operador),
              ),
              if (_edicao) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Usuário ativo'),
                  value: _ativo,
                  activeThumbColor: AppColors.terracota,
                  onChanged: (v) => setState(() => _ativo = v),
                ),
              ],
              if (_erro != null) ...[
                const SizedBox(height: 8),
                Text(_erro!, style: const TextStyle(color: AppColors.saida)),
              ],
            ],
          ),
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
