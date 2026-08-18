import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveAndShareFile({
  required String bytesString,
  required String fileName,
  required String mimeType,
}) async {
  final bytes = utf8.encode(bytesString);
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: mimeType, name: fileName)],
    sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
  );
}
