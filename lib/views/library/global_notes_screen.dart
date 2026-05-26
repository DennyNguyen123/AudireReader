import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:audire_reader/models/book.dart';
import 'package:audire_reader/models/bookmark.dart';
import 'package:audire_reader/models/highlight.dart';
import 'package:audire_reader/core/database/database_helper.dart';
import 'package:audire_reader/views/reader/reader_screen.dart';
import 'package:audire_reader/services/tts_service.dart';

class GlobalNotesScreen extends StatefulWidget {
  const GlobalNotesScreen({super.key});

  @override
  State<GlobalNotesScreen> createState() => _GlobalNotesScreenState();
}

class _GlobalNotesScreenState extends State<GlobalNotesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Bookmark> _bookmarks = [];
  List<Highlight> _highlights = [];
  Map<String, Book> _bookCache = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    final db = await DatabaseHelper.getInstance();
    
    final allBookmarks = await db.isar.bookmarks.where().sortByDateAddedDesc().findAll();
    final allHighlights = await db.isar.highlights.where().sortByDateAddedDesc().findAll();
    
    // Cache book information
    final Set<String> bookUuids = {};
    for (var b in allBookmarks) { bookUuids.add(b.bookUuid); }
    for (var h in allHighlights) { bookUuids.add(h.bookUuid); }
    
    final Map<String, Book> cache = {};
    for (final uuid in bookUuids) {
      final book = await db.getBookByUuid(uuid);
      if (book != null) {
        cache[uuid] = book;
      }
    }

    if (mounted) {
      setState(() {
        _bookmarks = allBookmarks;
        _highlights = allHighlights;
        _bookCache = cache;
        _isLoading = false;
      });
    }
  }

  Future<void> _openLocation(String bookUuid, int chapterIndex, int paragraphIndex) async {
    final book = _bookCache[bookUuid];
    if (book == null) return;

    final db = await DatabaseHelper.getInstance();
    final chapters = await db.getChaptersForBook(book.uuid);
    
    final ttsService = await TtsService.getInstance();
    await ttsService.loadBook(
      book,
      chapters,
      startChapter: chapterIndex,
      startParagraph: paragraphIndex,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ReaderScreen()),
      ).then((_) {
        _loadData();
      });
    }
  }

  Future<void> _deleteBookmark(Bookmark bookmark) async {
    final db = await DatabaseHelper.getInstance();
    await db.deleteBookmark(bookmark.id);
    _loadData();
  }

  Future<void> _deleteHighlight(Highlight highlight) async {
    final db = await DatabaseHelper.getInstance();
    await db.deleteHighlight(highlight.id);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notes & Bookmarks', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'Bookmarks'),
            Tab(text: 'Highlights'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBookmarksTab(isDark),
                _buildHighlightsTab(isDark),
              ],
            ),
    );
  }

  Widget _buildBookmarksTab(bool isDark) {
    if (_bookmarks.isEmpty) {
      return Center(
        child: Text('No bookmarks yet', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bookmarks.length,
      itemBuilder: (context, index) {
        final b = _bookmarks[index];
        final book = _bookCache[b.bookUuid];
        final bookTitle = book?.title ?? 'Unknown Book';

        return Card(
          color: isDark ? Colors.white10 : Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(bookTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text('Ch. ${b.chapterIndex + 1} | Par. ${b.paragraphIndex + 1}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 4),
                Text('"${b.contentSnippet}"', style: TextStyle(fontStyle: FontStyle.italic, color: isDark ? Colors.white70 : Colors.black87)),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              onPressed: () => _deleteBookmark(b),
            ),
            onTap: () => _openLocation(b.bookUuid, b.chapterIndex, b.paragraphIndex),
          ),
        );
      },
    );
  }

  Widget _buildHighlightsTab(bool isDark) {
    if (_highlights.isEmpty) {
      return Center(
        child: Text('No highlights yet', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _highlights.length,
      itemBuilder: (context, index) {
        final h = _highlights[index];
        final book = _bookCache[h.bookUuid];
        final bookTitle = book?.title ?? 'Unknown Book';

        // Parse colorHex to Color
        Color highlightColor = Colors.amber.withValues(alpha: 0.3);
        try {
          if (h.colorHex.startsWith('#')) {
            highlightColor = Color(int.parse(h.colorHex.substring(1), radix: 16) + 0xFF000000);
          }
        } catch (_) {}

        return Card(
          color: isDark ? Colors.white10 : Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(bookTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text('Ch. ${h.chapterIndex + 1} | Par. ${h.paragraphIndex + 1}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: highlightColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: highlightColor, width: 1),
                  ),
                  child: Text('"${h.text}"', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                ),
                if (h.note != null && h.note!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notes_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(h.note!, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                    ],
                  ),
                ],
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              onPressed: () => _deleteHighlight(h),
            ),
            onTap: () => _openLocation(h.bookUuid, h.chapterIndex, h.paragraphIndex),
          ),
        );
      },
    );
  }
}
