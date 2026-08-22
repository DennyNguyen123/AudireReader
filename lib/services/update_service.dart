import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';

class UpdateService {
  static const String owner = 'DennyNguyen123';
  static const String repo = 'AudireReader';

  static Future<void> checkForUpdate(
    BuildContext context, {
    bool showNoUpdateMessage = false,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String latestVersionTag = data['tag_name'] ?? '';
        final String latestVersion = latestVersionTag.replaceAll('v', '');

        final PackageInfo packageInfo = await PackageInfo.fromPlatform();
        final String currentVersion = packageInfo.version;

        if (isNewerVersion(currentVersion, latestVersion)) {
          final String body = data['body'] ?? 'No release notes available.';
          final String downloadUrl = getDownloadUrl(data['assets'] ?? []);

          if (context.mounted) {
            _showUpdateDialog(context, latestVersion, body, downloadUrl);
          }
        } else {
          if (showNoUpdateMessage && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You are on the latest version.')),
            );
          }
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

  @visibleForTesting
  static bool isNewerVersion(String currentVersion, String latestVersion) {
    if (latestVersion.isEmpty) return false;
    List<int> currentParts = currentVersion
        .split('+')[0]
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    List<int> latestParts = latestVersion
        .split('+')[0]
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    for (int i = 0; i < currentParts.length && i < latestParts.length; i++) {
      if (latestParts[i] > currentParts[i]) {
        return true;
      } else if (latestParts[i] < currentParts[i]) {
        return false;
      }
    }
    return latestParts.length > currentParts.length;
  }

  @visibleForTesting
  static String getDownloadUrl(List<dynamic> assets) {
    String fallbackUrl = 'https://github.com/$owner/$repo/releases/latest';

    if (kIsWeb) return fallbackUrl;

    if (Platform.isWindows) {
      for (var asset in assets) {
        String name = asset['name'].toString().toLowerCase();
        if (name.endsWith('-setup.exe') || name.endsWith('.exe')) {
          return asset['browser_download_url'];
        }
      }
      for (var asset in assets) {
        String name = asset['name'].toString().toLowerCase();
        if (name.endsWith('.zip')) {
          return asset['browser_download_url'];
        }
      }
    } else if (Platform.isAndroid) {
      for (var asset in assets) {
        String name = asset['name'].toString().toLowerCase();
        if (name.endsWith('.apk')) {
          return asset['browser_download_url'];
        }
      }
    } else if (Platform.isIOS || Platform.isMacOS) {
      for (var asset in assets) {
        String name = asset['name'].toString().toLowerCase();
        if (name.endsWith('.ipa')) {
          return asset['browser_download_url'];
        }
      }
    }

    return fallbackUrl;
  }

  static void _showUpdateDialog(
    BuildContext context,
    String version,
    String releaseNotes,
    String downloadUrl,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _UpdateDialogContent(
        version: version,
        releaseNotes: releaseNotes,
        downloadUrl: downloadUrl,
      ),
    );
  }
}

class _UpdateDialogContent extends StatefulWidget {
  final String version;
  final String releaseNotes;
  final String downloadUrl;

  const _UpdateDialogContent({
    required this.version,
    required this.releaseNotes,
    required this.downloadUrl,
  });

  @override
  State<_UpdateDialogContent> createState() => _UpdateDialogContentState();
}

class _UpdateDialogContentState extends State<_UpdateDialogContent> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String? _statusText;

  Future<void> _handleWindowsUpdate() async {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _statusText = 'Downloading installer...';
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final targetFile = File(p.join(tempDir.path, 'AudireReader-Update-Setup.exe'));

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(widget.downloadUrl));
      final response = await client.send(request);

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      final sink = targetFile.openWrite();
      await response.stream.listen((chunk) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0 && mounted) {
          setState(() {
            _progress = receivedBytes / totalBytes;
          });
        }
      }).asFuture();

      await sink.flush();
      await sink.close();
      client.close();

      if (mounted) {
        setState(() {
          _statusText = 'Starting installer...';
        });
      }

      // Kích hoạt silent installer và tự khởi động lại app mới
      await Process.start(
        targetFile.path,
        ['/SILENT', '/CLOSEAPPLICATIONS', '/RESTARTAPPLICATIONS'],
        mode: ProcessStartMode.detached,
        runInShell: true,
      );

      // Thoát tiến trình hiện tại để installer làm việc
      exit(0);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusText = 'Update failed: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  Future<void> _handleIosShare() async {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _statusText = 'Downloading IPA file...';
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final targetFile = File(p.join(tempDir.path, 'AudireReader-iOS.ipa'));

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(widget.downloadUrl));
      final response = await client.send(request);

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      final sink = targetFile.openWrite();
      await response.stream.listen((chunk) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0 && mounted) {
          setState(() {
            _progress = receivedBytes / totalBytes;
          });
        }
      }).asFuture();

      await sink.flush();
      await sink.close();
      client.close();

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusText = null;
        });

        // Mở iOS Share Sheet để chia sẻ file trực tiếp sang KSign, ESign, TrollStore,...
        await Share.shareXFiles(
          [XFile(targetFile.path)],
          text: 'Audire Reader iOS Update',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusText = 'Download failed: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download IPA: $e')),
        );
      }
    }
  }

  void _copyIpaLink(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: widget.downloadUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _openBrowser() async {
    final Uri url = Uri.parse(widget.downloadUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final titleText = 'New Update Available (${widget.version})';
    final installText = l10n?.installUpdate ?? 'Update Now';
    final openSignerText = l10n?.openInSigner ?? 'Download & Open in Signer';
    final copyLinkText = l10n?.copyIpaLink ?? 'Copy Link';
    final copiedText = l10n?.ipaLinkCopied ?? 'Link copied to clipboard!';
    final browserText = l10n?.openInBrowser ?? 'Open in Browser';
    final cancelText = l10n?.cancel ?? 'Later';

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.system_update_alt_rounded,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      titleText,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Release Notes
              const Text(
                'Release Notes:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    widget.releaseNotes,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Downloading Indicator
              if (_isDownloading) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _statusText ?? 'Downloading...',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${(_progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _progress > 0 ? _progress : null,
                      backgroundColor: isDark ? Colors.white12 : Colors.black12,
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ],

              // Actions
              if (!_isDownloading) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!kIsWeb && Platform.isWindows) ...[
                      FilledButton.icon(
                        onPressed: _handleWindowsUpdate,
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: Text(installText, style: const TextStyle(fontWeight: FontWeight.bold)),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ] else if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) ...[
                      FilledButton.icon(
                        onPressed: _handleIosShare,
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: Text(openSignerText, style: const TextStyle(fontWeight: FontWeight.bold)),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _copyIpaLink(context, copiedText),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: Text(copyLinkText),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ] else ...[
                      FilledButton.icon(
                        onPressed: _openBrowser,
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: Text(installText, style: const TextStyle(fontWeight: FontWeight.bold)),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _copyIpaLink(context, copiedText),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: Text(copyLinkText),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _openBrowser,
                          child: Text(
                            browserText,
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            cancelText,
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
