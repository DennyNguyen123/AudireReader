import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/sync_service.dart';

class SyncHistoryScreen extends StatefulWidget {
  const SyncHistoryScreen({super.key});

  @override
  State<SyncHistoryScreen> createState() => _SyncHistoryScreenState();
}

class _SyncHistoryScreenState extends State<SyncHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await SyncService.getInstance().getSyncHistory();
      if (mounted) {
        setState(() {
          _history = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatTimestamp(BuildContext context, String timestampStr) {
    try {
      final dt = DateTime.parse(timestampStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      final locale = Localizations.localeOf(context).languageCode;
      final isVi = locale == 'vi';

      if (diff.inSeconds < 60) {
        return isVi ? 'Vừa xong' : 'Just now';
      }
      if (diff.inMinutes < 60) {
        return isVi ? '${diff.inMinutes} phút trước' : '${diff.inMinutes}m ago';
      }
      if (diff.inHours < 24) {
        return isVi ? '${diff.inHours} giờ trước' : '${diff.inHours}h ago';
      }
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return timestampStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;
    final isVi = locale == 'vi';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isVi ? 'Lịch sử đồng bộ' : 'Sync History',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off_rounded,
                    size: 64,
                    color: isDark ? Colors.white30 : Colors.black26,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isVi ? 'Không có lịch sử đồng bộ' : 'No sync history found',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _history.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _history[index];
                final action = item['action'] as String? ?? 'push';
                final isPush = action == 'push';

                final timestamp = item['timestamp'] as String? ?? '';
                final deviceName =
                    item['deviceName'] as String? ?? 'Unknown Device';
                final bookTitle =
                    item['bookTitle'] as String? ?? 'Unknown Book';
                final chapterIndex =
                    (item['chapterIndex'] as num?)?.toInt() ?? 0;
                final paragraphIndex =
                    (item['paragraphIndex'] as num?)?.toInt() ?? 0;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isPush
                        ? Colors.green.withOpacity(0.15)
                        : Colors.orange.withOpacity(0.15),
                    child: Icon(
                      isPush
                          ? Icons.cloud_upload_rounded
                          : Icons.cloud_download_rounded,
                      color: isPush ? Colors.green : Colors.orange,
                    ),
                  ),
                  title: Text(
                    bookTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isVi
                              ? 'Thiết bị: $deviceName'
                              : 'Device: $deviceName',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isVi
                              ? 'Tiến trình: Chương ${chapterIndex + 1}, Đoạn ${paragraphIndex + 1}'
                              : 'Progress: Ch ${chapterIndex + 1}, Paragraph ${paragraphIndex + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Text(
                    _formatTimestamp(context, timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white30 : Colors.black38,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
