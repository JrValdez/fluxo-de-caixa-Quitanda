import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/moeda_input.dart';
import '../../cadastros/data/cadastros_repository.dart';
import '../../cadastros/domain/cadastro_models.dart';
import '../data/transacoes_repository.dart';
import '../domain/transacao_models.dart';
import '../../../core/utils/dialogos.dart';

/// Formulário de lançamento (criação/edição) de uma transação.
class TransacaoDialog extends ConsumerStatefulWidget {
  final Transacao? transacao;
  const TransacaoDialog({super.key, this.transacao});

  @override
  ConsumerState<TransacaoDialog> createState() => _TransacaoDialogState();
}

class _TransacaoDialogState extends ConsumerState<TransacaoDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _valor;
  late final TextEditingController _descricao;
  late String _tipo;
  late String _status;
  late DateTime _data;
  DateTime? _vencimento;
  String? _contaId;
  String? _categoriaId;
  String? _subcategoriaId;
  String? _contraParteId;
  String? _formaPagamentoId;
  bool _salvando = false;
  String? _erro;

  bool get _edicao => widget.transacao != null;

  @override
  void initState() {
    super.initState();
    final t = widget.transacao;
    _valor = TextEditingController(text: moedaInicial(t?.valor ?? 0));
    _descricao = TextEditingController(text: t?.descricao ?? '');
    _tipo = t?.tipo ?? 'Entrada';
    _status = t?.status ?? 'Realizado';
    _data = t?.data ?? DateTime.now();
    _vencimento = t?.dataVencimento;
    _contaId = t?.contaId;
    _categoriaId = t?.categoriaId;
    _subcategoriaId = t?.subcategoriaId;
    _contraParteId = t?.contraParteId;
    _formaPagamentoId = t?.formaPagamentoId;
  }

  @override
  void dispose() {
    _valor.dispose();
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    if (_contaId == null || _categoriaId == null) {
      setState(() => _erro = 'Selecione a conta e a categoria.');
      return;
    }
    setState(() { _salvando = true; _erro = null; });
    String d(DateTime x) => x.toIso8601String().substring(0, 10);
    try {
      await ref.read(transacoesRepositoryProvider).salvar({
        'tipo': _tipo,
        'valor': parseMoeda(_valor.text),
        'descricao': _descricao.text.trim().isEmpty ? null : _descricao.text.trim(),
        'data': d(_data),
        'dataVencimento': _vencimento == null ? null : d(_vencimento!),
        'dataPagamento': _status == 'Realizado' ? d(_data) : null,
        'status': _status,
        'contaId': _contaId,
        'categoriaId': _categoriaId,
        'subcategoriaId': _subcategoriaId,
        'contraParteId': _contraParteId,
        'formaPagamentoId': _formaPagamentoId,
      }, id: widget.transacao?.id);
      if (mounted) fecharDialogo(context, true);
    } catch (_) {
      setState(() { _salvando = false; _erro = 'Não foi possível salvar o lançamento.'; });
    }
  }

  Future<void> _escolherData({required bool vencimento}) async {
    final inicial = vencimento ? (_vencimento ?? DateTime.now()) : _data;
    final escolhida = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (escolhida != null) {
      setState(() {
        if (vencimento) {
          _vencimento = escolhida;
        } else {
          _data = escolhida;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final contas = ref.watch(contasProvider);
    final categorias = ref.watch(categoriasProvider);
    final contrapartes = ref.watch(contrapartesProvider);
    final formas = ref.watch(formasPagamentoProvider);

    final catList = categorias.asData?.value ?? const <Categoria>[];
    final catSelecionada = catList.where((c) => c.id == _categoriaId).firstOrNull;

    return AlertDialog(
      title: Text(_edicao ? 'Editar lançamento' : 'Novo lançamento'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Tipo (Entrada/Saída)
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Entrada', label: Text('Entrada'), icon: Icon(Icons.south_west)),
                  ButtonSegment(value: 'Saida', label: Text('Saída'), icon: Icon(Icons.north_east)),
                ],
                selected: {_tipo},
                onSelectionChanged: (s) => setState(() => _tipo = s.first),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _valor,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [MoedaInputFormatter()],
                    decoration: const InputDecoration(labelText: 'Valor (R\$)'),
                    validator: (v) => parseMoeda(v ?? '') <= 0 ? 'Valor inválido' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'Realizado', child: Text('Realizado')),
                      DropdownMenuItem(value: 'Previsto', child: Text('Previsto')),
                    ],
                    onChanged: (v) => setState(() => _status = v ?? 'Realizado'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descricao,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _DataField(label: 'Data', data: _data, onTap: () => _escolherData(vencimento: false))),
                const SizedBox(width: 12),
                Expanded(child: _DataField(label: 'Vencimento', data: _vencimento, onTap: () => _escolherData(vencimento: true), limpavel: () => setState(() => _vencimento = null))),
              ]),
              const SizedBox(height: 12),
              _dropdownAsync<Conta>(contas, 'Conta', _contaId, (c) => c.id, (c) => c.nome,
                  (v) => setState(() => _contaId = v)),
              const SizedBox(height: 12),
              _dropdownAsync<Categoria>(categorias, 'Categoria', _categoriaId, (c) => c.id,
                  (c) => '${c.nome} (${c.tipo == 'Receita' ? 'Rec' : 'Desp'})',
                  (v) => setState(() { _categoriaId = v; _subcategoriaId = null; })),
              if (catSelecionada != null && catSelecionada.subcategorias.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _subcategoriaId,
                  decoration: const InputDecoration(labelText: 'Subcategoria (opcional)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('—')),
                    ...catSelecionada.subcategorias
                        .map((s) => DropdownMenuItem(value: s.id, child: Text(s.nome))),
                  ],
                  onChanged: (v) => setState(() => _subcategoriaId = v),
                ),
              ],
              const SizedBox(height: 12),
              _dropdownAsync<ContraParte>(contrapartes, 'Cliente/Fornecedor (opcional)', _contraParteId,
                  (c) => c.id, (c) => c.nome, (v) => setState(() => _contraParteId = v), opcional: true),
              const SizedBox(height: 12),
              _dropdownAsync<FormaPagamento>(formas, 'Forma de pagamento (opcional)', _formaPagamentoId,
                  (f) => f.id, (f) => f.nome, (v) => setState(() => _formaPagamentoId = v), opcional: true),
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
              : const Text('Salvar'),
        ),
      ],
    );
  }

  Widget _dropdownAsync<T>(
    AsyncValue<List<T>> async,
    String label,
    String? valor,
    String Function(T) id,
    String Function(T) nome,
    void Function(String?) onChanged, {
    bool opcional = false,
  }) {
    return async.when(
      loading: () => InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: const SizedBox(height: 20, child: LinearProgressIndicator()),
      ),
      error: (e, _) => Text('Erro ao carregar $label'),
      data: (itens) => DropdownButtonFormField<String>(
        initialValue: valor,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          if (opcional) const DropdownMenuItem(value: null, child: Text('—')),
          ...itens.map((i) => DropdownMenuItem(value: id(i), child: Text(nome(i), overflow: TextOverflow.ellipsis))),
        ],
        validator: opcional ? null : (v) => v == null ? 'Selecione' : null,
        onChanged: onChanged,
      ),
    );
  }
}

class _DataField extends StatelessWidget {
  final String label;
  final DateTime? data;
  final VoidCallback onTap;
  final VoidCallback? limpavel;
  const _DataField({required this.label, required this.data, required this.onTap, this.limpavel});

  @override
  Widget build(BuildContext context) {
    final texto = data == null
        ? '—'
        : '${data!.day.toString().padLeft(2, '0')}/${data!.month.toString().padLeft(2, '0')}/${data!.year}';
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: (limpavel != null && data != null)
              ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: limpavel)
              : const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(texto),
      ),
    );
  }
}
