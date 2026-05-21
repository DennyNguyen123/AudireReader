// ignore_for_file: deprecated_member_use, avoid_print
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Book> _books = [];
  bool _isLoading = false;
  String _searchQuery = '';

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

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
    _loadAppVersion();
    _loadBooks().then((_) {
      _triggerAutoSync();
      // Tự động mở sách đọc gần nhất sau khi dựng xong frame đầu tiên để tránh lỗi thread điều hướng
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAutoOpenLastRead();
        _checkUpdateOnLaunch();
      });
    });
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
    // Tông màu tối hiện đại, cao cấp
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[700]!),
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
                      child: TextField(
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)?.searchBookHint ?? 'Search book on shelf...',
                          hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4)),
                          prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4)),
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
                                selectedColor: Colors.amber[700],
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
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final double width = constraints.maxWidth;
                              // Tự động tính toán số cột dựa trên chiều rộng màn hình, mỗi card rộng tầm 150-180px
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
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
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
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _importBook,
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          AppLocalizations.of(context)?.importBook ?? 'Import Book',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
    
    Color statusColor = Colors.grey;
    if (bookStatus == 'reading') statusColor = Colors.amber[700]!;
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
                  book.coverPath != null
                      ? Image.file(
                          File(book.coverPath!),
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: isDark ? Colors.grey[850] : Colors.grey[300],
                          child: Icon(
                            Icons.book_rounded,
                            size: 40,
                            color: isDark ? Colors.white30 : Colors.black38,
                          ),
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
                      onSelected: (value) {
                        if (value == 'delete') {
                          _showDeleteConfirm(book);
                        }
                      },
                      itemBuilder: (context) => [
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[700]!),
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
                          color: Colors.amber[700],
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
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontSize: 12, fontWeight: FontWeight.w600)),
      selected: isSelected,
      selectedColor: Colors.amber[700],
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
}
