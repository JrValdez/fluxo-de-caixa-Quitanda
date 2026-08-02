import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Dispara o download de um arquivo no navegador a partir de bytes.
void baixarArquivo(List<int> bytes, String nomeArquivo, String mime) {
  final data = Uint8List.fromList(bytes);
  final blob = web.Blob([data.toJS].toJS, web.BlobPropertyBag(type: mime));
  final url = web.URL.createObjectURL(blob);
  final ancora = web.HTMLAnchorElement()
    ..href = url
    ..download = nomeArquivo;
  ancora.click();
  web.URL.revokeObjectURL(url);
}
