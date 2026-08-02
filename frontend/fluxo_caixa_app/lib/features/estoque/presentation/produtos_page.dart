import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/moeda_input.dart';
import '../../../core/widgets/estados.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../cadastros/presentation/widgets/cadastro_scaffold.dart';
import '../data/estoque_repository.dart';
import '../domain/estoque_models.dart';
import 'movimento_dialog.dart';
import '../../../core/utils/dialogos.dart';

class ProdutosPage extends ConsumerWidget {
  const ProdutosPage({super.key});

  String _qtd(double v, String un) => '${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2)} $un';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(produtosProvider);
    final podeEditar = ref.watch(authControllerProvider).usuario?.podeEditar ?? false;

    return CadastroScaffold(
      titulo: 'Estoque / Produtos',
      onNovo: podeEditar ? () => _dialogProduto(context, ref) : null,
      child: async.when(
        loading: () => const EsqueletoLista(linhas: 5),
        error: (e, _) => Center(child: Text('Erro ao carregar: $e')),
        data: (produtos) => produtos.isEmpty
            ? EstadoVazio(
                icone: Icons.inventory_2_outlined,
                titulo: 'Nenhum produto cadastrado',
                mensagem: 'Cadastre os produtos (quitandas, pão de queijo...) para controlar o estoque.',
                rotuloAcao: podeEditar ? 'Novo produto' : null,
                onAcao: podeEditar ? () => _dialogProduto(context, ref) : null,
              )
            : Card(
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: double.infinity,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Produto')),
                        DataColumn(label: Text('Estoque'), numeric: true),
                        DataColumn(label: Text('Custo médio'), numeric: true),
                        DataColumn(label: Text('Preço venda'), numeric: true),
                        DataColumn(label: Text('Situação')),
                        DataColumn(label: Text('Ações')),
                      ],
                      rows: produtos.map((p) => DataRow(cells: [
                            DataCell(Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(p.nome, style: const TextStyle(fontWeight: FontWeight.w500)),
                                if (p.sku != null) Text(p.sku!, style: const TextStyle(fontSize: 11, color: AppColors.marromSuave)),
                              ],
                            )),
                            DataCell(Text(_qtd(p.quantidadeAtual, p.unidadeMedida),
                                style: TextStyle(fontWeight: FontWeight.w600, color: p.estoqueBaixo ? AppColors.saida : AppColors.marrom))),
                            DataCell(Text(Fmt.moeda(p.custoMedio))),
                            DataCell(Text(Fmt.moeda(p.precoVenda))),
                            DataCell(p.estoqueBaixo
                                ? const _Badge('Estoque baixo', AppColors.saida)
                                : (p.ativo ? const _Badge('OK', AppColors.entrada) : const _Badge('Inativo', AppColors.marromSuave))),
                            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(
                                tooltip: 'Histórico',
                                icon: const Icon(Icons.history, size: 20),
                                onPressed: () => _historico(context, ref, p),
                              ),
                              if (podeEditar) ...[
                                IconButton(
                                  tooltip: 'Movimentar',
                                  icon: const Icon(Icons.sync_alt, size: 20, color: AppColors.terracota),
                                  onPressed: () => _movimentar(context, ref, p),
                                ),
                                IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _dialogProduto(context, ref, produto: p)),
                                IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: () => _excluir(context, ref, p)),
                              ],
                            ])),
                          ])).toList(),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _movimentar(BuildContext context, WidgetRef ref, Produto p) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => MovimentoDialog(produto: p));
    if (ok == true) ref.invalidate(produtosProvider);
  }

  Future<void> _dialogProduto(BuildContext context, WidgetRef ref, {Produto? produto}) async {
    await showDialog(context: context, builder: (_) => _ProdutoDialog(produto: produto));
    ref.invalidate(produtosProvider);
  }

  Future<void> _excluir(BuildContext context, WidgetRef ref, Produto p) async {
    if (await confirmarExclusao(context, p.nome) != true) return;
    try {
      await ref.read(estoqueRepositoryProvider).excluirProduto(p.id);
      ref.invalidate(produtosProvider);
    } catch (e) {
      if (context.mounted) mostrarErroExclusao(context, e);
    }
  }

  Future<void> _historico(BuildContext context, WidgetRef ref, Produto p) async {
    await showDialog(context: context, builder: (_) => _HistoricoDialog(produto: p));
  }
}

class _Badge extends StatelessWidget {
  final String texto;
  final Color cor;
  const _Badge(this.texto, this.cor);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: cor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
        child: Text(texto, style: TextStyle(color: cor, fontWeight: FontWeight.w600, fontSize: 12)),
      );
}

class _HistoricoDialog extends ConsumerWidget {
  final Produto produto;
  const _HistoricoDialog({required this.produto});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(movimentosProvider(produto.id));
    return AlertDialog(
      title: Text('Histórico — ${produto.nome}'),
      content: SizedBox(
        width: 460,
        child: async.when(
          loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Text('Erro: $e'),
          data: (movs) => movs.isEmpty
              ? const Text('Nenhum movimento.')
              : SizedBox(
                  width: 460,
                  height: 360,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: movs.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final m = movs[i];
                      final entrada = m.tipo == 'Entrada';
                      final cor = m.tipo == 'Ajuste' ? AppColors.marromSuave : (entrada ? AppColors.entrada : AppColors.saida);
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          m.tipo == 'Ajuste' ? Icons.tune : (entrada ? Icons.add : Icons.remove),
                          color: cor, size: 20),
                        title: Text('${tipoMovimentoEstoqueLabels[m.tipo]} · ${m.quantidade.toStringAsFixed(0)} ${produto.unidadeMedida}'),
                        subtitle: Text('${Fmt.data(m.data)}${m.observacao != null ? ' · ${m.observacao}' : ''}'),
                        trailing: m.transacaoId != null
                            ? const Tooltip(message: 'Gerou lançamento no caixa', child: Icon(Icons.link, size: 18, color: AppColors.terracota))
                            : null,
                      );
                    },
                  ),
                ),
        ),
      ),
      actions: [TextButton(onPressed: () => fecharDialogo(context), child: const Text('Fechar'))],
    );
  }
}

class _ProdutoDialog extends ConsumerStatefulWidget {
  final Produto? produto;
  const _ProdutoDialog({this.produto});
  @override
  ConsumerState<_ProdutoDialog> createState() => _ProdutoDialogState();
}

class _ProdutoDialogState extends ConsumerState<_ProdutoDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nome, _sku, _unidade, _preco, _estoqueMin, _custoIni, _qtdIni;
  late bool _ativo;
  bool _salvando = false;

  bool get _edicao => widget.produto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.produto;
    _nome = TextEditingController(text: p?.nome ?? '');
    _sku = TextEditingController(text: p?.sku ?? '');
    _unidade = TextEditingController(text: p?.unidadeMedida ?? 'un');
    _preco = TextEditingController(text: moedaInicial(p?.precoVenda ?? 0));
    _estoqueMin = TextEditingController(text: (p?.estoqueMinimo ?? 0).toStringAsFixed(0));
    _custoIni = TextEditingController(text: moedaInicial(p?.custoMedio ?? 0));
    _qtdIni = TextEditingController(text: '0');
    _ativo = p?.ativo ?? true;
  }

  @override
  void dispose() {
    for (final c in [_nome, _sku, _unidade, _preco, _estoqueMin, _custoIni, _qtdIni]) {
      c.dispose();
    }
    super.dispose();
  }

  double _num(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      await ref.read(estoqueRepositoryProvider).salvarProduto({
        'nome': _nome.text.trim(),
        'sku': _sku.text.trim().isEmpty ? null : _sku.text.trim(),
        'unidadeMedida': _unidade.text.trim().isEmpty ? 'un' : _unidade.text.trim(),
        'precoVenda': parseMoeda(_preco.text),
        'estoqueMinimo': _num(_estoqueMin),
        'ativo': _ativo,
        'custoMedio': parseMoeda(_custoIni.text),
        'quantidadeInicial': _edicao ? 0 : _num(_qtdIni),
      }, id: widget.produto?.id);
      if (mounted) fecharDialogo(context);
    } catch (_) {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_edicao ? 'Editar produto' : 'Novo produto'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: _nome,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextFormField(controller: _sku, decoration: const InputDecoration(labelText: 'SKU (opcional)'))),
                const SizedBox(width: 12),
                SizedBox(width: 110, child: TextFormField(controller: _unidade, decoration: const InputDecoration(labelText: 'Unidade'))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextFormField(
                  controller: _preco,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [MoedaInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Preço de venda (R\$)'),
                )),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(
                  controller: _estoqueMin,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Estoque mínimo'),
                )),
              ]),
              if (!_edicao) ...[
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextFormField(
                    controller: _qtdIni,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Estoque inicial'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(
                    controller: _custoIni,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [MoedaInputFormatter()],
                    decoration: const InputDecoration(labelText: 'Custo unitário (R\$)'),
                  )),
                ]),
              ],
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Produto ativo'),
                value: _ativo,
                activeThumbColor: AppColors.terracota,
                onChanged: (v) => setState(() => _ativo = v),
              ),
            ]),
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
