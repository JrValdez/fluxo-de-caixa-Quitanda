import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/moeda_input.dart';
import '../../cadastros/data/cadastros_repository.dart';
import '../../cadastros/domain/cadastro_models.dart';
import '../data/estoque_repository.dart';
import '../domain/estoque_models.dart';
import '../../../core/utils/dialogos.dart';

class MovimentoDialog extends ConsumerStatefulWidget {
  final Produto produto;
  const MovimentoDialog({super.key, required this.produto});
  @override
  ConsumerState<MovimentoDialog> createState() => _MovimentoDialogState();
}

class _MovimentoDialogState extends ConsumerState<MovimentoDialog> {
  final _form = GlobalKey<FormState>();
  final _quantidade = TextEditingController();
  final _custo = TextEditingController();
  final _valor = TextEditingController();
  final _obs = TextEditingController();
  String _tipo = 'Entrada';
  DateTime _data = DateTime.now();
  bool _gerarTransacao = true;
  String? _contaId;
  String? _categoriaId;
  String? _formaPagamentoId;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _custo.text = moedaInicial(widget.produto.custoMedio);
  }

  @override
  void dispose() {
    _quantidade.dispose();
    _custo.dispose();
    _valor.dispose();
    _obs.dispose();
    super.dispose();
  }

  bool get _isAjuste => _tipo == 'Ajuste';
  bool get _isEntrada => _tipo == 'Entrada';

  double get _valorSugerido {
    final q = double.tryParse(_quantidade.text.replaceAll(',', '.')) ?? 0;
    if (_isEntrada) return q * parseMoeda(_custo.text);
    return q * widget.produto.precoVenda;
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    if (_gerarTransacao && !_isAjuste && (_contaId == null || _categoriaId == null)) {
      setState(() => _erro = 'Selecione conta e categoria para o lançamento no caixa.');
      return;
    }
    setState(() { _salvando = true; _erro = null; });
    try {
      final valorInformado = _valor.text.trim().isEmpty ? null : parseMoeda(_valor.text);
      await ref.read(estoqueRepositoryProvider).registrarMovimento({
        'produtoId': widget.produto.id,
        'tipo': _tipo,
        'quantidade': double.parse(_quantidade.text.replaceAll(',', '.')),
        'custoUnitario': parseMoeda(_custo.text),
        'data': _data.toIso8601String().substring(0, 10),
        'observacao': _obs.text.trim().isEmpty ? null : _obs.text.trim(),
        'gerarTransacao': _gerarTransacao && !_isAjuste,
        'valorTransacao': valorInformado,
        'contaId': _contaId,
        'categoriaId': _categoriaId,
        'formaPagamentoId': _formaPagamentoId,
        'contraParteId': null,
      });
      if (mounted) fecharDialogo(context, true);
    } catch (e) {
      setState(() { _salvando = false; _erro = _mensagemErro(e); });
    }
  }

  String _mensagemErro(Object e) {
    if (e is DioException && e.response?.data is Map && (e.response!.data as Map)['mensagem'] is String) {
      return (e.response!.data as Map)['mensagem'] as String;
    }
    return 'Não foi possível registrar o movimento.';
  }

  @override
  Widget build(BuildContext context) {
    final contas = ref.watch(contasProvider).asData?.value ?? const <Conta>[];
    final categorias = ref.watch(categoriasProvider).asData?.value ?? const <Categoria>[];
    final formas = ref.watch(formasPagamentoProvider).asData?.value ?? const <FormaPagamento>[];

    return AlertDialog(
      title: Text('Movimentar — ${widget.produto.nome}'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Estoque atual: ${Fmt.moeda(widget.produto.quantidadeAtual).replaceAll('R\$', '').trim()} '
                  '${widget.produto.unidadeMedida}  ·  custo médio ${Fmt.moeda(widget.produto.custoMedio)}',
                  style: const TextStyle(color: AppColors.marromSuave)),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Entrada', label: Text('Compra')),
                  ButtonSegment(value: 'Saida', label: Text('Venda')),
                  ButtonSegment(value: 'Ajuste', label: Text('Ajuste')),
                ],
                selected: {_tipo},
                onSelectionChanged: (s) => setState(() => _tipo = s.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantidade,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _isAjuste ? 'Nova quantidade em estoque' : 'Quantidade (${widget.produto.unidadeMedida})',
                ),
                validator: (v) {
                  final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                  if (n == null) return 'Valor inválido';
                  if (!_isAjuste && n <= 0) return 'Deve ser maior que zero';
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              if (_isEntrada) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _custo,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [MoedaInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Custo unitário (R\$)'),
                  onChanged: (_) => setState(() {}),
                ),
              ],
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context, initialDate: _data, firstDate: DateTime(2020), lastDate: DateTime(2100));
                      if (d != null) setState(() => _data = d);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Data', suffixIcon: Icon(Icons.calendar_today, size: 18)),
                      child: Text(Fmt.data(_data)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _obs, decoration: const InputDecoration(labelText: 'Observação'))),
              ]),
              if (!_isAjuste) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Gerar lançamento no caixa'),
                  subtitle: Text(_isEntrada ? 'Cria uma saída (pagamento ao fornecedor)' : 'Cria uma entrada (recebimento da venda)',
                      style: const TextStyle(fontSize: 12)),
                  value: _gerarTransacao,
                  activeThumbColor: AppColors.terracota,
                  onChanged: (v) => setState(() => _gerarTransacao = v),
                ),
                if (_gerarTransacao) ...[
                  DropdownButtonFormField<String>(
                    initialValue: _contaId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Conta'),
                    items: contas.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome))).toList(),
                    onChanged: (v) => setState(() => _contaId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _categoriaId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: categorias.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) => setState(() => _categoriaId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _formaPagamentoId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Forma de pagamento (opcional)'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('—')),
                      ...formas.map((f) => DropdownMenuItem(value: f.id, child: Text(f.nome))),
                    ],
                    onChanged: (v) => setState(() => _formaPagamentoId = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _valor,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [MoedaInputFormatter()],
                    decoration: InputDecoration(
                      labelText: 'Valor no caixa (R\$)',
                      hintText: 'Sugerido: ${Fmt.moeda(_valorSugerido)}',
                    ),
                  ),
                ],
              ],
              if (_erro != null) ...[
                const SizedBox(height: 12),
                Text(_erro!, style: const TextStyle(color: AppColors.saida)),
              ],
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
              : const Text('Registrar'),
        ),
      ],
    );
  }
}
