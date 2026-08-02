import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/estados.dart';
import '../../cadastros/data/cadastros_repository.dart';
import '../../cadastros/domain/cadastro_models.dart';
import '../data/extras_repository.dart';
import '../domain/extras_models.dart';

class ConciliacaoPage extends ConsumerStatefulWidget {
  const ConciliacaoPage({super.key});
  @override
  ConsumerState<ConciliacaoPage> createState() => _ConciliacaoPageState();
}

class _ConciliacaoPageState extends ConsumerState<ConciliacaoPage> {
  final _csv = TextEditingController();
  String? _contaId;
  String? _categoriaId;
  List<LinhaExtrato>? _linhas;
  bool _importando = false;
  String? _erro;

  @override
  void dispose() {
    _csv.dispose();
    super.dispose();
  }

  Future<void> _importar() async {
    if (_contaId == null) {
      setState(() => _erro = 'Selecione a conta do extrato.');
      return;
    }
    setState(() { _importando = true; _erro = null; });
    try {
      final linhas = await ref.read(extrasRepositoryProvider).importarExtrato(_contaId!, _csv.text);
      setState(() => _linhas = linhas);
    } catch (_) {
      setState(() => _erro = 'Não foi possível importar. Verifique o formato: data;descrição;valor');
    } finally {
      if (mounted) setState(() => _importando = false);
    }
  }

  Future<void> _conciliar(LinhaExtrato l) async {
    if (l.transacaoCorrespondenteId == null && _categoriaId == null) {
      setState(() => _erro = 'Selecione uma categoria padrão para conciliar linhas sem correspondência.');
      return;
    }
    try {
      await ref.read(extrasRepositoryProvider).conciliar({
        'contaId': _contaId,
        'data': l.data.toIso8601String().substring(0, 10),
        'descricao': l.descricao,
        'valor': l.valor,
        'tipo': l.tipo,
        'transacaoCorrespondenteId': l.transacaoCorrespondenteId,
        'categoriaId': _categoriaId,
      });
      setState(() => l.conciliada = true);
    } catch (_) {
      setState(() => _erro = 'Falha ao conciliar a linha.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final contas = ref.watch(contasProvider).asData?.value ?? const <Conta>[];
    final categorias = ref.watch(categoriasProvider).asData?.value ?? const <Categoria>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Conciliação bancária',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.marrom)),
          const SizedBox(height: 4),
          const Text('Importe o extrato (CSV) e concilie com os lançamentos previstos.',
              style: TextStyle(color: AppColors.marromSuave)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 16, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  SizedBox(
                    width: 260,
                    child: DropdownButtonFormField<String>(
                      initialValue: _contaId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Conta do extrato', isDense: true),
                      items: contas.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome))).toList(),
                      onChanged: (v) => setState(() => _contaId = v),
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: DropdownButtonFormField<String>(
                      initialValue: _categoriaId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Categoria padrão (novos)', isDense: true),
                      items: categorias.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setState(() => _categoriaId = v),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextField(
                  controller: _csv,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Extrato (CSV)',
                    hintText: 'data;descrição;valor  (valor negativo = saída)\n2026-08-02;PIX cliente;540,00\n2026-08-02;Fornecedor;-120,00',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  FilledButton.icon(
                    onPressed: _importando ? null : _importar,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Importar'),
                  ),
                  if (_erro != null) ...[
                    const SizedBox(width: 16),
                    Expanded(child: Text(_erro!, style: const TextStyle(color: AppColors.saida))),
                  ],
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          if (_importando) const Center(child: CircularProgressIndicator()),
          if (_linhas != null && _linhas!.isNotEmpty) ...[
            Text('${_linhas!.length} linha(s) importada(s)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.marrom)),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: _linhas!.map((l) => _LinhaTile(linha: l, onConciliar: () => _conciliar(l))).toList(),
              ),
            ),
          ],
          if (_linhas != null && _linhas!.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: EstadoVazio(
                  icone: Icons.description_outlined,
                  titulo: 'Nenhuma linha válida no CSV',
                  mensagem: 'Use o formato: data;descrição;valor — valor negativo indica saída.',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LinhaTile extends StatelessWidget {
  final LinhaExtrato linha;
  final VoidCallback onConciliar;
  const _LinhaTile({required this.linha, required this.onConciliar});

  @override
  Widget build(BuildContext context) {
    final cor = linha.isEntrada ? AppColors.entrada : AppColors.saida;
    final match = linha.transacaoCorrespondenteId != null;
    return ListTile(
      leading: Icon(linha.isEntrada ? Icons.south_west : Icons.north_east, color: cor),
      title: Text(linha.descricao),
      subtitle: Text(
        '${Fmt.data(linha.data)}'
        '${match ? ' · corresponde a: ${linha.descricaoCorrespondente ?? 'lançamento previsto'}' : ' · sem correspondência (cria novo)'}',
        style: TextStyle(color: match ? AppColors.entrada : AppColors.marromSuave),
      ),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('${linha.isEntrada ? '+' : '-'} ${Fmt.moeda(linha.valor)}',
            style: TextStyle(color: cor, fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        linha.conciliada
            ? const Chip(
                label: Text('Conciliado'),
                backgroundColor: Color(0x1A2E7D5B),
                labelStyle: TextStyle(color: AppColors.entrada, fontWeight: FontWeight.w600),
                side: BorderSide.none,
              )
            : FilledButton(onPressed: onConciliar, child: const Text('Conciliar')),
      ]),
    );
  }
}
