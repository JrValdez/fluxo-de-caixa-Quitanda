import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/moeda_input.dart';
import '../../../core/widgets/estados.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../cadastros/data/cadastros_repository.dart';
import '../../cadastros/domain/cadastro_models.dart';
import '../../cadastros/presentation/widgets/cadastro_scaffold.dart';
import '../data/recorrencias_repository.dart';
import '../data/transacoes_repository.dart';
import '../domain/transacao_models.dart';
import '../../../core/utils/dialogos.dart';

class RecorrenciasPage extends ConsumerWidget {
  const RecorrenciasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recorrenciasProvider);
    final podeEditar = ref.watch(authControllerProvider).usuario?.podeEditar ?? false;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Lançamentos recorrentes',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.marrom)),
            const Spacer(),
            if (podeEditar) ...[
              OutlinedButton.icon(
                onPressed: () => _gerar(context, ref),
                icon: const Icon(Icons.event_repeat),
                label: const Text('Gerar lançamentos'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => _dialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Nova recorrência'),
              ),
            ],
          ]),
          const SizedBox(height: 16),
          Expanded(
            child: async.when(
              loading: () => const EsqueletoLista(linhas: 4),
              error: (e, _) => Center(child: Text('Erro ao carregar: $e')),
              data: (lista) => lista.isEmpty
                  ? EstadoVazio(
                      icone: Icons.event_repeat,
                      titulo: 'Nenhuma recorrência',
                      mensagem: 'Cadastre lançamentos fixos (aluguel, salários, assinaturas) para gerá-los automaticamente.',
                      rotuloAcao: podeEditar ? 'Nova recorrência' : null,
                      onAcao: podeEditar ? () => _dialog(context, ref) : null,
                    )
                  : Card(
                      child: SingleChildScrollView(
                        child: SizedBox(
                          width: double.infinity,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Descrição')),
                              DataColumn(label: Text('Frequência')),
                              DataColumn(label: Text('Categoria')),
                              DataColumn(label: Text('Valor'), numeric: true),
                              DataColumn(label: Text('Próxima')),
                              DataColumn(label: Text('Ativa')),
                              DataColumn(label: Text('Ações')),
                            ],
                            rows: lista.map((r) => _row(context, ref, r, podeEditar)).toList(),
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

  DataRow _row(BuildContext context, WidgetRef ref, Recorrencia r, bool podeEditar) {
    final cor = r.isEntrada ? AppColors.entrada : AppColors.saida;
    return DataRow(cells: [
      DataCell(Text(r.descricao)),
      DataCell(Text(frequenciaLabels[r.frequencia] ?? r.frequencia)),
      DataCell(Text(r.categoriaNome)),
      DataCell(Text('${r.isEntrada ? '+' : '-'} ${Fmt.moeda(r.valor)}',
          style: TextStyle(color: cor, fontWeight: FontWeight.w600))),
      DataCell(Text(r.proximaGeracao != null ? Fmt.data(r.proximaGeracao!) : '—')),
      DataCell(Icon(r.ativa ? Icons.check_circle : Icons.cancel,
          color: r.ativa ? AppColors.entrada : AppColors.saida, size: 20)),
      DataCell(podeEditar
          ? Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _dialog(context, ref, rec: r)),
              IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: () => _excluir(context, ref, r)),
            ])
          : const SizedBox()),
    ]);
  }

  Future<void> _dialog(BuildContext context, WidgetRef ref, {Recorrencia? rec}) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => _RecorrenciaDialog(recorrencia: rec));
    if (ok == true) ref.invalidate(recorrenciasProvider);
  }

  Future<void> _excluir(BuildContext context, WidgetRef ref, Recorrencia r) async {
    if (await confirmarExclusao(context, r.descricao) != true) return;
    try {
      await ref.read(recorrenciasRepositoryProvider).excluir(r.id);
      ref.invalidate(recorrenciasProvider);
    } catch (e) {
      if (context.mounted) mostrarErroExclusao(context, e);
    }
  }

  Future<void> _gerar(BuildContext context, WidgetRef ref) async {
    final geradas = await ref.read(recorrenciasRepositoryProvider).gerar();
    ref.invalidate(recorrenciasProvider);
    ref.invalidate(transacoesProvider);
    ref.invalidate(resumoProvider);
    ref.invalidate(agendaProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$geradas lançamento(s) gerado(s).')),
      );
    }
  }
}

class _RecorrenciaDialog extends ConsumerStatefulWidget {
  final Recorrencia? recorrencia;
  const _RecorrenciaDialog({this.recorrencia});
  @override
  ConsumerState<_RecorrenciaDialog> createState() => _RecorrenciaDialogState();
}

class _RecorrenciaDialogState extends ConsumerState<_RecorrenciaDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _descricao;
  late final TextEditingController _valor;
  late String _frequencia;
  late String _tipo;
  late DateTime _dataInicio;
  DateTime? _dataFim;
  String? _contaId;
  String? _categoriaId;
  String? _contraParteId;
  bool _ativa = true;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    final r = widget.recorrencia;
    _descricao = TextEditingController(text: r?.descricao ?? '');
    _valor = TextEditingController(text: moedaInicial(r?.valor ?? 0));
    _frequencia = r?.frequencia ?? 'Mensal';
    _tipo = r?.tipo ?? 'Saida';
    _dataInicio = r?.dataInicio ?? DateTime.now();
    _dataFim = r?.dataFim;
    _contaId = r?.contaId;
    _categoriaId = r?.categoriaId;
    _contraParteId = r?.contraParteId;
    _ativa = r?.ativa ?? true;
  }

  @override
  void dispose() {
    _descricao.dispose();
    _valor.dispose();
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
      await ref.read(recorrenciasRepositoryProvider).salvar({
        'descricao': _descricao.text.trim(),
        'frequencia': _frequencia,
        'tipo': _tipo,
        'valor': parseMoeda(_valor.text),
        'dataInicio': d(_dataInicio),
        'dataFim': _dataFim == null ? null : d(_dataFim!),
        'ativa': _ativa,
        'contaId': _contaId,
        'categoriaId': _categoriaId,
        'contraParteId': _contraParteId,
      }, id: widget.recorrencia?.id);
      if (mounted) fecharDialogo(context, true);
    } catch (_) {
      setState(() { _salvando = false; _erro = 'Não foi possível salvar.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final contas = ref.watch(contasProvider).asData?.value ?? const <Conta>[];
    final categorias = ref.watch(categoriasProvider).asData?.value ?? const <Categoria>[];

    return AlertDialog(
      title: Text(widget.recorrencia == null ? 'Nova recorrência' : 'Editar recorrência'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Entrada', label: Text('Entrada')),
                  ButtonSegment(value: 'Saida', label: Text('Saída')),
                ],
                selected: {_tipo},
                onSelectionChanged: (s) => setState(() => _tipo = s.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricao,
                decoration: const InputDecoration(labelText: 'Descrição'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe a descrição' : null,
              ),
              const SizedBox(height: 12),
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
                    initialValue: _frequencia,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Frequência'),
                    items: frequenciaLabels.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) => setState(() => _frequencia = v ?? 'Mensal'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _contaId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Conta'),
                items: contas.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome))).toList(),
                validator: (v) => v == null ? 'Selecione' : null,
                onChanged: (v) => setState(() => _contaId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _categoriaId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: categorias.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome, overflow: TextOverflow.ellipsis))).toList(),
                validator: (v) => v == null ? 'Selecione' : null,
                onChanged: (v) => setState(() => _categoriaId = v),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _DataInline(label: 'Início', data: _dataInicio, onPick: (d) => setState(() => _dataInicio = d))),
                const SizedBox(width: 12),
                Expanded(child: _DataInline(label: 'Fim (opcional)', data: _dataFim, onPick: (d) => setState(() => _dataFim = d), onClear: () => setState(() => _dataFim = null))),
              ]),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ativa'),
                value: _ativa,
                activeThumbColor: AppColors.terracota,
                onChanged: (v) => setState(() => _ativa = v),
              ),
              if (_erro != null) Text(_erro!, style: const TextStyle(color: AppColors.saida)),
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

class _DataInline extends StatelessWidget {
  final String label;
  final DateTime? data;
  final void Function(DateTime) onPick;
  final VoidCallback? onClear;
  const _DataInline({required this.label, required this.data, required this.onPick, this.onClear});

  @override
  Widget build(BuildContext context) {
    final texto = data == null ? '—' : Fmt.data(data!);
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: data ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (d != null) onPick(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: (onClear != null && data != null)
              ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: onClear)
              : const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(texto),
      ),
    );
  }
}
