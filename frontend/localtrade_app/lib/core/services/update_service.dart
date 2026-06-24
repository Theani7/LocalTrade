import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String releaseNotes;
  final String downloadUrl;

  UpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
    required this.downloadUrl,
  });
}

class UpdateService {
  UpdateService._();

  static final UpdateService _instance = UpdateService._();
  factory UpdateService() => _instance;

  static const String _repo = 'Theani7/LocalTrade';
  UpdateInfo? _cachedInfo;

  UpdateInfo? get cached => _cachedInfo;

  static const String _fallbackVersion = '2.2.1';

  Future<UpdateInfo> checkForUpdate({bool force = false}) async {
    if (_cachedInfo != null && !force) return _cachedInfo!;

    String currentVersion;
    try {
      final info = await PackageInfo.fromPlatform();
      currentVersion = info.version;
    } catch (_) {
      currentVersion = _fallbackVersion;
    }

    try {
      final uri = Uri.parse('https://api.github.com/repos/$_repo/releases/latest');
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode != 200) {
        return _cachedInfo ?? UpdateInfo(
          hasUpdate: false,
          currentVersion: currentVersion,
          latestVersion: currentVersion,
          releaseNotes: '',
          downloadUrl: 'https://github.com/$_repo/releases/latest',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = (data['tag_name'] as String?)?.replaceFirst('v', '') ?? currentVersion;

      String apkUrl = 'https://github.com/$_repo/releases/latest';
      final assets = data['assets'] as List<dynamic>?;
      if (assets != null) {
        for (final asset in assets) {
          final name = asset['name'] as String? ?? '';
          if (name.endsWith('.apk')) {
            apkUrl = asset['browser_download_url'] as String? ?? apkUrl;
            break;
          }
        }
      }

      final releaseNotes = (data['body'] as String?) ?? '';

      final hasUpdate = _isNewer(tag, currentVersion);

      _cachedInfo = UpdateInfo(
        hasUpdate: hasUpdate,
        currentVersion: currentVersion,
        latestVersion: tag,
        releaseNotes: releaseNotes,
        downloadUrl: apkUrl,
      );
    } catch (_) {
      _cachedInfo ??= UpdateInfo(
        hasUpdate: false,
        currentVersion: currentVersion,
        latestVersion: currentVersion,
        releaseNotes: '',
        downloadUrl: 'https://github.com/$_repo/releases/latest',
      );
    }

    return _cachedInfo!;
  }

  Future<String> downloadApk({
    required String url,
    required void Function(int received, int total) onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/localtrade_update.apk');

    final response = await http.Client().send(http.Request('GET', Uri.parse(url)));
    final total = response.contentLength ?? -1;
    final sink = file.openWrite(mode: FileMode.write);
    int received = 0;

    await for (final chunk in response.stream) {
      sink.add(chunk);
      received += chunk.length;
      onProgress(received, total);
    }

    await sink.flush();
    await sink.close();
    return file.path;
  }

  bool _isNewer(String latest, String current) {
    final latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLen = latestParts.length > currentParts.length ? latestParts.length : currentParts.length;
    for (var i = 0; i < maxLen; i++) {
      final l = i < latestParts.length ? latestParts[i] : 0;
      final c = i < currentParts.length ? currentParts[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }
}
