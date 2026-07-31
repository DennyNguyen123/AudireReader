import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../l10n/app_localizations.dart';
import 'package:audire_reader/src/rust/api/models.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import '../../../services/offline_tts_service.dart';

class TtsDownloadManagerSheet extends StatefulWidget {
  final Book book;
  final List<Chapter> chapters;
  final bool isDark;
  final Color textColor;
  final Color sheetBg;
  final int currentChapterIndex;

  const TtsDownloadManagerSheet({
    super.key,
    required this.book,
    required this.chapters,
    required this.isDark,
    required this.textColor,
    required this.sheetBg,
    this.currentChapterIndex = 0,
  });

  @override
  State<TtsDownloadManagerSheet> createState() =>
      _TtsDownloadManagerSheetState();
}

class _TtsDownloadManagerSheetState extends State<TtsDownloadManagerSheet> {
  final OfflineTtsService _offlineService = OfflineTtsService.getInstance();
  AppSettings? _settings;
  int _storageSize = 0;
  bool _isLoading = true;
  Set<int> _downloadedChapterIndices = {};
  Map<int, int> _chapterSizes = {};

  bool _isMultiSelectMode = false;
  final Set<int> _selectedChapterIndices = {};

  final AutoScrollController _autoScrollController = AutoScrollController();

  String _filterMode = 'all';

  List<Chapter> get _displayChapters {
    List<Chapter> list = widget.chapters;
    if (_filterMode == 'downloaded') {
      return list
          .where((ch) => _downloadedChapterIndices.contains(ch.chapterIndex))
          .toList();
    } else if (_filterMode == 'not_downloaded') {
      final notDownloaded = list
          .where((ch) => !_downloadedChapterIndices.contains(ch.chapterIndex))
          .toList();

      notDownloaded.sort((a, b) {
        final aActive = _offlineService.activeChapterIndices.contains(
          a.chapterIndex,
        );
        final bActive = _offlineService.activeChapterIndices.contains(
          b.chapterIndex,
        );
        if (aActive && !bActive) return -1;
        if (!aActive && bActive) return 1;
        return a.chapterIndex.compareTo(b.chapterIndex);
      });
      return notDownloaded;
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _offlineService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _updateDebounceTimer?.cancel();
    _offlineService.removeListener(_onServiceUpdate);
    _autoScrollController.dispose();
    super.dispose();
  }

  Timer? _updateDebounceTimer;

  void _onServiceUpdate() {
    if (!mounted) return;
    if (_updateDebounceTimer?.isActive ?? false) return;

    _updateDebounceTimer = Timer(const Duration(milliseconds: 1000), () async {
      if (!mounted) return;
      await _loadStorageAndStatus();
      if (_offlineService.isDownloading || _offlineService.isPaused) {
        setState(() {
          if (_offlineService.storageSize > 0) {
            _storageSize = _offlineService.storageSize;
          }
          if (_offlineService.downloadedChapterIndices.isNotEmpty) {
            _downloadedChapterIndices = _offlineService.downloadedChapterIndices
                .toSet();
          }
          if (_offlineService.chapterSizes.isNotEmpty) {
            _chapterSizes = _offlineService.chapterSizes;
          }
        });
      }
    });
  }

  Future<void> _loadInitialData() async {
    _currentChapterIndex = widget.currentChapterIndex;
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();
    final progress = await db.getProgress(widget.book.uuid);
    if (progress != null) {
      _currentChapterIndex = progress.currentChapterIndex;
    }
    setState(() {
      _settings = settings;
    });
    await _loadStorageAndStatus();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStorageAndStatus() async {
    final info = await _offlineService.getBookStorageInfo(widget.book.uuid);
    if (info != null && mounted) {
      setState(() {
        _storageSize = info.totalBytes.toInt();
        _downloadedChapterIndices = info.chapterIndices.toSet();
        _chapterSizes = {
          for (final item in info.chapterSizes)
            item.chapterIndex: item.bytes.toInt(),
        };
      });
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _updateConcurrency(double val) async {
    if (_settings == null) return;
    final int newConcurrency = val.round().clamp(1, 100);
    final updated = _settings!.copyWith(ttsDownloadConcurrency: newConcurrency);
    setState(() {
      _settings = updated;
    });
    final db = await DatabaseHelper.getInstance();
    await db.saveSettings(updated);
  }

  void _startDownloadSelected() {
    if (_settings == null || _selectedChapterIndices.isEmpty) return;
    final selectedChapters = widget.chapters
        .where((ch) => _selectedChapterIndices.contains(ch.chapterIndex))
        .toList();
    _offlineService.startDownload(
      book: widget.book,
      chapters: selectedChapters,
      settings: _settings!,
    );
    setState(() {
      _isMultiSelectMode = false;
      _selectedChapterIndices.clear();
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedChapterIndices.isEmpty) return;
    final count = _selectedChapterIndices.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteSelectedChapters),
        content: Text(
          AppLocalizations.of(context)!.confirmDeleteSelected(count),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(AppLocalizations.of(context)?.deleteBook ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _offlineService.deleteOfflineTtsForChapters(
        widget.book.uuid,
        _selectedChapterIndices.toList(),
      );
      setState(() {
        _isMultiSelectMode = false;
        _selectedChapterIndices.clear();
      });
      await _loadStorageAndStatus();
    }
  }

  Future<void> _confirmDeleteAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteAllOfflineTts),
        content: Text(AppLocalizations.of(context)!.confirmDeleteAllOfflineTts),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(AppLocalizations.of(context)?.deleteBook ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _offlineService.deleteOfflineTtsForBook(widget.book.uuid);
      await _loadStorageAndStatus();
    }
  }

  void _selectAll() {
    setState(() {
      _selectedChapterIndices.clear();
      _selectedChapterIndices.addAll(
        widget.chapters.map((e) => e.chapterIndex),
      );
    });
  }

  void _selectMissing() {
    setState(() {
      _selectedChapterIndices.clear();
      for (final ch in widget.chapters) {
        if (!_downloadedChapterIndices.contains(ch.chapterIndex)) {
          _selectedChapterIndices.add(ch.chapterIndex);
        }
      }
    });
  }

  int _currentChapterIndex = 0;

  void _selectFromCurrentToEnd() {
    setState(() {
      _selectedChapterIndices.clear();
      for (final ch in widget.chapters) {
        if (ch.chapterIndex >= _currentChapterIndex &&
            !_downloadedChapterIndices.contains(ch.chapterIndex)) {
          _selectedChapterIndices.add(ch.chapterIndex);
        }
      }
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedChapterIndices.clear();
    });
  }

  Future<void> _showSelectRangeDialog() async {
    final startController = TextEditingController();
    final endController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.selectRange),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(
                context,
              )!.enterChapterRange(widget.chapters.length),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: startController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.fromRange,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: endController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.toRange,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context)!.selectButton),
          ),
        ],
      ),
    );

    if (result == true) {
      final start = int.tryParse(startController.text) ?? 0;
      final end = int.tryParse(endController.text) ?? 0;

      if (start > 0 && end > 0 && start <= end) {
        setState(() {
          final startIdx = (start - 1).clamp(0, widget.chapters.length - 1);
          final endIdx = (end - 1).clamp(0, widget.chapters.length - 1);

          for (int i = startIdx; i <= endIdx; i++) {
            _selectedChapterIndices.add(widget.chapters[i].chapterIndex);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.93,
          decoration: BoxDecoration(
            color: widget.sheetBg.withValues(alpha: widget.isDark ? 0.9 : 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: widget.textColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.offlineTtsManager,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.textColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: widget.textColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: Column(
                    children: [
                      // Top compact controls header
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Compact Storage usage card
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: primaryColor.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Text(
                                          '${AppLocalizations.of(context)!.storageUsed}: ',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: widget.textColor.withValues(
                                              alpha: 0.7,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _formatSize(_storageSize),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '(${_downloadedChapterIndices.length}/${widget.chapters.length})',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: widget.textColor.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_storageSize > 0)
                                    OutlinedButton.icon(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 14,
                                        color: Colors.redAccent,
                                      ),
                                      label: Text(
                                        AppLocalizations.of(context)!.deleteAll,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        side: const BorderSide(
                                          color: Colors.redAccent,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                      onPressed: _confirmDeleteAll,
                                    ),
                                ],
                              ),
                            ),

                            // Concurrency slider
                            Theme(
                              data: theme.copyWith(
                                dividerColor: Colors.transparent,
                              ),
                              child: ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                title: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.advancedSettings,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: widget.textColor,
                                  ),
                                ),
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: widget.isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.black.withValues(
                                              alpha: 0.03,
                                            ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.parallelDownloadThreads,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: widget.textColor,
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: primaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '${(_settings?.ttsDownloadConcurrency ?? 3).clamp(1, 100)}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Slider(
                                          value:
                                              (_settings?.ttsDownloadConcurrency ??
                                                      3)
                                                  .clamp(1, 100)
                                                  .toDouble(),
                                          min: 1.0,
                                          max: 100.0,
                                          divisions: 99,
                                          activeColor: primaryColor,
                                          onChanged: _updateConcurrency,
                                        ),
                                        if (((_settings?.ttsDownloadConcurrency ??
                                                    3)
                                                .clamp(1, 100)) >
                                            20)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2,
                                            ),
                                            child: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.highThreadCountWarning,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.orangeAccent,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Compact Active Download Bar
                            if (_offlineService.isDownloading ||
                                _offlineService.isPaused)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.0,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.downloading(
                                            '${_offlineService.completedChaptersCount}/${_offlineService.totalChaptersToDownload}',
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: widget.textColor,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(4),
                                        icon: Icon(
                                          _offlineService.isPaused
                                              ? Icons.play_arrow_rounded
                                              : Icons.pause_rounded,
                                          size: 18,
                                          color: primaryColor,
                                        ),
                                        onPressed: () {
                                          if (_offlineService.isPaused &&
                                              _settings != null) {
                                            _offlineService.resumeDownload(
                                              widget.book,
                                              _settings!,
                                            );
                                          } else {
                                            _offlineService.pauseDownload();
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(4),
                                        icon: const Icon(
                                          Icons.cancel_rounded,
                                          size: 18,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () {
                                          _offlineService.cancelDownload();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            const SizedBox(height: 6),

                            // Chapter list header with Filter & Multi-select toggle
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.chapterList,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: widget.textColor,
                                  ),
                                ),
                                Row(
                                  children: [
                                    PopupMenuButton<String>(
                                      icon: Icon(
                                        Icons.filter_list_rounded,
                                        color: widget.textColor,
                                      ),
                                      tooltip: 'Filter',
                                      onSelected: (mode) {
                                        setState(() {
                                          _filterMode = mode;
                                        });
                                      },
                                      itemBuilder: (ctx) => [
                                        PopupMenuItem(
                                          value: 'all',
                                          child: Row(
                                            children: [
                                              if (_filterMode == 'all')
                                                Icon(
                                                  Icons.check_rounded,
                                                  size: 18,
                                                  color: primaryColor,
                                                )
                                              else
                                                const SizedBox(width: 18),
                                              const SizedBox(width: 8),
                                              Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.filterAll,
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'downloaded',
                                          child: Row(
                                            children: [
                                              if (_filterMode == 'downloaded')
                                                Icon(
                                                  Icons.check_rounded,
                                                  size: 18,
                                                  color: primaryColor,
                                                )
                                              else
                                                const SizedBox(width: 18),
                                              const SizedBox(width: 8),
                                              Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.filterDownloaded,
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'not_downloaded',
                                          child: Row(
                                            children: [
                                              if (_filterMode ==
                                                  'not_downloaded')
                                                Icon(
                                                  Icons.check_rounded,
                                                  size: 18,
                                                  color: primaryColor,
                                                )
                                              else
                                                const SizedBox(width: 18),
                                              const SizedBox(width: 8),
                                              Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.filterNotDownloaded,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    TextButton.icon(
                                      icon: Icon(
                                        _isMultiSelectMode
                                            ? Icons.close_rounded
                                            : Icons.checklist_rounded,
                                        size: 18,
                                        color: primaryColor,
                                      ),
                                      label: Text(
                                        _isMultiSelectMode
                                            ? (AppLocalizations.of(
                                                    context,
                                                  )?.cancel ??
                                                  'Cancel')
                                            : AppLocalizations.of(
                                                context,
                                              )!.selectMulti,
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isMultiSelectMode =
                                              !_isMultiSelectMode;
                                          if (!_isMultiSelectMode) {
                                            _selectedChapterIndices.clear();
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            if (_isMultiSelectMode) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${_selectedChapterIndices.length} ${AppLocalizations.of(context)!.selected}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: widget.textColor,
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          child: Row(
                                            children: [
                                              Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.selectMulti,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: primaryColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Icon(
                                                Icons.arrow_drop_down_rounded,
                                                color: primaryColor,
                                              ),
                                            ],
                                          ),
                                          onSelected: (val) {
                                            if (val == 'all') {
                                              _selectAll();
                                            }
                                            if (val == 'missing') {
                                              _selectMissing();
                                            }
                                            if (val == 'from_current') {
                                              _selectFromCurrentToEnd();
                                            }
                                            if (val == 'range') {
                                              _showSelectRangeDialog();
                                            }
                                            if (val == 'clear') {
                                              _deselectAll();
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              value: 'all',
                                              child: Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.selectAll,
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'missing',
                                              child: Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.selectMissing,
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'from_current',
                                              child: Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.selectFromCurrentToEnd,
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'range',
                                              child: Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.selectRange,
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'clear',
                                              child: Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.clearSelection,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            icon: const Icon(
                                              Icons.download_rounded,
                                              size: 16,
                                            ),
                                            label: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.downloadSelected,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: primaryColor,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: _startDownloadSelected,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 16,
                                              color: Colors.redAccent,
                                            ),
                                            label: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.deleteSelected,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.redAccent,
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(
                                                color: Colors.redAccent,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: _deleteSelected,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Chapter status list filling 100% remaining vertical height
                      Expanded(
                        child: ListView.builder(
                          controller: _autoScrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          itemCount: _displayChapters.length,
                          itemBuilder: (context, index) {
                            final ch = _displayChapters[index];
                            final isDownloading = _offlineService
                                .activeChapterIndices
                                .contains(ch.chapterIndex);
                            final isDownloaded = _downloadedChapterIndices
                                .contains(ch.chapterIndex);
                            final isFailed = _offlineService
                                .failedChapterIndices
                                .contains(ch.chapterIndex);
                            final status = isDownloading
                                ? 'downloading'
                                : (isFailed
                                      ? 'failed'
                                      : (isDownloaded ? 'completed' : 'idle'));
                            final chSize = _chapterSizes[ch.chapterIndex] ?? 0;
                            final isSelected = _selectedChapterIndices.contains(
                              ch.chapterIndex,
                            );

                            return AutoScrollTag(
                              key: ValueKey(ch.chapterIndex),
                              controller: _autoScrollController,
                              index: index,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryColor.withValues(alpha: 0.15)
                                      : (widget.isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.03,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.02,
                                              )),
                                  borderRadius: BorderRadius.circular(10),
                                  border: isSelected
                                      ? Border.all(
                                          color: primaryColor,
                                          width: 1.5,
                                        )
                                      : null,
                                ),
                                child: ListTile(
                                  dense: true,
                                  leading: _isMultiSelectMode
                                      ? Checkbox(
                                          value: isSelected,
                                          activeColor: primaryColor,
                                          onChanged: (val) {
                                            setState(() {
                                              if (val == true) {
                                                _selectedChapterIndices.add(
                                                  ch.chapterIndex,
                                                );
                                              } else {
                                                _selectedChapterIndices.remove(
                                                  ch.chapterIndex,
                                                );
                                              }
                                            });
                                          },
                                        )
                                      : null,
                                  title: Text(
                                    ch.title,
                                    style: TextStyle(
                                      color: widget.textColor,
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: status == 'downloading'
                                      ? const Text(
                                          'Downloading...',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.amber,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : status == 'failed'
                                      ? const Text(
                                          'Failed to download',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : (chSize > 0
                                            ? Text(
                                                _formatSize(chSize),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: primaryColor
                                                      .withValues(alpha: 0.8),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : null),
                                  trailing: status == 'downloading'
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.amber,
                                                ),
                                          ),
                                        )
                                      : status == 'failed'
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.error_outline_rounded,
                                              color: Colors.redAccent,
                                              size: 20,
                                            ),
                                            if (!_isMultiSelectMode)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.refresh_rounded,
                                                  size: 20,
                                                  color: Colors.amber,
                                                ),
                                                onPressed: () {
                                                  if (_settings != null) {
                                                    _offlineService
                                                        .startDownload(
                                                          book: widget.book,
                                                          chapters: [ch],
                                                          settings: _settings!,
                                                        );
                                                  }
                                                },
                                              ),
                                          ],
                                        )
                                      : status == 'completed'
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              color: Colors.green,
                                              size: 18,
                                            ),
                                            if (!_isMultiSelectMode)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline_rounded,
                                                  size: 18,
                                                  color: Colors.redAccent,
                                                ),
                                                onPressed: () async {
                                                  await _offlineService
                                                      .deleteOfflineTtsForChapter(
                                                        widget.book.uuid,
                                                        ch.chapterIndex,
                                                      );
                                                  await _loadStorageAndStatus();
                                                },
                                              ),
                                          ],
                                        )
                                      : (!_isMultiSelectMode
                                            ? IconButton(
                                                icon: const Icon(
                                                  Icons
                                                      .download_for_offline_outlined,
                                                  size: 20,
                                                ),
                                                onPressed: () {
                                                  if (_settings != null) {
                                                    _offlineService
                                                        .startDownload(
                                                          book: widget.book,
                                                          chapters: [ch],
                                                          settings: _settings!,
                                                        );
                                                  }
                                                },
                                              )
                                            : null),
                                  onTap: _isMultiSelectMode
                                      ? () {
                                          setState(() {
                                            if (isSelected) {
                                              _selectedChapterIndices.remove(
                                                ch.chapterIndex,
                                              );
                                            } else {
                                              _selectedChapterIndices.add(
                                                ch.chapterIndex,
                                              );
                                            }
                                          });
                                        }
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
