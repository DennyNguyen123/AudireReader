import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../models/bookmark.dart';
import '../../../models/highlight.dart';
import '../../../services/tts_service.dart';
import '../../../services/offline_tts_service.dart';
import '../../../core/database/database_helper.dart';
import '../../../l10n/app_localizations.dart';
import 'tts_download_manager_sheet.dart';

class ChapterListSheet extends StatefulWidget {
  final TtsService ttsService;
  final List<Bookmark> bookmarks;
  final List<Highlight> highlights;
  final bool isDark;
  final Color textColor;
  final Color sheetBg;
  final Future<void> Function()
  onRefreshData; // Gọi khi xóa bookmark/highlight để load lại dữ liệu ở màn hình chính
  final Future<void> Function()
  onUpdateBookmarkState; // Cập nhật lại icon bookmark ở AppBar
  final ScrollController? scrollController;

  const ChapterListSheet({
    super.key,
    required this.ttsService,
    required this.bookmarks,
    required this.highlights,
    required this.isDark,
    required this.textColor,
    required this.sheetBg,
    required this.onRefreshData,
    required this.onUpdateBookmarkState,
    this.scrollController,
  });

  @override
  State<ChapterListSheet> createState() => _ChapterListSheetState();
}

class _ChapterListSheetState extends State<ChapterListSheet> {
  String _chapterSearchQuery = '';
  late List<Bookmark> _localBookmarks;
  late List<Highlight> _localHighlights;
  final OfflineTtsService _offlineService = OfflineTtsService.getInstance();
  Set<int> _downloadedChapterIndices = {};

  @override
  void initState() {
    super.initState();
    _localBookmarks = List.from(widget.bookmarks);
    _localHighlights = List.from(widget.highlights);
    _loadDownloadedStatus();
    _offlineService.addListener(_loadDownloadedStatus);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController != null &&
          widget.scrollController!.hasClients) {
        final currentIdx = widget.ttsService.currentChapterIndex;
        if (currentIdx > 0) {
          final offset = (currentIdx * 52.0) - 52.0;
          final maxScroll = widget.scrollController!.position.maxScrollExtent;
          widget.scrollController!.jumpTo(
            offset > maxScroll ? maxScroll : (offset > 0 ? offset : 0),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _offlineService.removeListener(_loadDownloadedStatus);
    super.dispose();
  }

  Future<void> _loadDownloadedStatus() async {
    final book = widget.ttsService.activeBook;
    if (book == null) return;
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();

    final downloaded = <int>{};
    for (final ch in widget.ttsService.chapters) {
      final isDownloaded = await _offlineService.isChapterDownloaded(
        book.uuid,
        ch.chapterIndex,
        settings,
      );
      if (isDownloaded) {
        downloaded.add(ch.chapterIndex);
      }
    }
    if (mounted) {
      setState(() {
        _downloadedChapterIndices = downloaded;
      });
    }
  }

  void _openDownloadManager() {
    final book = widget.ttsService.activeBook;
    if (book == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TtsDownloadManagerSheet(
        book: book,
        chapters: widget.ttsService.chapters,
        isDark: widget.isDark,
        textColor: widget.textColor,
        sheetBg: widget.sheetBg,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant ChapterListSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bookmarks != oldWidget.bookmarks) {
      _localBookmarks = List.from(widget.bookmarks);
    }
    if (widget.highlights != oldWidget.highlights) {
      _localHighlights = List.from(widget.highlights);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final chapters = widget.ttsService.chapters;
    final currentChapterIdx = widget.ttsService.currentChapterIndex;

    final filteredChapters = chapters.asMap().entries.where((entry) {
      final title = entry.value.title.toLowerCase();
      final query = _chapterSearchQuery.toLowerCase();
      return title.contains(query);
    }).toList();

    return DefaultTabController(
      length: 3,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  widget.sheetBg.withValues(alpha: widget.isDark ? 0.75 : 0.85),
                  widget.sheetBg.withValues(alpha: widget.isDark ? 0.85 : 0.95),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(
                  color: widget.isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.06),
                  width: 1.5,
                ),
              ),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: widget.isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                TabBar(
                  labelColor: primaryColor,
                  unselectedLabelColor: widget.textColor.withValues(alpha: 0.6),
                  indicatorColor: primaryColor,
                  indicatorWeight: 3,
                  tabs: [
                    Tab(
                      text:
                          AppLocalizations.of(context)?.chaptersTab ??
                          'Chapters',
                      icon: const Icon(
                        Icons.format_list_bulleted_rounded,
                        size: 20,
                      ),
                    ),
                    Tab(
                      text:
                          AppLocalizations.of(context)?.bookmarksTab ??
                          'Bookmarks',
                      icon: const Icon(Icons.bookmark_rounded, size: 20),
                    ),
                    Tab(
                      text:
                          AppLocalizations.of(context)?.highlightsTab ??
                          'Highlights',
                      icon: const Icon(Icons.border_color_rounded, size: 20),
                    ),
                  ],
                ),
                const Divider(height: 1),
                Expanded(
                  child: TabBarView(
                    children: [
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    style: TextStyle(color: widget.textColor),
                                    decoration: InputDecoration(
                                      hintText:
                                          AppLocalizations.of(
                                            context,
                                          )?.searchChaptersHint ??
                                          'Search chapters...',
                                      hintStyle: TextStyle(
                                        color: widget.textColor.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search_rounded,
                                        color: widget.textColor.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: widget.isDark
                                          ? Colors.white10
                                          : Colors.black12,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        _chapterSearchQuery = val;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(
                                    Icons.download_for_offline_rounded,
                                    color: primaryColor,
                                  ),
                                  tooltip: 'Quản lý TTS Offline',
                                  style: IconButton.styleFrom(
                                    backgroundColor: primaryColor.withValues(
                                      alpha: 0.15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _openDownloadManager,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: filteredChapters.isEmpty
                                ? Center(
                                    child: Text(
                                      AppLocalizations.of(
                                            context,
                                          )?.noChaptersMatch ??
                                          'No chapters match your search',
                                      style: TextStyle(
                                        color: widget.textColor.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    controller: widget.scrollController,
                                    itemCount: filteredChapters.length,
                                    itemBuilder: (context, index) {
                                      final entry = filteredChapters[index];
                                      final originalIndex = entry.key;
                                      final chapter = entry.value;
                                      final isCurrent =
                                          originalIndex == currentChapterIdx;
                                      final isDownloaded =
                                          _downloadedChapterIndices.contains(
                                            originalIndex,
                                          );

                                      return ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 2,
                                            ),
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                chapter.title,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: isCurrent
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                  color: isCurrent
                                                      ? primaryColor
                                                      : widget.textColor,
                                                ),
                                              ),
                                            ),
                                            if (isDownloaded)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 6,
                                                ),
                                                child: Icon(
                                                  Icons.check_circle_rounded,
                                                  color: Colors.green
                                                      .withValues(alpha: 0.8),
                                                  size: 16,
                                                ),
                                              ),
                                          ],
                                        ),
                                        trailing: isCurrent
                                            ? Icon(
                                                Icons.volume_up_rounded,
                                                color: primaryColor,
                                              )
                                            : null,
                                        tileColor: isCurrent
                                            ? primaryColor.withValues(
                                                alpha: 0.15,
                                              )
                                            : null,
                                        onTap: () {
                                          Navigator.pop(context);
                                          widget.ttsService.jumpToChapter(
                                            originalIndex,
                                          );
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                      _localBookmarks.isEmpty
                          ? Center(
                              child: Text(
                                AppLocalizations.of(
                                      context,
                                    )?.noBookmarksSaved ??
                                    'No bookmarks saved yet',
                                style: TextStyle(
                                  color: widget.textColor.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              controller: widget.scrollController,
                              itemCount: _localBookmarks.length,
                              separatorBuilder: (context, index) => Divider(
                                color: widget.isDark
                                    ? Colors.white10
                                    : Colors.black12,
                                height: 1,
                              ),
                              itemBuilder: (context, index) {
                                final b = _localBookmarks[index];
                                final chTitle = b.chapterIndex < chapters.length
                                    ? chapters[b.chapterIndex].title
                                    : 'Chapter ${b.chapterIndex + 1}';
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  title: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          chTitle,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        AppLocalizations.of(
                                              context,
                                            )?.paragraphIndexLabel(
                                              b.paragraphIndex + 1,
                                            ) ??
                                            'Paragraph ${b.paragraphIndex + 1}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: widget.textColor.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      b.contentSnippet,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: widget.textColor,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () async {
                                      final db =
                                          await DatabaseHelper.getInstance();
                                      await db.deleteBookmark(b.id);
                                      await widget.onRefreshData();
                                      await widget.onUpdateBookmarkState();
                                      if (mounted) {
                                        setState(() {
                                          _localBookmarks.removeAt(index);
                                        });
                                      }
                                    },
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    widget.ttsService.jumpToChapter(
                                      b.chapterIndex,
                                    );
                                    widget.ttsService.jumpToParagraph(
                                      b.paragraphIndex,
                                    );
                                  },
                                );
                              },
                            ),
                      _localHighlights.isEmpty
                          ? Center(
                              child: Text(
                                AppLocalizations.of(
                                      context,
                                    )?.noHighlightsSaved ??
                                    'No highlights saved yet',
                                style: TextStyle(
                                  color: widget.textColor.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              controller: widget.scrollController,
                              itemCount: _localHighlights.length,
                              separatorBuilder: (context, index) => Divider(
                                color: widget.isDark
                                    ? Colors.white10
                                    : Colors.black12,
                                height: 1,
                              ),
                              itemBuilder: (context, index) {
                                final h = _localHighlights[index];
                                final chTitle = h.chapterIndex < chapters.length
                                    ? chapters[h.chapterIndex].title
                                    : 'Chapter ${h.chapterIndex + 1}';

                                Color hColor = Colors.yellow;
                                if (h.colorHex.toLowerCase() == '#ff4caf50' ||
                                    h.colorHex.toLowerCase() == '0xff4caf50') {
                                  hColor = Colors.green;
                                } else if (h.colorHex.toLowerCase() ==
                                        '#ff2196f3' ||
                                    h.colorHex.toLowerCase() == '0xff2196f3') {
                                  hColor = Colors.blue;
                                }

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  title: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: hColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          chTitle,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        AppLocalizations.of(
                                              context,
                                            )?.paragraphIndexLabel(
                                              h.paragraphIndex + 1,
                                            ) ??
                                            'Paragraph ${h.paragraphIndex + 1}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: widget.textColor.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: hColor.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: hColor.withValues(
                                                alpha: 0.3,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            h.text,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: widget.textColor,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      if (h.note != null &&
                                          h.note!.isNotEmpty) ...[
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.sticky_note_2_rounded,
                                              size: 14,
                                              color: primaryColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                h.note!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: widget.textColor
                                                      .withValues(alpha: 0.8),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () async {
                                      final db =
                                          await DatabaseHelper.getInstance();
                                      await db.deleteHighlight(h.id);
                                      await widget.onRefreshData();
                                      if (mounted) {
                                        setState(() {
                                          _localHighlights.removeAt(index);
                                        });
                                      }
                                    },
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    widget.ttsService.jumpToChapter(
                                      h.chapterIndex,
                                    );
                                    widget.ttsService.jumpToParagraph(
                                      h.paragraphIndex,
                                    );
                                  },
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
