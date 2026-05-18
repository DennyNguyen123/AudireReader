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
import '../../services/tts_service.dart';
import '../reader/reader_screen.dart';
import '../../services/sync_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadBooks().then((_) {
      _triggerAutoSync();
      // Tự động mở sách đọc gần nhất sau khi dựng xong frame đầu tiên để tránh lỗi thread điều hướng
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAutoOpenLastRead();
      });
    });
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
      SyncService.getInstance().sync().then((result) {
        if (result.success && result.localChanged) {
          _loadBooks();
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
             (book.author?.toLowerCase().contains(searchLower) ?? false);
    }).toList();

    final scaffoldContent = Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F7),
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
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Search book on shelf...',
                      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                      prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white38 : Colors.black38),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
