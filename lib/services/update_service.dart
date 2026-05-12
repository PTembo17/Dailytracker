import 'dart:convert';
import 'package:ota_update/ota_update.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  static const String versionUrl =
    'https://raw.githubusercontent.com/your-user/your-repo/main/version.json';

  static Future<Map<String, dynamic>?> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;      // e.g. "1.0.0"
    final currentBuild = int.parse(packageInfo.buildNumber); // e.g. 10

    final response = await http.get(Uri.parse(versionUrl));
    if (response.statusCode != 200) return null;

    final remote = jsonDecode(response.body);
    final remoteBuild = remote['build_number'] as int;

    if (remoteBuild > currentBuild) {
      return remote; // update available → return the full payload
    }
    return null;     // already up to date
  }
  static void downloadAndInstall(String apkUrl) {
  OtaUpdate()
    .execute(
      apkUrl,
      destinationFilename: 'app-update.apk',
    )
    .listen(
      (OtaEvent event) {
        switch (event.status) {
          case OtaStatus.DOWNLOADING:
            // event.value = "0" to "100" (progress %)
            print('Downloading: ${event.value}%');
            break;
          case OtaStatus.INSTALLING:
            print('Launching installer...');
            break;
          case OtaStatus.ALREADY_RUNNING_ERROR:
          case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
          case OtaStatus.INTERNAL_ERROR:
            print('Error: ${event.value}');
            break;
          default:
            break;
        }
      },
    );
}
}