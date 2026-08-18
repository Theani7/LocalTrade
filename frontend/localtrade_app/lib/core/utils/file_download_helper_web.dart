// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;

Future<void> saveAndShareFile({
  required String bytesString,
  required String fileName,
  required String mimeType,
}) async {
  final uri = Uri.dataFromString(
    bytesString,
    mimeType: mimeType,
    encoding: utf8,
  ).toString();

  final anchor = html.AnchorElement(href: uri)
    ..setAttribute('download', fileName)
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
}
