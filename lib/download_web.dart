import 'dart:convert';
import 'dart:html';
import 'dart:typed_data';

void download(Uint8List data, String filename) {
  final anchor = AnchorElement(
      href:
          'data:application/octet-stream;charset=utf-16le;base64,${base64Encode(data)}')
    ..setAttribute('download', filename);
  anchor.click();
}
