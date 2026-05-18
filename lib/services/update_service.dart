import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const String owner = 'DennyNguyen123';
  static const String repo = 'NovelReader';

  static Future<void> checkForUpdate(BuildContext context, {bool showNoUpdateMessage = false}) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String latestVersionTag = data['tag_name'];
        final String latestVersion = latestVersionTag.replaceAll('v', '');
        
        final PackageInfo packageInfo = await PackageInfo.fromPlatform();
        final String currentVersion = packageInfo.version;

        if (_isNewerVersion(currentVersion, latestVersion)) {
          final String body = data['body'] ?? 'No release notes available.';
          final String downloadUrl = _getDownloadUrl(data['assets'] ?? []);
          
          if (context.mounted) {
            _showUpdateDialog(context, latestVersion, body, downloadUrl);
          }
        } else if (showNoUpdateMessage && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You are on the latest version.')),
          );
        }
      } else {
        if (showNoUpdateMessage && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to check for updates.')),
          );
        }
      }
    } catch (e) {
      if (showNoUpdateMessage && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking for updates: $e')),
        );
      }
    }
  }

  static bool _isNewerVersion(String currentVersion, String latestVersion) {
    List<int> currentParts = currentVersion.split('+')[0].split('.').map(int.parse).toList();
    List<int> latestParts = latestVersion.split('+')[0].split('.').map(int.parse).toList();

    for (int i = 0; i < currentParts.length && i < latestParts.length; i++) {
      if (latestParts[i] > currentParts[i]) {
        return true;
      } else if (latestParts[i] < currentParts[i]) {
        return false;
      }
    }
    return latestParts.length > currentParts.length;
  }

  static String _getDownloadUrl(List<dynamic> assets) {
    String fallbackUrl = 'https://github.com/$owner/$repo/releases/latest';
    for (var asset in assets) {
      String name = asset['name'].toString().toLowerCase();
      String url = asset['browser_download_url'];
      if (Platform.isWindows && (name.endsWith('.exe') || name.endsWith('.zip'))) {
        return url;
      } else if (Platform.isAndroid && name.endsWith('.apk')) {
        return url;
      } else if (Platform.isIOS && name.endsWith('.ipa')) {
        return url;
      }
    }
    return fallbackUrl;
  }

  static void _showUpdateDialog(BuildContext context, String version, String releaseNotes, String downloadUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('New Update Available ($version)'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('A new version is available! Release notes:'),
                const SizedBox(height: 8),
                Text(releaseNotes, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () async {
                final Uri url = Uri.parse(downloadUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Update Now'),
            ),
          ],
        );
      },
    );
  }
}
