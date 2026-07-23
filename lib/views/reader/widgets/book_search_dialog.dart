import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:audire_reader/src/rust/api/models.dart';
import '../../../services/tts_service.dart';

class BookSearchDialog extends StatefulWidget {
  final List<Chapter> chapters;
  final TtsService ttsService;
  final bool isDark;
  final Color textColor;

  const BookSearchDialog({
    super.key,
    required this.chapters,
    required this.ttsService,
    required this.isDark,
    required this.textColor,
  });

  @override
  State<BookSearchDialog> createState() => _BookSearchDialogState();
}

class _BookSearchDialogState extends State<BookSearchDialog> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }
    setState(() {
      _isSearching = true;
    });
    final list = <Map<String, dynamic>>[];
    final queryLower = trimmed.toLowerCase();
    for (int cIdx = 0; cIdx < widget.chapters.length; cIdx++) {
      final ch = widget.chapters[cIdx];
      for (int pIdx = 0; pIdx < ch.paragraphs.length; pIdx++) {
        final paragraph = ch.paragraphs[pIdx];
        if (paragraph.toLowerCase().contains(queryLower)) {
          list.add({
            'chapterIndex': cIdx,
            'chapterTitle': ch.title,
            'paragraphIndex': pIdx,
            'text': paragraph,
          });
        }
      }
    }
    setState(() {
      _results = list;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        AppLocalizations.of(context)!.searchInsideBook,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              style: TextStyle(color: widget.textColor),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.typeKeyword,
                hintStyle: TextStyle(
                  color: widget.textColor.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: widget.textColor.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: widget.isDark ? Colors.white10 : Colors.black12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (val) => _performSearch(val),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                  ? Center(
                      child: Text(
                        _searchController.text.isEmpty
                            ? AppLocalizations.of(context)!.enterKeywordToSearch
                            : AppLocalizations.of(context)!.noResultsFound,
                        style: TextStyle(
                          color: widget.textColor.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final res = _results[index];
                        final text = res['text'] as String;
                        final query = _searchController.text;

                        final queryLower = query.toLowerCase();
                        final textLower = text.toLowerCase();
                        final startIdx = textLower.indexOf(queryLower);

                        Widget textWidget;
                        if (startIdx != -1) {
                          final endIdx = startIdx + query.length;
                          final before = text.substring(0, startIdx);
                          final keyword = text.substring(startIdx, endIdx);
                          final after = text.substring(endIdx);
                          textWidget = RichText(
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: TextStyle(
                                color: widget.textColor,
                                fontSize: 13,
                                height: 1.4,
                              ),
                              children: [
                                TextSpan(
                                  text: before.length > 50
                                      ? '...${before.substring(before.length - 40)}'
                                      : before,
                                ),
                                TextSpan(
                                  text: keyword,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: after.length > 50
                                      ? '${after.substring(0, 40)}...'
                                      : after,
                                ),
                              ],
                            ),
                          );
                        } else {
                          textWidget = Text(
                            text,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: widget.textColor,
                              fontSize: 13,
                            ),
                          );
                        }

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          title: Text(
                            res['chapterTitle'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: textWidget,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            widget.ttsService.jumpToChapter(
                              res['chapterIndex'],
                            );
                            widget.ttsService.jumpToParagraph(
                              res['paragraphIndex'],
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.close),
        ),
      ],
    );
  }
}
