import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/moeda_input.dart';
import '../../../core/widgets/estados.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/cadastros_repository.dart';
import '../domain/cadastro_models.dart';
import 'widgets/cadastro_scaffold.dart';
import '../../../core/utils/dialogos.dart';

class ContasPage extends ConsumerWidget {
  const ContasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(contasProvider);
    final podeEditar = ref.watch(authControllerProvider).usuario?.podeEditar ?? false;

    return CadastroScaffold(
      titulo: 'Contas / Caixas',
      onNovo: podeEditar ? () => _dialog(context, ref) : null,
      child: async.when(
        loading: () => const EsqueletoLista(linhas: 4),
        error: (e, _) => Center(child: Text('Erro ao carregar: $e')),
        data: (contas) => contas.isEmpty
            ? EstadoVazio(
                icone: Icons.account_balance_wallet_outlined,
                titulo: 'Nenhuma conta cadastrada',
                mensagem: 'Cadastre onde o dinheiro fica: banco, caixa físico ou carteira digital.',
                rotuloAcao: podeEditar ? 'Nova conta' : null,
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
                        DataColumn(label: Text('Moeda')),
                        DataColumn(label: Text('Saldo atual'), numeric: true),
                        DataColumn(label: Text('Ativa')),
                        DataColumn(label: Text('Ações')),
                      ],
                      rows: contas
                          .map((c) => DataRow(cells: [
                                DataCell(Text(c.nome)),
                                DataCell(Text(tipoContaLabels[c.tipo] ?? c.tipo)),
                                DataCell(Text(c.moeda)),
                                DataCell(Text(Fmt.moeda(c.saldoAtual),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: c.saldoAtual < 0 ? AppColors.saida : AppColors.marrom))),
                                DataCell(Icon(c.ativa ? Icons.check_circle : Icons.cancel,
                                    color: c.ativa ? AppColors.entrada : AppColors.saida, size: 20)),
                                DataCell(podeEditar
                                    ? Row(children: [
                                        IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 20),
                                            onPressed: () => _dialog(context, ref, conta: c)),
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

  Future<void> _dialog(BuildContext context, WidgetRef ref, {Conta? conta}) async {
    await showDialog(context: context, builder: (_) => _ContaDialog(conta: conta));
    ref.invalidate(contasProvider);
  }

  Future<void> _excluir(BuildContext context, WidgetRef ref, Conta c) async {
    final ok = await confirmarExclusao(context, c.nome);
    if (ok != true) return;
    try {
      await ref.read(cadastrosRepositoryProvider).excluirConta(c.id);
      ref.invalidate(contasProvider);
    } catch (e) {
      if (context.mounted) mostrarErroExclusao(context, e);
    }
  }
}

class _ContaDialog extends ConsumerStatefulWidget {
  final Conta? conta;
  const _ContaDialog({this.conta});
  @override
  ConsumerState<_ContaDialog> createState() => _ContaDialogState();
}

class _ContaDialogState extends ConsumerState<_ContaDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _saldo;
  late final TextEditingController _obs;
  late String _tipo;
  late String _moeda;
  late bool _ativa;
  bool _salvando = false;

  bool get _edicao => widget.conta != null;

  @override
  void initState() {
    super.initState();
    final c = widget.conta;
    _nome = TextEditingController(text: c?.nome ?? '');
    _saldo = TextEditingController(text: moedaInicial(c?.saldoInicial ?? 0));
    _obs = TextEditingController(text: c?.observacao ?? '');
    _tipo = c?.tipo ?? 'Banco';
    _moeda = c?.moeda ?? 'BRL';
    _ativa = c?.ativa ?? true;
  }

  @override
  void dispose() {
    _nome.dispose();
    _saldo.dispose();
    _obs.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      await ref.read(cadastrosRepositoryProvider).salvarConta({
        'nome': _nome.text.trim(),
        'tipo': _tipo,
        'moeda': _moeda,
        'saldoInicial': parseMoeda(_saldo.text),
        'ativa': _ativa,
        'observacao': _obs.text.trim().isEmpty ? null : _obs.text.trim(),
      }, id: widget.conta?.id);
      if (mounted) fecharDialogo(context);
    } catch (_) {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_edicao ? 'Editar conta' : 'Nova conta'),
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
              items: tipoContaLabels.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _tipo = v ?? 'Banco'),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _saldo,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [MoedaInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Saldo inicial (R\$)'),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: DropdownButtonFormField<String>(
                  initialValue: _moeda,
                  decoration: const InputDecoration(labelText: 'Moeda'),
                  items: const [
                    DropdownMenuItem(value: 'BRL', child: Text('BRL')),
                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                    DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                  ],
                  onChanged: (v) => setState(() => _moeda = v ?? 'BRL'),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: _obs,
              decoration: const InputDecoration(labelText: 'Observação (opcional)'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Conta ativa'),
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
