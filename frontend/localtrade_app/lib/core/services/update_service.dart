import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
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

  static const String _fallbackVersion = '2.3.4';

  Future<UpdateInfo> checkForUpdate({bool force = false}) async {
    if (_cachedInfo != null && !force) return _cachedInfo!;

    String currentVersion;
    int currentBuild = 0;
    try {
      final info = await PackageInfo.fromPlatform();
      currentVersion = info.version;
      currentBuild = int.tryParse(info.buildNumber) ?? 0;
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
        final abis = await _deviceAbis();
        String? fallbackUrl;
        for (final asset in assets) {
          final name = asset['name'] as String? ?? '';
          if (!name.endsWith('.apk')) continue;
          final url = asset['browser_download_url'] as String?;
          if (url == null) continue;
          if (abis.isNotEmpty && abis.any(name.contains)) {
            apkUrl = url;
            break;
          }
          fallbackUrl ??= url;
        }
        if (apkUrl == 'https://github.com/$_repo/releases/latest' && fallbackUrl != null) {
          apkUrl = fallbackUrl;
        }
      }

      final releaseNotes = (data['body'] as String?) ?? '';

      final hasUpdate = _isNewer(tag, currentVersion, currentBuild);

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

  Future<List<String>> _deviceAbis() async {
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      return info.supportedAbis;
    } catch (_) {
      return const [];
    }
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

  bool _isNewer(String latest, String current, int currentBuild) {
    final latestParts = _versionParts(latest);
    final currentParts = _versionParts(current);
    final latestBuild = _buildNumber(latest);

    final maxLen = latestParts.length > currentParts.length ? latestParts.length : currentParts.length;
    for (var i = 0; i < maxLen; i++) {
      final l = i < latestParts.length ? latestParts[i] : 0;
      final c = i < currentParts.length ? currentParts[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return latestBuild > currentBuild;
  }

  List<int> _versionParts(String version) {
    final clean = version.split('+').first;
    return clean.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  }

  int _buildNumber(String version) {
    final parts = version.split('+');
    return parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  }
}
