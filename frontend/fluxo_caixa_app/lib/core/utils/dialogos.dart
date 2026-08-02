import 'package:flutter/material.dart';

/// Fecha o diálogo atual com proteção contra toque duplo.
///
/// Um duplo clique rápido em "Cancelar"/"Salvar" disparava dois `Navigator.pop`:
/// o primeiro fechava o diálogo e o segundo removia a própria página da pilha
/// do go_router ("You have popped the last page off of the stack"), deixando o
/// app em tela branca. Aqui, se a rota do diálogo já não é a atual (o pop já
/// começou), o segundo toque é ignorado.
void fecharDialogo<T>(BuildContext context, [T? resultado]) {
  final route = ModalRoute.of(context);
  if (route == null || !route.isCurrent) return;
  Navigator.of(context).pop(resultado);
}
