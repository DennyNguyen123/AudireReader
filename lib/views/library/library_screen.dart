// ignore_for_file: deprecated_member_use, avoid_print
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as path;
import '../../core/database/database_helper.dart';
import '../../core/shortcut_helper.dart';
import '../../core/utils/path_helper.dart';
import '../../models/book.dart';
import '../../models/progress.dart';
import '../../services/epub_parser.dart';
import '../../services/txt_parser.dart';
import '../../services/pdf_parser.dart';
import '../../services/docx_parser.dart';
import '../../services/tts_service.dart' hide print;
import '../reader/reader_screen.dart';
import '../../services/sync_service.dart' hide print;
import '../../services/logger_service.dart';
import '../../services/update_service.dart';
import 'sync_settings_screen.dart';
import '../../l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'widgets/mini_player.dart';
import 'widgets/edit_book_dialog.dart';
import 'global_notes_screen.dart';
import 'widgets/tts_settings_sheet.dart';


class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Book> _books = [];
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _searchHistory = [];
  bool _showSearchHistory = false;

  // Trạng thái lọc và sắp xếp nâng cao
  String? _selectedTag = 'All';
  String? _selectedStatus = 'All';
  String _sortBy = 'lastRead';
  List<String> _allTags = ['All'];
  Map<String, double> _progressMap = {};

  // Trạng thái đồng bộ đám mây WebDAV
  DateTime? _lastSyncTime;
  bool _isSyncing = false;
  bool _webDavEnabled = false;
  String _appVersion = '';
  bool _syncFailed = false;
  bool _isGridView = true;
  TtsService? _ttsService;

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
    _loadAppVersion();
    _loadViewMode();
    _loadSearchHistory();
    
    _searchFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _showSearchHistory = _searchFocusNode.hasFocus;
        });
      }
    });
    
    TtsService.getInstance().then((instance) {
      if (mounted) {
        setState(() {
          _ttsService = instance;
        });
      }
    });
    _loadBooks().then((_) {
      _triggerAutoSync();
      // Tự động mở sách đọc gần nhất sau khi dựng xong frame đầu tiên để tránh lỗi thread điều hướng
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAutoOpenLastRead();
        _checkUpdateOnLaunch();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    const storage = FlutterSecureStorage();
    final historyStr = await storage.read(key: 'search_history');
    if (historyStr != null && historyStr.isNotEmpty) {
      if (mounted) {
        setState(() {
          _searchHistory = historyStr.split('|||');
        });
      }
    }
  }

  Future<void> _addToSearchHistory(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    setState(() {
      _searchHistory.remove(q);
      _searchHistory.insert(0, q);
      if (_searchHistory.length > 10) {
        _searchHistory = _searchHistory.sublist(0, 10);
      }
    });
    const storage = FlutterSecureStorage();
    await storage.write(key: 'search_history', value: _searchHistory.join('|||'));
  }

  Future<void> _removeSearchHistory(String query) async {
    setState(() {
      _searchHistory.remove(query);
    });
    const storage = FlutterSecureStorage();
    await storage.write(key: 'search_history', value: _searchHistory.join('|||'));
  }

  Future<void> _loadViewMode() async {
    const storage = FlutterSecureStorage();
    final viewMode = await storage.read(key: 'library_view_mode') ?? 'grid';
    if (mounted) {
      setState(() {
        _isGridView = viewMode == 'grid';
      });
    }
  }

  Future<void> _toggleViewMode() async {
    setState(() {
      _isGridView = !_isGridView;
    });
    const storage = FlutterSecureStorage();
    await storage.write(key: 'library_view_mode', value: _isGridView ? 'grid' : 'list');
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadSyncStatus() async {
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();
    const storage = FlutterSecureStorage();
    final password = await storage.read(key: 'webdav_password') ?? '';
    if (mounted) {
      setState(() {
        _lastSyncTime = settings.webDavLastSync;
        _webDavEnabled = settings.webDavEnabled &&
            settings.webDavUrl.trim().isNotEmpty &&
            settings.webDavUsername.trim().isNotEmpty &&
            password.trim().isNotEmpty;
      });
    }
  }

  Color _getSyncBadgeColor() {
    if (_syncFailed) {
      return Colors.redAccent;
    }
    if (_lastSyncTime == null) {
      return Colors.amber;
    }
    final now = DateTime.now();
    final difference = now.difference(_lastSyncTime!);
    if (difference.inHours < 24) {
      return Colors.green;
    }
    return Colors.amber;
  }

  String _formatLastSyncTime() {
    if (_lastSyncTime == null) return AppLocalizations.of(context)?.neverSynced ?? 'Never synced';
    final now = DateTime.now();
    final difference = now.difference(_lastSyncTime!);
    
    if (difference.inMinutes < 1) {
      return AppLocalizations.of(context)?.justNow ?? 'Just now';
    } else if (difference.inMinutes < 60) {
      return AppLocalizations.of(context)?.minutesAgo(difference.inMinutes) ?? '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      final hh = _lastSyncTime!.hour.toString().padLeft(2, '0');
      final mm = _lastSyncTime!.minute.toString().padLeft(2, '0');
      return AppLocalizations.of(context)?.todayAt('$hh:$mm') ?? 'Today at $hh:$mm';
    } else {
      final yyyy = _lastSyncTime!.year;
      final mm = _lastSyncTime!.month.toString().padLeft(2, '0');
      final dd = _lastSyncTime!.day.toString().padLeft(2, '0');
      final hour = _lastSyncTime!.hour.toString().padLeft(2, '0');
      final min = _lastSyncTime!.minute.toString().padLeft(2, '0');
      return '$yyyy-$mm-$dd $hour:$min';
    }
  }

  Future<void> _startManualSync() async {
    if (_isSyncing) return;
    
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();
    
    if (!settings.webDavEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.pleaseConfigureWebdav ?? 'Please enable and configure WebDAV in Settings first.'),
            backgroundColor: Colors.amber,
          ),
        );
      }
      return;
    }
    
    setState(() {
      _isSyncing = true;
      _syncFailed = false;
    });
    
    try {
      final result = await SyncService.getInstance().sync();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.success 
                ? (AppLocalizations.of(context)?.syncCompleted ?? 'Sync completed successfully!') 
                : (AppLocalizations.of(context)?.syncFailed(result.message) ?? 'Sync failed: ${result.message}')),
            backgroundColor: result.success ? Colors.green : Colors.redAccent,
          ),
        );
        setState(() {
          _syncFailed = !result.success;
        });
      }
      if (result.success && result.localChanged) {
        await _loadBooks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.syncError(e.toString()) ?? 'Sync error: $e'), 
            backgroundColor: Colors.redAccent
          ),
        );
        setState(() {
          _syncFailed = true;
        });
      }
    } finally {
      await _loadSyncStatus();
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _startForcePush() async {
    if (_isSyncing) return;

    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();

    if (!settings.webDavEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.pleaseConfigureWebdav ?? 'Please enable and configure WebDAV in Settings first.'),
            backgroundColor: Colors.amber,
          ),
        );
      }
      return;
    }

    bool progressOnly = true;

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(AppLocalizations.of(context)?.forcePushConfirmTitle ?? 'Confirm Force Push'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)?.forcePushConfirmDesc ?? 'This action will overwrite all data on the cloud server with the data from this device. Are you sure you want to continue?'),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: Text(AppLocalizations.of(context)?.onlySyncProgress ?? 'Chỉ ghi đè tiến trình đọc'),
                  subtitle: Text(AppLocalizations.of(context)?.onlySyncProgressDesc ?? 'Đồng bộ nhanh tiến trình đọc, giữ nguyên danh mục sách'),
                  value: progressOnly,
                  contentPadding: EdgeInsets.zero,
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (val) {
                    setDialogState(() {
                      progressOnly = val ?? true;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                child: Text(AppLocalizations.of(context)?.confirm ?? 'Confirm'),
              ),
            ],
          );
        }
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isSyncing = true;
      _syncFailed = false;
    });

    try {
      final result = await SyncService.getInstance().forcePush(progressOnly: progressOnly);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.success
                ? (AppLocalizations.of(context)?.forcePushSuccess ?? 'Force push completed successfully!')
                : (AppLocalizations.of(context)?.syncFailed(result.message) ?? 'Force push failed: ${result.message}')),
            backgroundColor: result.success ? Colors.green : Colors.redAccent,
          ),
        );
        setState(() {
          _syncFailed = !result.success;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.syncError(e.toString()) ?? 'Sync error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() {
          _syncFailed = true;
        });
      }
    } finally {
      await _loadSyncStatus();
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _startForcePull() async {
    if (_isSyncing) return;

    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();

    if (!settings.webDavEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.pleaseConfigureWebdav ?? 'Please enable and configure WebDAV in Settings first.'),
            backgroundColor: Colors.amber,
          ),
        );
      }
      return;
    }

    bool progressOnly = true;

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(AppLocalizations.of(context)?.forcePullConfirmTitle ?? 'Confirm Force Pull'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)?.forcePullConfirmDesc ?? 'This action will overwrite all data on this device with the data from the cloud server. Local books and progress not on the cloud will be deleted. Are you sure you want to continue?'),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: Text(AppLocalizations.of(context)?.onlySyncProgress ?? 'Chỉ ghi đè tiến trình đọc'),
                  subtitle: Text(AppLocalizations.of(context)?.onlySyncProgressDesc ?? 'Đồng bộ nhanh tiến trình đọc, giữ nguyên danh mục sách'),
                  value: progressOnly,
                  contentPadding: EdgeInsets.zero,
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (val) {
                    setDialogState(() {
                      progressOnly = val ?? true;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                child: Text(AppLocalizations.of(context)?.confirm ?? 'Confirm'),
              ),
            ],
          );
        }
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isSyncing = true;
      _syncFailed = false;
    });

    try {
      final result = await SyncService.getInstance().forcePull(progressOnly: progressOnly);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.success
                ? (AppLocalizations.of(context)?.forcePullSuccess ?? 'Force pull completed successfully!')
                : (AppLocalizations.of(context)?.syncFailed(result.message) ?? 'Force pull failed: ${result.message}')),
            backgroundColor: result.success ? Colors.green : Colors.redAccent,
          ),
        );
        setState(() {
          _syncFailed = !result.success;
        });
      }
      if (result.success && result.localChanged) {
        await _loadBooks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.syncError(e.toString()) ?? 'Sync error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() {
          _syncFailed = true;
        });
      }
    } finally {
      await _loadSyncStatus();
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _startForcePushBook(Book book) async {
    if (_isSyncing) return;

    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();

    if (!settings.webDavEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.pleaseConfigureWebdav ?? 'Please enable and configure WebDAV in Settings first.'),
            backgroundColor: Colors.amber,
          ),
        );
      }
      return;
    }

    bool progressOnly = true;

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(AppLocalizations.of(context)?.forcePushBookConfirmTitle ?? 'Confirm Force Push Book'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)?.forcePushBookConfirmDesc ?? 'This action will overwrite this book and its reading progress on the WebDAV cloud. Are you sure you want to continue?'),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: Text(AppLocalizations.of(context)?.onlySyncProgress ?? 'Chỉ ghi đè tiến trình đọc'),
                  subtitle: Text(AppLocalizations.of(context)?.onlySyncProgressDesc ?? 'Đồng bộ nhanh tiến trình đọc, giữ nguyên danh mục sách'),
                  value: progressOnly,
                  contentPadding: EdgeInsets.zero,
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (val) {
                    setDialogState(() {
                      progressOnly = val ?? true;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                child: Text(AppLocalizations.of(context)?.confirm ?? 'Confirm'),
              ),
            ],
          );
        }
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isSyncing = true;
      _syncFailed = false;
    });

    try {
      final result = await SyncService.getInstance().forcePushBook(book.uuid, progressOnly: progressOnly);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.success
                ? (AppLocalizations.of(context)?.forcePushBookSuccess(book.title) ?? 'Successfully pushed book "${book.title}" to cloud.')
                : (AppLocalizations.of(context)?.forcePushBookFailed(result.message) ?? 'Failed to push book: ${result.message}')),
            backgroundColor: result.success ? Colors.green : Colors.redAccent,
          ),
        );
        setState(() {
          _syncFailed = !result.success;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.forcePushBookFailed(e.toString()) ?? 'Failed to push book: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() {
          _syncFailed = true;
        });
      }
    } finally {
      await _loadSyncStatus();
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _startForcePullBook(Book book) async {
    if (_isSyncing) return;

    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();

    if (!settings.webDavEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.pleaseConfigureWebdav ?? 'Please enable and configure WebDAV in Settings first.'),
            backgroundColor: Colors.amber,
          ),
        );
      }
      return;
    }

    bool progressOnly = true;

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(AppLocalizations.of(context)?.forcePullBookConfirmTitle ?? 'Confirm Force Pull Book'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)?.forcePullBookConfirmDesc ?? 'This action will download this book and its reading progress from the WebDAV cloud to overwrite local data. Are you sure you want to continue?'),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: Text(AppLocalizations.of(context)?.onlySyncProgress ?? 'Chỉ ghi đè tiến trình đọc'),
                  subtitle: Text(AppLocalizations.of(context)?.onlySyncProgressDesc ?? 'Đồng bộ nhanh tiến trình đọc, giữ nguyên danh mục sách'),
                  value: progressOnly,
                  contentPadding: EdgeInsets.zero,
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (val) {
                    setDialogState(() {
                      progressOnly = val ?? true;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                child: Text(AppLocalizations.of(context)?.confirm ?? 'Confirm'),
              ),
            ],
          );
        }
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isSyncing = true;
      _syncFailed = false;
    });

    try {
      final result = await SyncService.getInstance().forcePullBook(book.uuid, progressOnly: progressOnly);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.success
                ? (AppLocalizations.of(context)?.forcePullBookSuccess(book.title) ?? 'Successfully pulled book "${book.title}" to local.')
                : (AppLocalizations.of(context)?.forcePullBookFailed(result.message) ?? 'Failed to pull book: ${result.message}')),
            backgroundColor: result.success ? Colors.green : Colors.redAccent,
          ),
        );
        setState(() {
          _syncFailed = !result.success;
        });
      }
      if (result.success && result.localChanged) {
        await _loadBooks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.forcePullBookFailed(e.toString()) ?? 'Failed to pull book: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() {
          _syncFailed = true;
        });
      }
    } finally {
      await _loadSyncStatus();
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _checkUpdateOnLaunch() async {
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();
    if (settings.autoCheckUpdate && mounted) {
      UpdateService.checkForUpdate(context);
    }
  }

  Future<void> _checkAutoOpenLastRead() async {
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();
    
    if (settings.openLastReadOnLaunch) {
      // Tìm tiến trình đọc gần đây nhất
      final progressList = await db.isar.readingProgress
          .where()
          .sortByLastReadDesc()
          .findAll();
          
      if (progressList.isNotEmpty) {
        final lastProgress = progressList.first;
        final book = await db.getBookByUuid(lastProgress.bookUuid);
        if (book != null && mounted) {
          _openBook(book);
        }
      }
    }
  }

  Future<void> _triggerAutoSync() async {
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();
    if (settings.webDavEnabled) {
      setState(() {
        _isSyncing = true;
      });
      SyncService.getInstance().sync().then((result) {
        if (result.success && result.localChanged) {
          _loadBooks();
        }
        _loadSyncStatus();
        if (mounted) {
          setState(() {
            _isSyncing = false;
          });
        }
      }).catchError((e) {
        _loadSyncStatus();
        if (mounted) {
          setState(() {
            _isSyncing = false;
          });
        }
      });
    }
  }

  Future<void> _loadBooks() async {
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();
    
    final books = await db.getBooks(
      tag: (_selectedTag == 'All' || _selectedTag == null) ? null : _selectedTag,
      status: (_selectedStatus == 'All' || _selectedStatus == null) ? null : _selectedStatus,
      sortBy: settings.sortBy,
    );
    
    final tags = await db.getAllBookTags();
    
    final Map<String, double> pMap = {};
    for (final book in books) {
      final progress = await db.getProgress(book.uuid);
      if (progress != null && book.totalChapters > 0) {
        final percent = (progress.currentChapterIndex / book.totalChapters) * 100;
        pMap[book.uuid] = percent.clamp(0.0, 100.0);
      } else {
        pMap[book.uuid] = 0.0;
      }
    }
    
    if (mounted) {
      setState(() {
        _books = books;
        _sortBy = settings.sortBy;
        _allTags = ['All', ...tags];
        _progressMap = pMap;
      });
    }
  }

  void _showSortMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context)?.sortBooks ?? 'Sort Books',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.access_time_rounded, color: _sortBy == 'lastRead' ? Colors.amber[700] : null),
              title: Text(AppLocalizations.of(context)?.sortByLastRead ?? 'Sort by Last Read', style: TextStyle(color: _sortBy == 'lastRead' ? Colors.amber[700] : null, fontWeight: _sortBy == 'lastRead' ? FontWeight.bold : null)),
              onTap: () => _updateSortBy('lastRead'),
            ),
            ListTile(
              leading: Icon(Icons.sort_by_alpha_rounded, color: _sortBy == 'title' ? Colors.amber[700] : null),
              title: Text(AppLocalizations.of(context)?.sortByTitle ?? 'Sort by Title', style: TextStyle(color: _sortBy == 'title' ? Colors.amber[700] : null, fontWeight: _sortBy == 'title' ? FontWeight.bold : null)),
              onTap: () => _updateSortBy('title'),
            ),
            ListTile(
              leading: Icon(Icons.calendar_today_rounded, color: _sortBy == 'dateAdded' ? Colors.amber[700] : null),
              title: Text(AppLocalizations.of(context)?.sortByDateAdded ?? 'Sort by Date Added', style: TextStyle(color: _sortBy == 'dateAdded' ? Colors.amber[700] : null, fontWeight: _sortBy == 'dateAdded' ? FontWeight.bold : null)),
              onTap: () => _updateSortBy('dateAdded'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateSortBy(String type) async {
    Navigator.pop(context);
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();
    settings.sortBy = type;
    await db.saveSettings(settings);
    await _loadBooks();
  }

  Future<void> _importBook() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub', 'txt', 'pdf', 'docx'],
      );

      if (result == null || result.files.single.path == null) return;

      setState(() {
        _isLoading = true;
      });

      final filePath = result.files.single.path!;
      final docDir = await PathHelper.getAppDirectory();

      // Chạy parser trong background isolate để tránh đơ giao diện
      final parsedData = await compute(
        _parseBookIsolate,
        {
          'filePath': filePath,
          'docDirPath': docDir.path,
        },
      );

      final db = await DatabaseHelper.getInstance();
      await db.saveBook(parsedData.book);
      await db.saveChapters(parsedData.chapters);

      await _loadBooks();
      _triggerAutoSync();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.successfullyImported(parsedData.book.title) ?? 'Successfully imported "${parsedData.book.title}"!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.failedToImport(e.toString()) ?? 'Failed to import book: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Hàm chạy riêng trong isolate
  static Future<ParsedBookData> _parseBookIsolate(Map<String, String> args) async {
    final filePath = args['filePath']!;
    final docDirPath = args['docDirPath']!;
    final extension = path.extension(filePath).toLowerCase();

    if (extension == '.epub') {
      return await EpubParser.parseEpubFile(filePath, docDirPath);
    } else if (extension == '.txt') {
      return await TxtParser.parseTxtFile(filePath);
    } else if (extension == '.pdf') {
      return await PdfParser.parsePdfFile(filePath);
    } else if (extension == '.docx') {
      return await DocxParser.parseDocxFile(filePath);
    } else {
      throw Exception("Unsupported file format");
    }
  }

  Future<void> _deleteBook(Book book) async {
    final db = await DatabaseHelper.getInstance();
    await db.deleteBook(book.uuid);
    await _loadBooks();

    // Tự động kích hoạt xóa sách trên WebDAV đám mây nếu cấu hình bật
    final settings = await db.getSettings();
    if (settings.webDavEnabled) {
      SyncService.getInstance().deleteBookFromCloud(book.uuid).then((result) {
        LoggerService().log('[Sync] Cloud deletion result for "${book.title}": ${result.message}', tag: 'SYNC', level: LogLevel.info);
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.deleteBookConfirm(book.title) ?? 'Deleted "${book.title}"')),
      );
    }
  }

  Future<void> _openBook(Book book) async {
    final db = await DatabaseHelper.getInstance();
    
    if (book.status == 'unread') {
      book.status = 'reading';
      await db.saveBook(book);
    }

    final chapters = await db.getChaptersForBook(book.uuid);
    final progress = await db.getProgress(book.uuid);

    final ttsService = await TtsService.getInstance();
    
    int startChapter = progress?.currentChapterIndex ?? 0;
    int startParagraph = progress?.currentParagraphIndex ?? 0;

    // Đảm bảo chỉ số nằm trong phạm vi hợp lệ
    if (startChapter >= chapters.length) {
      startChapter = 0;
      startParagraph = 0;
    } else if (chapters.isNotEmpty && startParagraph >= chapters[startChapter].paragraphs.length) {
      startParagraph = 0;
    }

    await ttsService.loadBook(
      book,
      chapters,
      startChapter: startChapter,
      startParagraph: startParagraph,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ReaderScreen(),
        ),
      ).then((_) {
        // Tải lại sách để cập nhật tiến độ đọc
        _loadBooks();
        _triggerAutoSync();
      });
    }
  }

  // --- Hotkeys & Boss Key Handlers ---
  Future<void> _handleOpenSettingShortcut() async {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SyncSettingsScreen(),
      ),
    ).then((_) {
      _loadBooks();
      _loadSyncStatus();
      _triggerAutoSync();
    });
  }



  Future<Map<ShortcutActivator, VoidCallback>> _buildLibraryShortcuts() async {
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();
    return {
      ShortcutHelper.parse(settings.hotkeyOpenSetting): _handleOpenSettingShortcut,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = theme.colorScheme.primary;

    final filteredBooks = _books.where((book) {
      final searchLower = _searchQuery.toLowerCase();
      return book.title.toLowerCase().contains(searchLower) ||
             book.author.toLowerCase().contains(searchLower);
    }).toList();

    final scaffoldContent = Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.png',
                width: 32,
                height: 32,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                AppLocalizations.of(context)?.appTitle ?? 'Audire Reader',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  letterSpacing: -0.5,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        actions: [
          if (_webDavEnabled && !_isSyncing) ...[
            Tooltip(
              message: AppLocalizations.of(context)?.forcePush ?? 'Force Push (Local -> Cloud)',
              child: IconButton(
                icon: const Icon(Icons.cloud_upload_rounded),
                onPressed: _startForcePush,
              ),
            ),
            Tooltip(
              message: AppLocalizations.of(context)?.forcePull ?? 'Force Pull (Cloud -> Local)',
              child: IconButton(
                icon: const Icon(Icons.cloud_download_rounded),
                onPressed: _startForcePull,
              ),
            ),
          ],
          if (_webDavEnabled)
            _isSyncing
                ? SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                        ),
                      ),
                    ),
                  )
                : Tooltip(
                    message: _lastSyncTime == null
                        ? (AppLocalizations.of(context)?.lastSyncedNever ?? 'Last Synced: Never')
                        : (AppLocalizations.of(context)?.lastSyncedAt(_formatLastSyncTime()) ?? 'Last Synced: ${_formatLastSyncTime()}'),
                    child: IconButton(
                      icon: Badge(
                        backgroundColor: _getSyncBadgeColor(),
                        child: const Icon(Icons.sync_rounded),
                      ),
                      onPressed: _startManualSync,
                    ),
                  ),
          IconButton(
            icon: const Icon(Icons.bookmarks_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GlobalNotesScreen()),
              ).then((_) {
                _loadBooks();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.headphones_rounded),
            tooltip: 'TTS Settings',
            onPressed: () {
              showTtsSettingsBottomSheet(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SyncSettingsScreen(),
                ),
              ).then((_) {
                _loadBooks();
                _loadSyncStatus();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: _showAboutDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_books.isNotEmpty || _selectedTag != 'All' || _selectedStatus != 'All')
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)?.searchBookHint ?? 'Search book on shelf...',
                              hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4)),
                              prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4)),
                              suffixIcon: _searchQuery.isNotEmpty ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() { _searchQuery = ''; });
                                },
                              ) : null,
                              filled: true,
                              fillColor: Theme.of(context).cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                            onSubmitted: (val) {
                              _addToSearchHistory(val);
                            },
                          ),
                          if (_showSearchHistory && _searchHistory.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: _searchHistory.map((query) => ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.history, size: 20),
                                  title: Text(query),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: () => _removeSearchHistory(query),
                                  ),
                                  onTap: () {
                                    _searchController.text = query;
                                    setState(() { _searchQuery = query; });
                                    _addToSearchHistory(query);
                                    _searchFocusNode.unfocus();
                                  },
                                )).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Row(
                              children: [
                                _buildFilterChip(AppLocalizations.of(context)?.all ?? 'All', _selectedStatus == 'All', (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedStatus = 'All';
                                    });
                                    _loadBooks();
                                  }
                                }),
                                const SizedBox(width: 8),
                                _buildFilterChip(AppLocalizations.of(context)?.unread ?? 'Unread', _selectedStatus == 'unread', (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedStatus = 'unread';
                                    });
                                    _loadBooks();
                                  }
                                }),
                                const SizedBox(width: 8),
                                _buildFilterChip(AppLocalizations.of(context)?.reading ?? 'Reading', _selectedStatus == 'reading', (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedStatus = 'reading';
                                    });
                                    _loadBooks();
                                  }
                                }),
                                const SizedBox(width: 8),
                                _buildFilterChip(AppLocalizations.of(context)?.completed ?? 'Completed', _selectedStatus == 'completed', (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedStatus = 'completed';
                                    });
                                    _loadBooks();
                                  }
                                }),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Tooltip(
                            message: _isGridView ? 'List View' : 'Grid View',
                            child: IconButton(
                              icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded, size: 20),
                              onPressed: _toggleViewMode,
                              style: IconButton.styleFrom(
                                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                                foregroundColor: isDark ? Colors.white70 : Colors.black87,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Tooltip(
                            message: AppLocalizations.of(context)?.sortOptions ?? 'Sort options',
                            child: IconButton(
                              icon: const Icon(Icons.sort_rounded, size: 20),
                              onPressed: _showSortMenu,
                              style: IconButton.styleFrom(
                                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                                foregroundColor: isDark ? Colors.white70 : Colors.black87,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_allTags.length > 1)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Row(
                          children: _allTags.map((tag) {
                            final isSelected = _selectedTag == tag;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(tag, style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontSize: 12)),
                                selected: isSelected,
                                selectedColor: accentColor,
                                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                showCheckmark: false,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedTag = tag;
                                    });
                                    _loadBooks();
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              Expanded(
                child: _books.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              size: 80,
                              color: isDark ? Colors.white30 : Colors.black26,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)?.emptyShelf ?? 'Your shelf is empty',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context)?.importBookHint ?? 'Tap the "+" button to import a book (.epub, .txt, .pdf, .docx)',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      )
                    : filteredBooks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 80,
                                  color: isDark ? Colors.white30 : Colors.black26,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(context)?.noBooksMatch ?? 'No books match your search',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white54 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            child: _isGridView 
                                ? _buildGridView(filteredBooks, isDark)
                                : _buildListView(filteredBooks, isDark),
                          ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)?.parsingBookContent ?? 'Parsing book content...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: true,
              child: MiniPlayer(),
            ),
          ),
          StreamBuilder<MediaItem?>(
            stream: _ttsService?.audioHandler.mediaItem,
            builder: (context, mediaItemSnapshot) {
              final mediaItem = mediaItemSnapshot.data;
              return StreamBuilder<PlaybackState>(
                stream: _ttsService?.audioHandler.playbackState,
                builder: (context, playbackStateSnapshot) {
                  final playbackState = playbackStateSnapshot.data;
                  final hasActiveBook = _ttsService?.activeBook != null;
                  final isIdle = playbackState?.processingState == AudioProcessingState.idle;
                  
                  final bool showMiniPlayer = _ttsService != null && 
                      mediaItem != null && 
                      hasActiveBook && 
                      !isIdle;

                  final double fabBottom = showMiniPlayer ? 96.0 : 16.0;

                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    bottom: fabBottom + MediaQuery.of(context).padding.bottom,
                    right: 16,
                    child: FloatingActionButton.extended(
                      onPressed: _importBook,
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(
                        AppLocalizations.of(context)?.importBook ?? 'Import Book',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );

    return FutureBuilder<Map<ShortcutActivator, VoidCallback>>(
      future: _buildLibraryShortcuts(),
      builder: (context, snapshot) {
        final bindings = snapshot.data;
        if (bindings == null) {
          return scaffoldContent;
        }

        return CallbackShortcuts(
          bindings: bindings,
          child: Focus(
            autofocus: true,
            child: scaffoldContent,
          ),
        );
      },
    );
  }

  Widget _buildBookCard(Book book, bool isDark) {
    final progressPercent = _progressMap[book.uuid] ?? 0.0;
    final bookStatus = book.status.trim().isEmpty ? 'unread' : book.status;
    final accentColor = Theme.of(context).colorScheme.primary;
    
    Color statusColor = Colors.grey;
    if (bookStatus == 'reading') statusColor = accentColor;
    if (bookStatus == 'completed') statusColor = Colors.green;

    return GestureDetector(
      onTap: () => _openBook(book),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black45 : Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Builder(
                    builder: (context) {
                      final hasPath = book.coverPath != null && book.coverPath!.isNotEmpty;
                      final fileExists = hasPath ? File(book.coverPath!).existsSync() : false;
                      print('[LibraryScreen] Card "${book.title}" -> hasPath: $hasPath, exists: $fileExists, path: ${book.coverPath}');
                      
                      if (hasPath && fileExists) {
                        return Image.file(
                          File(book.coverPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('[LibraryScreen] Error loading image for "${book.title}": $error');
                            return Container(
                              color: isDark ? Colors.grey[850] : Colors.grey[300],
                              child: Icon(
                                Icons.book_rounded,
                                size: 40,
                                color: isDark ? Colors.white30 : Colors.black38,
                              ),
                            );
                          },
                        );
                      } else {
                        return Container(
                          color: isDark ? Colors.grey[850] : Colors.grey[300],
                          child: Icon(
                            Icons.book_rounded,
                            size: 40,
                            color: isDark ? Colors.white30 : Colors.black38,
                          ),
                        );
                      }
                    },
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        bookStatus.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  ValueListenableBuilder<Map<String, String>>(
                    valueListenable: SyncService.getInstance().syncStateNotifier,
                    builder: (context, syncState, child) {
                      final status = syncState[book.uuid];
                      if (status == null) return const SizedBox.shrink();
                      
                      if (status == 'syncing') {
                        return Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const SizedBox(
                              width: 12, height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                            ),
                          ),
                        );
                      } else if (status == 'success') {
                        return Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                            child: const Icon(Icons.check, size: 12, color: Colors.white),
                          ),
                        );
                      } else if (status == 'error') {
                        return Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black54,
                        ),
                        child: const Icon(
                          Icons.more_vert_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          final result = await showDialog<bool>(
                            context: context,
                            builder: (context) => EditBookDialog(book: book),
                          );
                          if (result == true) {
                            _loadBooks();
                          }
                        } else if (value == 'delete') {
                          _showDeleteConfirm(book);
                        } else if (value == 'force_push') {
                          _startForcePushBook(book);
                        } else if (value == 'force_pull') {
                          _startForcePullBook(book);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_rounded, size: 18),
                              const SizedBox(width: 8),
                              const Text(
                                'Edit Book',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)?.deleteBook ?? 'Delete Book',
                                style: const TextStyle(color: Colors.red, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        if (_webDavEnabled) ...[
                          PopupMenuItem(
                            value: 'force_push',
                            child: Row(
                              children: [
                                const Icon(Icons.cloud_upload_rounded, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context)?.forcePushBook ?? 'Force Push Book',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'force_pull',
                            child: Row(
                              children: [
                                const Icon(Icons.cloud_download_rounded, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context)?.forcePullBook ?? 'Force Pull Book',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: progressPercent / 100,
                      backgroundColor: Colors.black26,
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      minHeight: 3,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 80,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: -0.2,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.chaptersCount(book.totalChapters) ?? '${book.totalChapters} Chapters',
                        style: TextStyle(
                          fontSize: 9,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)?.readPercent(progressPercent.toStringAsFixed(0)) ?? '${progressPercent.toStringAsFixed(0)}% Read',
                        style: TextStyle(
                          fontSize: 9,
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.confirmDelete ?? 'Confirm Delete'),
        content: Text(AppLocalizations.of(context)?.confirmDeleteBook(book.title) ?? 'Are you sure you want to delete "${book.title}"? This will erase all chapter caches and reading progress.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteBook(book);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)?.delete ?? 'Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, ValueChanged<bool> onSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.primary;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontSize: 12, fontWeight: FontWeight.w600)),
      selected: isSelected,
      selectedColor: accentColor,
      backgroundColor: isDark ? Colors.white10 : Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
      onSelected: onSelected,
    );
  }

  void _showAboutDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 64,
                  height: 64,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)?.appTitle ?? 'Audire Reader',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context)?.version(_appVersion.isEmpty ? '1.1.12' : _appVersion) ?? 'Version ${_appVersion.isEmpty ? '1.1.12' : _appVersion}',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, thickness: 1),
              const SizedBox(height: 16),
              _buildInfoRow('Author', 'Denny Nguyen', isDark),
              const SizedBox(height: 10),
              _buildInfoRow('License', 'MIT License', isDark),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  final Uri url = Uri.parse('https://github.com/DennyNguyen123/AudireReader');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GitHub',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'github.com/DennyNguyen123/AudireReader',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber[700],
                            decoration: TextDecoration.underline,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                AppLocalizations.of(context)?.close ?? 'Close',
                style: TextStyle(
                  color: Colors.amber[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildGridView(List<Book> filteredBooks, bool isDark) {
    return LayoutBuilder(
      key: const ValueKey('grid_view_key'),
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final int crossAxisCount = (width / 160).floor().clamp(2, 8);
        
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.58,
          ),
          itemCount: filteredBooks.length,
          itemBuilder: (context, index) {
            final book = filteredBooks[index];
            return _buildBookCard(book, isDark);
          },
        );
      },
    );
  }

  Widget _buildListView(List<Book> filteredBooks, bool isDark) {
    return ListView.builder(
      key: const ValueKey('list_view_key'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredBooks.length,
      itemBuilder: (context, index) {
        final book = filteredBooks[index];
        return _buildBookListItem(book, isDark);
      },
    );
  }

  Widget _buildBookListItem(Book book, bool isDark) {
    final progressPercent = _progressMap[book.uuid] ?? 0.0;
    final bookStatus = book.status.trim().isEmpty ? 'unread' : book.status;
    
    Color statusColor = Colors.grey;
    if (bookStatus == 'reading') statusColor = Theme.of(context).colorScheme.primary;
    if (bookStatus == 'completed') statusColor = Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openBook(book),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                height: 84,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Builder(
                        builder: (context) {
                          final hasPath = book.coverPath != null && book.coverPath!.isNotEmpty;
                          final fileExists = hasPath ? File(book.coverPath!).existsSync() : false;
                          if (hasPath && fileExists) {
                            return Image.file(
                              File(book.coverPath!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: isDark ? Colors.grey[850] : Colors.grey[300],
                                  child: Icon(
                                    Icons.book_rounded,
                                    size: 24,
                                    color: isDark ? Colors.white30 : Colors.black38,
                                  ),
                                );
                              },
                            );
                          } else {
                            return Container(
                              color: isDark ? Colors.grey[850] : Colors.grey[300],
                              child: Icon(
                                Icons.book_rounded,
                                size: 24,
                                color: isDark ? Colors.white30 : Colors.black38,
                              ),
                            );
                          }
                        },
                      ),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            bookStatus.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 6,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      ValueListenableBuilder<Map<String, String>>(
                        valueListenable: SyncService.getInstance().syncStateNotifier,
                        builder: (context, syncState, child) {
                          final status = syncState[book.uuid];
                          if (status == null) return const SizedBox.shrink();
                          
                          if (status == 'syncing') {
                            return Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: const SizedBox(
                                  width: 10, height: 10,
                                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                ),
                              ),
                            );
                          } else if (status == 'success') {
                            return Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                child: const Icon(Icons.check, size: 10, color: Colors.white),
                              ),
                            );
                          } else if (status == 'error') {
                            return Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 10, color: Colors.white),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)?.chaptersCount(book.totalChapters) ?? '${book.totalChapters} Chapters',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          AppLocalizations.of(context)?.readPercent(progressPercent.toStringAsFixed(0)) ?? '${progressPercent.toStringAsFixed(0)}% Read',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressPercent / 100,
                        backgroundColor: isDark ? Colors.white10 : Colors.black12,
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: isDark ? Colors.white54 : Colors.black54,
                  size: 20,
                ),
                onSelected: (value) async {
                  if (value == 'edit') {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => EditBookDialog(book: book),
                    );
                    if (result == true) {
                      _loadBooks();
                    }
                  } else if (value == 'delete') {
                    _showDeleteConfirm(book);
                  } else if (value == 'force_push') {
                    _startForcePushBook(book);
                  } else if (value == 'force_pull') {
                    _startForcePullBook(book);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_rounded, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Edit Book',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)?.deleteBook ?? 'Delete Book',
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (_webDavEnabled) ...[
                    PopupMenuItem(
                      value: 'force_push',
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_upload_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)?.forcePushBook ?? 'Force Push Book',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'force_pull',
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_download_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)?.forcePullBook ?? 'Force Pull Book',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
