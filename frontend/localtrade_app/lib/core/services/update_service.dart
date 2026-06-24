import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

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

  Future<UpdateInfo> checkForUpdate({bool force = false}) async {
    if (_cachedInfo != null && !force) return _cachedInfo!;

    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;

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
      final latestTag = (data['tag_name'] as String?)?.replaceFirst('v', '') ?? currentVersion;
      final releaseNotes = (data['body'] as String?) ?? '';
      final downloadUrl = (data['html_url'] as String?) ?? 'https://github.com/$_repo/releases/latest';

      final hasUpdate = _isNewer(latestTag, currentVersion);

      _cachedInfo = UpdateInfo(
        hasUpdate: hasUpdate,
        currentVersion: currentVersion,
        latestVersion: latestTag,
        releaseNotes: releaseNotes,
        downloadUrl: downloadUrl,
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
