import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/moeda_input.dart';
import '../../cadastros/data/cadastros_repository.dart';
import '../../cadastros/domain/cadastro_models.dart';
import '../data/projecoes_repository.dart';
import '../../../core/utils/dialogos.dart';

class SimulacaoDialog extends ConsumerStatefulWidget {
  const SimulacaoDialog({super.key});
  @override
  ConsumerState<SimulacaoDialog> createState() => _SimulacaoDialogState();
}

class _SimulacaoDialogState extends ConsumerState<SimulacaoDialog> {
  final _form = GlobalKey<FormState>();
  final _valor = TextEditingController();
  final _descricao = TextEditingController();
  String _tipo = 'Saida';
  DateTime _data = DateTime.now();
  String? _contaId;
  String? _categoriaId;
  bool _salvando = false;
  String? _erro;

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
    try {
      await ref.read(projecoesRepositoryProvider).criarSimulacao({
        'tipo': _tipo,
        'valor': parseMoeda(_valor.text),
        'descricao': _descricao.text.trim().isEmpty ? null : _descricao.text.trim(),
        'data': _data.toIso8601String().substring(0, 10),
        'contaId': _contaId,
        'categoriaId': _categoriaId,
      });
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
      title: const Text('Novo cenário simulado'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _form,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Entrada', label: Text('Entrada'), icon: Icon(Icons.south_west)),
                ButtonSegment(value: 'Saida', label: Text('Saída'), icon: Icon(Icons.north_east)),
              ],
              selected: {_tipo},
              onSelectionChanged: (s) => setState(() => _tipo = s.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valor,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [MoedaInputFormatter()],
              decoration: const InputDecoration(labelText: 'Valor (R\$)'),
              validator: (v) => parseMoeda(v ?? '') <= 0 ? 'Valor inválido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _descricao, decoration: const InputDecoration(labelText: 'Descrição')),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _data,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime(2100),
                );
                if (d != null) setState(() => _data = d);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Data prevista', suffixIcon: Icon(Icons.calendar_today, size: 18)),
                child: Text(Fmt.data(_data)),
              ),
            ),
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
            if (_erro != null) ...[
              const SizedBox(height: 12),
              Text(_erro!, style: const TextStyle(color: AppColors.saida)),
            ],
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
