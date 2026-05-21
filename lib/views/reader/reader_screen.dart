// ignore_for_file: deprecated_member_use
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
  List<dynamic> _voices = [];
  Map<String, String>? _selectedVoice;
  String _fontFamily = 'System';
  String _themeMode = 'System';
  String _ttsProvider = 'system';


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
        LoggerService().log('[ReaderScreen] Auto-syncing progress on exit/pause for "${book.title}"...', tag: 'SYNC', level: LogLevel.info);
        SyncService.getInstance().syncBookProgress(book.uuid);
      }
    }
  }

  Future<void> _syncActiveBookProgressOnEntry() async {
    final book = _ttsService.activeBook;
    if (book != null) {
      LoggerService().log('[ReaderScreen] Auto-syncing progress on book open for "${book.title}"...', tag: 'SYNC', level: LogLevel.info);
      final localDatabaseChanged = await SyncService.getInstance().syncBookProgress(book.uuid);
      if (localDatabaseChanged && mounted) {
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
      }
    }
  }

  void _onTtsServiceChanged() {
    _updateBookmarkState();
    _loadBookmarksAndHighlights();
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
              leading: Icon(Icons.sticky_note_2_rounded, color: Colors.amber[700]),
              title: Text(existingHighlight?.note != null ? l10n.editNote : l10n.addNote, style: TextStyle(color: textColor)),
              onTap: () {
                Navigator.pop(context);
                _showAddNoteDialog(chapterIndex, paragraphIndex, paragraphText, existingHighlight);
              },
            ),
            
            ListTile(
              leading: Icon(Icons.copy_rounded, color: Colors.amber[700]),
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
          color: color.withOpacity(0.3),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.amber[700]! : color,
            width: isSelected ? 3 : 1.5,
          ),
        ),
        child: isSelected ? Icon(Icons.check, color: Colors.amber[700], size: 20) : null,
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
      final provider = settings.ttsProvider;
      _ttsProvider = (provider == 'microsoft_edge') ? 'microsoft_edge' : 'system';
      
      dynamic rawFont = settings.fontFamily;
      _fontFamily = (rawFont == null || rawFont.toString().trim().isEmpty) ? 'System' : rawFont.toString();
      
      dynamic rawTheme = settings.themeMode;
      _themeMode = (rawTheme == null || rawTheme.toString().trim().isEmpty) ? 'System' : rawTheme.toString();
    });

    _ttsService.addListener(_onTtsServiceChanged);
    await _loadBookmarksAndHighlights();
    await _updateBookmarkState();

    setState(() {
      _isInitialized = true;
    });

    _loadVoices(settings);
    
    // Tự động đồng bộ tiến trình đọc từ mây về khi mở màn hình đọc
    _syncActiveBookProgressOnEntry();
  }
  Future<void> _loadVoices(AppSettings settings) async {
    try {
      final list = await _ttsService.getVoicesForProvider(settings.ttsProvider);

      Map<String, String>? initialVoice;
      if (settings.selectedVoiceName != null && settings.selectedVoiceLocale != null) {
        dynamic matched;
        for (final v in list) {
          if (v['name']?.toString() == settings.selectedVoiceName &&
              v['locale']?.toString() == settings.selectedVoiceLocale) {
            matched = v;
            break;
          }
        }
        if (matched != null) {
          initialVoice = Map<String, String>.from(
            (matched as Map).map((k, val) => MapEntry(k.toString(), val.toString())),
          );
        }
      } else if (settings.ttsProvider == 'microsoft_edge' && list.isNotEmpty) {
        // Tự động gán mặc định giọng HoaiMy cho Edge TTS
        dynamic matched;
        for (final v in list) {
          if (v['name']?.toString() == 'vi-VN-HoaiMyNeural') {
            matched = v;
            break;
          }
        }
        matched ??= list.first;
        initialVoice = Map<String, String>.from(
          (matched as Map).map((k, val) => MapEntry(k.toString(), val.toString())),
        );
        _ttsService.updateSettings(voice: initialVoice);
      }

      setState(() {
        _voices = list;
        _selectedVoice = initialVoice;
      });
    } catch (e) {
      LoggerService().log('Failed to load voices', tag: 'APP', level: LogLevel.error, error: e.toString());
    }
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

  Color _getBackgroundColor(bool isDark) {
    if (_themeMode == 'Sepia') return const Color(0xFFF4ECD8);
    return isDark ? const Color(0xFF121212) : const Color(0xFFFAF9F6);
  }

  Color _getTextColor(bool isDark) {
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
        speechRate: _speechRate,
        ttsProvider: _ttsProvider,
        initialVoices: _voices,
        initialSelectedVoice: _selectedVoice,
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
        onSpeechRateChanged: (val) {
          setState(() {
            _speechRate = val;
            _speedController.text = (val * 2).toStringAsFixed(3);
          });
        },
        onTtsProviderChanged: (provider, voices, selectedVoice) {
          setState(() {
            _ttsProvider = provider;
            _voices = voices;
            _selectedVoice = selectedVoice;
          });
        },
        onVoiceChanged: (voice) {
          setState(() {
            _selectedVoice = voice;
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
                  IconButton(
                    icon: const Icon(Icons.search_rounded),
                    onPressed: _showSearchInsideBook,
                  ),
                  IconButton(
                    icon: Icon(_isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
                    color: _isBookmarked ? Colors.amber[700] : null,
                    onPressed: _toggleBookmark,
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_list_bulleted_rounded),
                    onPressed: () => _showChapterList(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_rounded),
                    onPressed: _showSettings,
                  ),
                ],
              ),
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        chapter.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.amber[400] : Colors.amber[800],
                          fontFamily: _fontFamily == 'System' ? null : _fontFamily.toLowerCase(),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: List.generate(chapter.paragraphs.length, (index) {
                          final paragraphText = chapter.paragraphs[index];
                          final isActive = index == _ttsService.currentParagraphIndex;

                          final key = '${activeChapterIndex}_$index';
                          final highlight = _highlightsMap[key];

                          return ParagraphWidget(
                            text: paragraphText,
                            isActive: isActive,
                            fontSize: _fontSize,
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
                        }),
                      ),
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
