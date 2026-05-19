// ignore_for_file: deprecated_member_use, avoid_print
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/database/database_helper.dart';
import '../../core/shortcut_helper.dart';
import '../../models/book.dart';
import '../../models/progress.dart';
import '../../services/epub_parser.dart';
import '../../services/tts_service.dart' hide print;
import '../reader/reader_screen.dart';
import '../../services/sync_service.dart' hide print;
import '../../services/update_service.dart';
import 'sync_settings_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Book> _books = [];
  bool _isLoading = false;
  String _searchQuery = '';

  // Trạng thái đồng bộ đám mây WebDAV
  DateTime? _lastSyncTime;
  bool _isSyncing = false;
  bool _webDavEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
    _loadBooks().then((_) {
      _triggerAutoSync();
      // Tự động mở sách đọc gần nhất sau khi dựng xong frame đầu tiên để tránh lỗi thread điều hướng
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAutoOpenLastRead();
        _checkUpdateOnLaunch();
      });
    });
  }

  Future<void> _loadSyncStatus() async {
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();
    if (mounted) {
      setState(() {
        _lastSyncTime = settings.webDavLastSync;
        _webDavEnabled = settings.webDavEnabled &&
            settings.webDavUrl.trim().isNotEmpty &&
            settings.webDavUsername.trim().isNotEmpty &&
            settings.webDavPassword.trim().isNotEmpty;
      });
    }
  }

  String _formatLastSyncTime() {
    if (_lastSyncTime == null) return 'Never synced';
    final now = DateTime.now();
    final difference = now.difference(_lastSyncTime!);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      final hh = _lastSyncTime!.hour.toString().padLeft(2, '0');
      final mm = _lastSyncTime!.minute.toString().padLeft(2, '0');
      return 'Today at $hh:$mm';
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
          const SnackBar(
            content: Text('Please enable and configure WebDAV in Settings first.'),
            backgroundColor: Colors.amber,
          ),
        );
      }
      return;
    }
    
    setState(() {
      _isSyncing = true;
    });
    
    try {
      final result = await SyncService.getInstance().sync();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.success ? 'Sync completed successfully!' : 'Sync failed: ${result.message}'),
            backgroundColor: result.success ? Colors.green : Colors.redAccent,
          ),
        );
      }
      if (result.success && result.localChanged) {
        await _loadBooks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync error: $e'), backgroundColor: Colors.redAccent),
        );
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
    final books = await db.getAllBooks();
    setState(() {
      _books = books;
    });
  }

  Future<void> _importEpub() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
      );

      if (result == null || result.files.single.path == null) return;

      setState(() {
        _isLoading = true;
      });

      final filePath = result.files.single.path!;
      final docDir = await getApplicationDocumentsDirectory();

      // Chạy parser trong background isolate để tránh đơ giao diện
      final parsedData = await compute(
        _parseEpubIsolate,
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
          SnackBar(content: Text('Successfully imported "${parsedData.book.title}"!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import EPUB: $e')),
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
  static Future<ParsedBookData> _parseEpubIsolate(Map<String, String> args) async {
    final filePath = args['filePath']!;
    final docDirPath = args['docDirPath']!;
    return await EpubParser.parseEpubFile(filePath, docDirPath);
  }

  Future<void> _deleteBook(Book book) async {
    final db = await DatabaseHelper.getInstance();
    await db.deleteBook(book.uuid);
    await _loadBooks();

    // Tự động kích hoạt xóa sách trên WebDAV đám mây nếu cấu hình bật
    final settings = await db.getSettings();
    if (settings.webDavEnabled) {
      SyncService.getInstance().deleteBookFromCloud(book.uuid).then((result) {
        print('[Sync] Cloud deletion result for "${book.title}": ${result.message}');
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted "${book.title}"')),
      );
    }
  }

  Future<void> _openBook(Book book) async {
    final db = await DatabaseHelper.getInstance();
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
            const Text(
              'Novel Shelf',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 24,
                letterSpacing: -0.5,
              ),
            ),
            if (_webDavEnabled) ...[
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _isSyncing
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[700]!),
                            ),
                          )
                        : GestureDetector(
                            onTap: _startManualSync,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Icon(
                                Icons.sync_rounded,
                                size: 16,
                                color: Colors.amber[700],
                              ),
                            ),
                          ),
                    const SizedBox(width: 8),
                    Text(
                      _isSyncing ? 'Syncing...' : 'Sync: ${_formatLastSyncTime()}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        actions: [
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
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_books.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    decoration: InputDecoration(
                      hintText: 'Search book on shelf...',
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
                              'Your shelf is empty',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the "+" button to import an EPUB book',
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
                                  'No books match your search',
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
                                  childAspectRatio: 0.62,
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
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Parsing EPUB content...',
                      style: TextStyle(
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
        onPressed: _importEpub,
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Import EPUB',
          style: TextStyle(fontWeight: FontWeight.bold),
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
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text('Delete Book', style: TextStyle(color: Colors.red, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 75,
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
                  Text(
                    '${book.totalChapters} Chapters',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.amber[700],
                      fontWeight: FontWeight.bold,
                    ),
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
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${book.title}"? This will erase all chapter caches and reading progress.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteBook(book);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
