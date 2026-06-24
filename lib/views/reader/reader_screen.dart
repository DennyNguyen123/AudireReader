import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../core/shortcut_helper.dart';
import '../../services/tts_service.dart' hide print;
import '../../services/sync_service.dart' hide print;
import '../../services/logger_service.dart';
import '../../core/database/database_helper.dart';
import '../../models/chapter.dart';
import '../../models/settings.dart';
import '../../models/book.dart';

import '../../models/bookmark.dart';
import '../../models/highlight.dart';
import 'widgets/paragraph_widget.dart';
import 'widgets/book_search_dialog.dart';
import 'widgets/reader_settings_sheet.dart';
import 'widgets/bottom_audio_panel.dart';
import 'widgets/chapter_list_sheet.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> with WidgetsBindingObserver {
  late final TtsService _ttsService;
  bool _isInitialized = false;
  double _fontSize = 18.0;
  double _speechRate = 0.5; // FlutterTts standard rate is 0.5 for normal speed
  final _speedController = TextEditingController();
  String _fontFamily = 'System';
  String _themeMode = 'System';

  double _lineHeight = 1.6;
  double _paragraphSpacing = 14.0;
  String _textAlignment = 'left';
  double _sideMargin = 20.0;
  String? _customBackgroundColor;
  String? _customTextColor;

  final ScrollController _scrollController = ScrollController();

  // Bookmarks, Highlights & Notes
  bool _isBookmarked = false;
  List<Bookmark> _bookmarks = [];
  List<Highlight> _highlights = [];
  Map<String, Highlight> _highlightsMap = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initTtsService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_isInitialized) {
      _ttsService.removeListener(_onTtsServiceChanged);
    }
    _scrollController.dispose();
    _speedController.dispose();
    _syncActiveBookProgressOnExit();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _syncActiveBookProgressOnExit();
    }
  }

  void _syncActiveBookProgressOnExit() {
    if (_isInitialized) {
      final book = _ttsService.activeBook;
      if (book != null) {
        SyncService.getInstance().syncBookProgress(book.uuid);
      }
    }
  }

  Future<void> _syncActiveBookProgressOnEntry() async {
    final book = _ttsService.activeBook;
    if (book != null) {
      LoggerService().log('[ReaderScreen] Auto-syncing progress on book open for "${book.title}"...', tag: 'SYNC', level: LogLevel.info);
      final syncResult = await SyncService.getInstance().syncBookProgress(book.uuid);
      if (syncResult.status == ProgressSyncStatus.updatedLocal && mounted) {
        LoggerService().log('[ReaderScreen] Local progress was updated from cloud. Reloading active book in TTS...', tag: 'SYNC', level: LogLevel.info);
        final db = await DatabaseHelper.getInstance();
        final progress = await db.getProgress(book.uuid);
        if (progress != null) {
          await _ttsService.loadBook(
            book, 
            _ttsService.chapters, 
            startChapter: progress.currentChapterIndex, 
            startParagraph: progress.currentParagraphIndex
          );
        }
      } else if (syncResult.status == ProgressSyncStatus.conflict && mounted && syncResult.cloudProgress != null) {
        // SHOW CONFLICT DIALOG
        _showConflictDialog(book, syncResult.cloudProgress!);
      }
    }
  }

  void _onTtsServiceChanged() {
    _updateBookmarkState();
    _loadBookmarksAndHighlights();
  }

  void _showConflictDialog(Book book, Map<String, dynamic> cloudProgress) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)?.syncConflictTitle ?? 'Sync Conflict Detected'),
          content: Text(
            AppLocalizations.of(context)?.syncConflictDesc(
              cloudProgress['deviceName'] ?? 'Unknown Device',
              (cloudProgress['currentChapterIndex'] ?? 0).toString(),
              _ttsService.currentChapterIndex.toString(),
            ) ??
            'Your current reading progress conflicts with data from "${cloudProgress['deviceName']}".\n\n'
            'Cloud: Chapter ${cloudProgress['currentChapterIndex']}\n'
            'Local: Chapter ${_ttsService.currentChapterIndex}\n\n'
            'Which progress would you like to keep?',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                // Keep Local: Upload local to cloud to overwrite
                final db = await DatabaseHelper.getInstance();
                final localProg = await db.getProgress(book.uuid);
                final settings = await db.getSettings();
                if (localProg != null) {
                  // Bypass conflict and force upload
                  SyncService.getInstance().forceUploadLocalProgress(book.uuid, localProg, settings.deviceId ?? '', settings.deviceName ?? '');
                }
              },
              child: Text(AppLocalizations.of(context)?.keepLocal ?? 'Keep Local', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                // Keep Cloud: Overwrite local
                final db = await DatabaseHelper.getInstance();
                await SyncService.getInstance().forceUpdateLocalFromCloud(book.uuid, cloudProgress, await db.getProgress(book.uuid), db);
                final updatedProg = await db.getProgress(book.uuid);
                if (updatedProg != null && mounted) {
                  await _ttsService.loadBook(
                    book, 
                    _ttsService.chapters, 
                    startChapter: updatedProg.currentChapterIndex, 
                    startParagraph: updatedProg.currentParagraphIndex
                  );
                }
              },
              child: Text(AppLocalizations.of(context)?.useCloud ?? 'Use Cloud', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateBookmarkState() async {
    final book = _ttsService.activeBook;
    if (book == null) return;
    try {
      final db = await DatabaseHelper.getInstance();
      final bookmark = await db.getBookmarkAt(
        book.uuid,
        _ttsService.currentChapterIndex,
        _ttsService.currentParagraphIndex,
      );
      if (mounted) {
        setState(() {
          _isBookmarked = bookmark != null;
        });
      }
    } catch (e) {
      LoggerService().log('Failed to update bookmark state', tag: 'APP', level: LogLevel.error, error: e.toString());
    }
  }

  Future<void> _loadBookmarksAndHighlights() async {
    final book = _ttsService.activeBook;
    if (book == null) return;
    try {
      final db = await DatabaseHelper.getInstance();
      final bookmarks = await db.getBookmarksForBook(book.uuid);
      final highlights = await db.getHighlightsForBook(book.uuid);
      
      final Map<String, Highlight> hMap = {};
      for (final h in highlights) {
        hMap['${h.chapterIndex}_${h.paragraphIndex}'] = h;
      }
      
      if (mounted) {
        setState(() {
          _bookmarks = bookmarks;
          _highlights = highlights;
          _highlightsMap = hMap;
        });
      }
    } catch (e) {
      LoggerService().log('Failed to load bookmarks and highlights', tag: 'APP', level: LogLevel.error, error: e.toString());
    }
  }

  Future<void> _toggleBookmark() async {
    final book = _ttsService.activeBook;
    if (book == null) return;
    final l10n = AppLocalizations.of(context)!;
    try {
      final db = await DatabaseHelper.getInstance();
      if (_isBookmarked) {
        await db.deleteBookmarkAt(book.uuid, _ttsService.currentChapterIndex, _ttsService.currentParagraphIndex);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.bookmarkRemoved), duration: const Duration(seconds: 1)),
        );
      } else {
        final chapter = _ttsService.chapters[_ttsService.currentChapterIndex];
        final snippet = chapter.paragraphs[_ttsService.currentParagraphIndex];
        final bookmark = Bookmark()
          ..bookUuid = book.uuid
          ..chapterIndex = _ttsService.currentChapterIndex
          ..paragraphIndex = _ttsService.currentParagraphIndex
          ..contentSnippet = snippet.substring(0, snippet.length > 60 ? 60 : snippet.length)
          ..dateAdded = DateTime.now();
        await db.saveBookmark(bookmark);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.bookmarkAdded), duration: const Duration(seconds: 1)),
        );
      }
      await _updateBookmarkState();
      await _loadBookmarksAndHighlights();
    } catch (e) {
      LoggerService().log('Failed to toggle bookmark', tag: 'APP', level: LogLevel.error, error: e.toString());
    }
  }

  void _showSearchInsideBook() {
    final isDark = _getIsDark(context);
    final textColor = _getTextColor(isDark);
    showDialog(
      context: context,
      builder: (context) => BookSearchDialog(
        chapters: _ttsService.chapters,
        ttsService: _ttsService,
        isDark: isDark,
        textColor: textColor,
      ),
    );
  }

  void _showParagraphMenu(int chapterIndex, int paragraphIndex, String paragraphText) async {
    final isDark = _getIsDark(context);
    final textColor = _getTextColor(isDark);
    final key = '${chapterIndex}_$paragraphIndex';
    final existingHighlight = _highlightsMap[key];

    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final sheetBg = theme.scaffoldBackgroundColor;
        final accentColor = theme.colorScheme.primary;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    sheetBg.withValues(alpha: isDark ? 0.75 : 0.85),
                    sheetBg.withValues(alpha: isDark ? 0.85 : 0.95),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.06),
                    width: 1.5,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.paragraphActions,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildColorButton(context, Colors.yellow, '#FFFFEB3B', existingHighlight, chapterIndex, paragraphIndex, paragraphText),
                      _buildColorButton(context, Colors.green, '#FF4CAF50', existingHighlight, chapterIndex, paragraphIndex, paragraphText),
                      _buildColorButton(context, Colors.blue, '#FF2196F3', existingHighlight, chapterIndex, paragraphIndex, paragraphText),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  
                  ListTile(
                    leading: Icon(Icons.sticky_note_2_rounded, color: accentColor),
                    title: Text(existingHighlight?.note != null ? l10n.editNote : l10n.addNote, style: TextStyle(color: textColor)),
                    onTap: () {
                      Navigator.pop(context);
                      _showAddNoteDialog(chapterIndex, paragraphIndex, paragraphText, existingHighlight);
                    },
                  ),
                  
                  ListTile(
                    leading: Icon(Icons.copy_rounded, color: accentColor),
                    title: Text(l10n.copyText, style: TextStyle(color: textColor)),
                    onTap: () {
                      Navigator.pop(context);
                      Clipboard.setData(ClipboardData(text: paragraphText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.copiedToClipboard), duration: const Duration(seconds: 1)),
                      );
                    },
                  ),

                  if (existingHighlight != null)
                    ListTile(
                      leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      title: Text(l10n.removeHighlight, style: const TextStyle(color: Colors.redAccent)),
                      onTap: () async {
                        Navigator.pop(context);
                        final db = await DatabaseHelper.getInstance();
                        await db.deleteHighlight(existingHighlight.id);
                        await _loadBookmarksAndHighlights();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.highlightRemoved), duration: const Duration(seconds: 1)),
                          );
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorButton(
    BuildContext context, 
    Color color, 
    String hex, 
    Highlight? existing, 
    int chapterIndex, 
    int paragraphIndex, 
    String text
  ) {
    final isSelected = existing?.colorHex == hex;
    final accentColor = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        final db = await DatabaseHelper.getInstance();
        final book = _ttsService.activeBook;
        if (book == null) return;
        
        final highlight = existing ?? Highlight()
          ..bookUuid = book.uuid
          ..chapterIndex = chapterIndex
          ..paragraphIndex = paragraphIndex
          ..text = text
          ..dateAdded = DateTime.now();
        
        highlight.colorHex = hex;
        await db.saveHighlight(highlight);
        await _loadBookmarksAndHighlights();
        if (context.mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.highlightSaved), duration: const Duration(seconds: 1)),
          );
        }
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.3),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? accentColor : color,
            width: isSelected ? 3 : 1.5,
          ),
        ),
        child: isSelected ? Icon(Icons.check, color: accentColor, size: 20) : null,
      ),
    );
  }

  void _showAddNoteDialog(int chapterIndex, int paragraphIndex, String text, Highlight? existing) {
    final isDark = _getIsDark(context);
    final controller = TextEditingController(text: existing?.note);
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(existing != null ? l10n.editNote : l10n.addNote, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: TextStyle(color: _getTextColor(isDark)),
          decoration: InputDecoration(
            hintText: l10n.typeNoteHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final noteText = controller.text.trim();
              final db = await DatabaseHelper.getInstance();
              final book = _ttsService.activeBook;
              if (book == null) return;

              final highlight = existing ?? Highlight()
                ..bookUuid = book.uuid
                ..chapterIndex = chapterIndex
                ..paragraphIndex = paragraphIndex
                ..text = text
                ..colorHex = '#FFFFEB3B'
                ..dateAdded = DateTime.now();

              highlight.note = noteText;
              await db.saveHighlight(highlight);
              await _loadBookmarksAndHighlights();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.noteSaved), duration: const Duration(seconds: 1)),
                );
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _initTtsService() async {
    _ttsService = await TtsService.getInstance();
    final settings = await _ttsService.getSettings();

    setState(() {
      _fontSize = settings.fontSize;
      _speechRate = settings.speechRate;
      _speedController.text = (_speechRate * 2).toStringAsFixed(3);
      
      dynamic rawFont = settings.fontFamily;
      _fontFamily = (rawFont == null || rawFont.toString().trim().isEmpty) ? 'System' : rawFont.toString();
      
      dynamic rawTheme = settings.themeMode;
      _themeMode = (rawTheme == null || rawTheme.toString().trim().isEmpty) ? 'System' : rawTheme.toString();
      
      _lineHeight = settings.lineHeight.isNaN ? 1.6 : settings.lineHeight;
      _paragraphSpacing = settings.paragraphSpacing.isNaN ? 14.0 : settings.paragraphSpacing;
      _textAlignment = settings.textAlignment;
      _sideMargin = settings.sideMargin.isNaN ? 20.0 : settings.sideMargin;
      _customBackgroundColor = settings.customBackgroundColor;
      _customTextColor = settings.customTextColor;
    });

    _ttsService.addListener(_onTtsServiceChanged);
    await _loadBookmarksAndHighlights();
    await _updateBookmarkState();

    setState(() {
      _isInitialized = true;
    });

    // Tự động đồng bộ tiến trình đọc từ mây về khi mở màn hình đọc
    _syncActiveBookProgressOnEntry();
  }




  // --- Hotkeys & Boss Key Handlers ---
  void _handleNextParagraph() {
    _ttsService.nextParagraph();
  }

  void _handlePrevParagraph() {
    _ttsService.previousParagraph();
  }

  void _handleNextChapter() {
    if (_ttsService.currentChapterIndex < _ttsService.chapters.length - 1) {
      _ttsService.nextChapter();
    }
  }

  void _handlePrevChapter() {
    if (_ttsService.currentChapterIndex > 0) {
      _ttsService.previousChapter();
    }
  }

  void _handlePlayPauseTts() {
    _ttsService.togglePlayPause();
  }

  void _handleOpenChapter() {
    _showChapterList(context);
  }

  void _handleOpenSetting() {
    _showSettings();
  }


  Map<ShortcutActivator, VoidCallback> _buildShortcuts(AppSettings settings) {
    return {
      ShortcutHelper.parse(settings.hotkeyNextParagraph): _handleNextParagraph,
      ShortcutHelper.parse(settings.hotkeyPrevParagraph): _handlePrevParagraph,
      ShortcutHelper.parse(settings.hotkeyNextChapter): _handleNextChapter,
      ShortcutHelper.parse(settings.hotkeyPrevChapter): _handlePrevChapter,
      ShortcutHelper.parse(settings.hotkeyPlayPauseTts): _handlePlayPauseTts,
      ShortcutHelper.parse(settings.hotkeyOpenChapter): _handleOpenChapter,
      ShortcutHelper.parse(settings.hotkeyOpenSetting): _handleOpenSetting,
    };
  }

  bool _getIsDark(BuildContext context) {
    if (_themeMode == 'Dark') return true;
    if (_themeMode == 'Light' || _themeMode == 'Sepia') return false;
    return Theme.of(context).brightness == Brightness.dark;
  }

  Color _parseColor(String? hexColor, Color fallback) {
    if (hexColor == null || hexColor.isEmpty) return fallback;
    try {
      String cleanHex = hexColor.replaceAll('#', '');
      if (cleanHex.length == 6) cleanHex = 'FF$cleanHex';
      return Color(int.parse(cleanHex, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  Color _getBackgroundColor(bool isDark) {
    if (_themeMode == 'Custom') {
      return _parseColor(_customBackgroundColor, isDark ? const Color(0xFF121212) : const Color(0xFFFAF9F6));
    }
    if (_themeMode == 'Sepia') return const Color(0xFFF4ECD8);
    return isDark ? const Color(0xFF121212) : const Color(0xFFFAF9F6);
  }

  Color _getTextColor(bool isDark) {
    if (_themeMode == 'Custom') {
      return _parseColor(_customTextColor, isDark ? Colors.white70 : Colors.black87);
    }
    if (_themeMode == 'Sepia') return const Color(0xFF5B4636);
    return isDark ? Colors.white70 : Colors.black87;
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ReaderSettingsSheet(
        ttsService: _ttsService,
        themeMode: _themeMode,
        fontSize: _fontSize,
        fontFamily: _fontFamily,
        lineHeight: _lineHeight,
        paragraphSpacing: _paragraphSpacing,
        textAlignment: _textAlignment,
        sideMargin: _sideMargin,
        customBackgroundColor: _customBackgroundColor,
        customTextColor: _customTextColor,
        onThemeModeChanged: (theme) {
          setState(() {
            _themeMode = theme;
          });
        },
        onFontSizeChanged: (val) {
          setState(() {
            _fontSize = val;
          });
        },
        onFontFamilyChanged: (val) {
          setState(() {
            _fontFamily = val;
          });
        },
        onLineHeightChanged: (val) {
          setState(() {
            _lineHeight = val;
          });
        },
        onParagraphSpacingChanged: (val) {
          setState(() {
            _paragraphSpacing = val;
          });
        },
        onTextAlignmentChanged: (val) {
          setState(() {
            _textAlignment = val;
          });
        },
        onSideMarginChanged: (val) {
          setState(() {
            _sideMargin = val;
          });
        },
        onCustomColorChanged: (bg, text) {
          setState(() {
            _customBackgroundColor = bg;
            _customTextColor = text;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final isDark = _getIsDark(context);
    final backgroundColor = _getBackgroundColor(isDark);
    final textColor = _getTextColor(isDark);

    return ListenableBuilder(
      listenable: _ttsService,
      builder: (context, _) {
        final book = _ttsService.activeBook;
        final chapters = _ttsService.chapters;
        final activeChapterIndex = _ttsService.currentChapterIndex;

        if (book == null || chapters.isEmpty) {
          return Scaffold(
            body: Center(
              child: Text(AppLocalizations.of(context)!.noBookActive),
            ),
          );
        }

        final chapter = chapters[activeChapterIndex];

        return FutureBuilder<AppSettings>(
          future: _ttsService.getSettings(),
          builder: (context, snapshot) {
            final settings = snapshot.data;
            final Widget scaffoldContent = Scaffold(
              backgroundColor: backgroundColor,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                foregroundColor: textColor,
                title: Text(
                  book.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                actions: [
                  if (_ttsService.isSleepTimerActive && _ttsService.sleepTimerDuration != null)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bedtime, size: 14, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              '${(_ttsService.sleepTimerDuration! ~/ 60).toString().padLeft(2, '0')}:${(_ttsService.sleepTimerDuration! % 60).toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.search_rounded),
                    onPressed: _showSearchInsideBook,
                  ),
                  IconButton(
                    icon: Icon(_isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
                    color: _isBookmarked ? Theme.of(context).colorScheme.primary : null,
                    onPressed: _toggleBookmark,
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_list_bulleted_rounded),
                    onPressed: () => _showChapterList(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.palette_rounded),
                    tooltip: 'Appearance Settings',
                    onPressed: _showSettings,
                  ),
                ],
              ),
              body: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: _sideMargin, vertical: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        chapter.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.primary,
                          fontFamily: _fontFamily == 'System' ? null : _fontFamily,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      cacheExtent: 100000,
                      padding: EdgeInsets.fromLTRB(_sideMargin, 10, _sideMargin, 100),
                      itemCount: chapter.paragraphs.length,
                      itemBuilder: (context, index) {
                        final paragraphText = chapter.paragraphs[index];
                        final isActive = index == _ttsService.currentParagraphIndex;

                        final key = '${activeChapterIndex}_$index';
                        final highlight = _highlightsMap[key];

                        return ParagraphWidget(
                          key: ValueKey(key),
                          text: paragraphText,
                          isActive: isActive,
                          isPlaying: _ttsService.isPlaying,
                          fontSize: _fontSize,
                          lineHeight: _lineHeight,
                          paragraphSpacing: _paragraphSpacing,
                          textAlign: _textAlignment == 'justify' ? TextAlign.justify : TextAlign.left,
                          wordStart: isActive ? _ttsService.wordStart : 0,
                          wordEnd: isActive ? _ttsService.wordEnd : 0,
                          isDark: isDark,
                          fontFamily: _fontFamily,
                          textColor: textColor,
                          highlightColorHex: highlight?.colorHex,
                          hasNote: highlight?.note != null && highlight!.note!.isNotEmpty,
                          onTap: () {
                            _ttsService.jumpToParagraph(index);
                          },
                          onLongPress: () {
                            _showParagraphMenu(activeChapterIndex, index, paragraphText);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: _buildBottomAudioPanel(chapter, isDark, textColor),
            );

            if (settings == null) {
              return scaffoldContent;
            }

            return CallbackShortcuts(
              bindings: _buildShortcuts(settings),
              child: Focus(
                autofocus: true,
                child: scaffoldContent,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomAudioPanel(Chapter chapter, bool isDark, Color textColor) {
    return BottomAudioPanel(
      ttsService: _ttsService,
      chapter: chapter,
      isDark: isDark,
      textColor: textColor,
      themeMode: _themeMode,
    );
  }

  void _showChapterList(BuildContext context) {
    final isDark = _getIsDark(context);
    final sheetBg = _getBackgroundColor(isDark);
    final textColor = _getTextColor(isDark);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ChapterListSheet(
          ttsService: _ttsService,
          bookmarks: _bookmarks,
          highlights: _highlights,
          isDark: isDark,
          textColor: textColor,
          sheetBg: sheetBg,
          onRefreshData: _loadBookmarksAndHighlights,
          onUpdateBookmarkState: _updateBookmarkState,
          scrollController: scrollController,
        ),
      ),
    );
  }
}
