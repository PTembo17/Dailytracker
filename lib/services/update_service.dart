import 'dart:convert';
import 'package:ota_update/ota_update.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  static const String versionUrl =
      'https://raw.githubusercontent.com/your-user/your-repo/main/version.json';

  /// Returns the remote version payload if a newer build is available,
  /// or null if the app is already up to date (or the check fails).
  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      final response = await http.get(Uri.parse(versionUrl));
      if (response.statusCode != 200) return null;

      final remote = jsonDecode(response.body);
      if (remote is! Map<String, dynamic>) return null;

      final remoteBuild = int.tryParse(remote['build_number']?.toString() ?? '') ?? 0;
      if (remoteBuild <= 0) return null;

      if (remoteBuild > currentBuild) {
        return remote;
      }
      return null; // already up to date
    } catch (_) {
      return null; // network / parse error → silently ignore
    }
  }

  /// Downloads the APK from [apkUrl] and triggers the Android installer.
  ///
  /// [onProgress] receives values 0–100 while downloading.
  /// [onError]    receives a human-readable error message if something fails.
  static void downloadAndInstall(
    String apkUrl, {
    void Function(int progress)? onProgress,
    void Function(String error)? onError,
  }) {
    OtaUpdate()
        .execute(
          apkUrl,
          destinationFilename: 'app-update.apk',
        )
        .listen(
          (OtaEvent event) {
            switch (event.status) {
              case OtaStatus.DOWNLOADING:
                final progress = int.tryParse(event.value ?? '0') ?? 0;
                onProgress?.call(progress);
                break;
              case OtaStatus.INSTALLING:
                // Installer handed off to Android — nothing more to do.
                break;
              case OtaStatus.ALREADY_RUNNING_ERROR:
                onError?.call('An update is already in progress.');
                break;
              case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
                onError?.call(
                    'Install permission not granted. Please allow installs from unknown sources.');
                break;
              case OtaStatus.INTERNAL_ERROR:
                onError?.call('Download failed: ${event.value}');
                break;
              default:
                break;
            }
          },
        );
  }
}
