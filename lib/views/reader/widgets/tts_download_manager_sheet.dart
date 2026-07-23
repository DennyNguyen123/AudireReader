import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/book.dart';
import '../../../models/chapter.dart';
import '../../../models/settings.dart';
import '../../../services/offline_tts_service.dart';

class TtsDownloadManagerSheet extends StatefulWidget {
  final Book book;
  final List<Chapter> chapters;
  final bool isDark;
  final Color textColor;
  final Color sheetBg;

  const TtsDownloadManagerSheet({
    super.key,
    required this.book,
    required this.chapters,
    required this.isDark,
    required this.textColor,
    required this.sheetBg,
  });

  @override
  State<TtsDownloadManagerSheet> createState() => _TtsDownloadManagerSheetState();
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

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _offlineService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _offlineService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (!mounted) return;
    if (_offlineService.isDownloading) {
      setState(() {});
    } else {
      _loadStorageAndStatus();
    }
  }

  Future<void> _loadInitialData() async {
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();
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
    final size = await _offlineService.getStorageUsage(widget.book.uuid);
    final sizes = await _offlineService.getChapterStorageSizes(widget.book.uuid);
    final downloaded = <int>{};
    if (_settings != null) {
      for (final ch in widget.chapters) {
        final isDownloaded = await _offlineService.isChapterDownloaded(
          widget.book.uuid,
          ch.chapterIndex,
          _settings!,
        );
        if (isDownloaded) {
          downloaded.add(ch.chapterIndex);
        }
      }
    }
    if (mounted) {
      setState(() {
        _storageSize = size;
        _chapterSizes = sizes;
        _downloadedChapterIndices = downloaded;
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
    final int newConcurrency = val.round().clamp(1, 10);
    setState(() {
      _settings!.ttsDownloadConcurrency = newConcurrency;
    });
    final db = await DatabaseHelper.getInstance();
    await db.saveSettings(_settings!);
  }

  void _startDownloadAll() {
    if (_settings == null) return;
    _offlineService.startDownload(
      book: widget.book,
      chapters: widget.chapters,
      settings: _settings!,
    );
  }

  void _startDownloadUndownloaded() {
    if (_settings == null) return;
    final undownloaded = widget.chapters.where((ch) => !_downloadedChapterIndices.contains(ch.chapterIndex)).toList();
    if (undownloaded.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.vietnamese == 'Tiếng Việt' ? 'Tất cả các chương đã được tải xuống' : 'All chapters are already downloaded')),
      );
      return;
    }
    _offlineService.startDownload(
      book: widget.book,
      chapters: undownloaded,
      settings: _settings!,
    );
  }

  void _startDownloadSelected() {
    if (_settings == null || _selectedChapterIndices.isEmpty) return;
    final selectedChapters = widget.chapters.where((ch) => _selectedChapterIndices.contains(ch.chapterIndex)).toList();
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
        title: Text(AppLocalizations.of(context)?.vietnamese == 'Tiếng Việt' ? 'Xoá các chương đã chọn' : 'Delete selected chapters'),
        content: Text(AppLocalizations.of(context)?.vietnamese == 'Tiếng Việt' ? 'Bạn có chắc chắn muốn xoá TTS offline của $count chương đã chọn?' : 'Are you sure you want to delete offline TTS for $count selected chapters?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(AppLocalizations.of(context)?.deleteBook ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _offlineService.deleteOfflineTtsForChapters(widget.book.uuid, _selectedChapterIndices.toList());
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
        title: Text(AppLocalizations.of(context)?.vietnamese == 'Tiếng Việt' ? 'Xoá tất cả TTS Offline' : 'Delete all offline TTS'),
        content: Text(AppLocalizations.of(context)?.vietnamese == 'Tiếng Việt' ? 'Bạn có chắc chắn muốn xoá toàn bộ dữ liệu audio TTS offline của cuốn sách này?' : 'Are you sure you want to delete all offline TTS audio files for this book?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel')),
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
      _selectedChapterIndices.addAll(widget.chapters.map((c) => c.chapterIndex));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedChapterIndices.clear();
    });
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
          height: MediaQuery.of(context).size.height * 0.85,
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.vietnamese == 'Tiếng Việt' ? 'Quản lý TTS Offline' : 'Offline TTS Manager',
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
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Storage usage card
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppLocalizations.of(context)?.vietnamese == 'Tiếng Việt' ? 'Dung lượng đã sử dụng' : 'Storage used',
                                          style: TextStyle(fontSize: 12, color: widget.textColor.withValues(alpha: 0.7)),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatSize(_storageSize),
                                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                                        ),
                                        Text(
                                          '${_downloadedChapterIndices.length} / ${widget.chapters.length} ${AppLocalizations.of(context)?.vietnamese == 'Tiếng Việt' ? 'chương đã tải' : 'chapters downloaded'}',
                                          style: TextStyle(fontSize: 12, color: widget.textColor.withValues(alpha: 0.6)),
                                        ),
                                      ],
                                    ),
                                    if (_storageSize > 0)
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                        label: Text(AppLocalizations.of(context)?.vietnamese == 'Tiếng Việt' ? 'Xoá tất cả' : 'Delete All', style: const TextStyle(color: Colors.redAccent)),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Colors.redAccent),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        onPressed: _confirmDeleteAll,
                                      ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Concurrency slider
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          AppLocalizations.of(context)?.vietnamese == 'Tiếng Việt' ? 'Số luồng tải song song' : 'Parallel download threads',
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: widget.textColor),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${(_settings?.ttsDownloadConcurrency ?? 3).clamp(1, 10)}',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Slider(
                                      value: (_settings?.ttsDownloadConcurrency ?? 3).clamp(1, 10).toDouble(),
                                      min: 1.0,
                                      max: 10.0,
                                      divisions: 9,
                                      activeColor: primaryColor,
                                      onChanged: _updateConcurrency,
                                    ),
                                    if (((_settings?.ttsDownloadConcurrency ?? 3).clamp(1, 10)) > 5)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          AppLocalizations.of(context)?.vietnamese == 'Tiếng Việt' 
                                              ? '⚠️ Số luồng cao (>5) có thể khiến server Edge/OpenAI tạm ngắt băng thông (lỗi 429).' 
                                              : '⚠️ High thread count (>5) may cause server rate-limiting (HTTP 429).',
                                          style: const TextStyle(fontSize: 11, color: Colors.orangeAccent),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Action buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.download_rounded),
                                      label: Text(AppLocalizations.of(context)?.vietnamese == 'Tiếng Việt' ? 'Tải các chương chưa tải' : 'Download missing'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: _offlineService.isDownloading ? null : _startDownloadUndownloaded,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.select_all_rounded),
                                    label: Text(AppLocalizations.of(context)?.vietnamese == 'Tiếng Việt' ? 'Tải tất cả' : 'Download All'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: _offlineService.isDownloading ? null : _startDownloadAll,
                                  ),
                                ],
                              ),

                              if (_offlineService.isDownloading || _offlineService.isPaused)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2.5),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            '${AppLocalizations.of(context)?.vietnamese == 'Tiếng Việt' ? 'Đang tải' : 'Downloading'} ${_offlineService.completedChaptersCount}/${_offlineService.totalChaptersToDownload}',
                                            style: TextStyle(fontWeight: FontWeight.bold, color: widget.textColor),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(_offlineService.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: primaryColor),
                                          onPressed: () {
                                            if (_offlineService.isPaused && _settings != null) {
                                              _offlineService.resumeDownload(widget.book, _settings!);
                                            } else {
                                              _offlineService.pauseDownload();
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                                          onPressed: () => _offlineService.cancelDownload(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 20),

                              // Chapter list header with Multi-select toggle
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)?.vietnamese == 'Tiếng Việt' ? 'Danh sách chương' : 'Chapter List',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: widget.textColor),
                                  ),
                                  TextButton.icon(
                                    icon: Icon(_isMultiSelectMode ? Icons.close_rounded : Icons.checklist_rounded, size: 18),
                                    label: Text(_isMultiSelectMode 
                                        ? (AppLocalizations.of(context)?.vietnamese == 'Tiếng Việt' ? 'Hủy chọn' : 'Cancel') 
                                        : (AppLocalizations.of(context)?.vietnamese == 'Tiếng Việt' ? 'Chọn nhiều' : 'Select Multi')),
                                    onPressed: () {
                                      setState(() {
                                        _isMultiSelectMode = !_isMultiSelectMode;
                                        _selectedChapterIndices.clear();
                                      });
                                    },
                                  ),
                                ],
                              ),

                              // Multi-select actions bar
                              if (_isMultiSelectMode)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${AppLocalizations.of(context)?.vietnamese == 'Tiếng Việt' ? 'Đã chọn' : 'Selected'}: ${_selectedChapterIndices.length}',
                                              style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                                            ),
                                            Row(
                                              children: [
                                                TextButton(
                                                  onPressed: _selectAll,
                                                  child: Text(AppLocalizations.of(context)?.vietnamese == 'Tiếng Việt' ? 'Tất cả' : 'Select All'),
                                                ),
                                                TextButton(
                                                  onPressed: _deselectAll,
                                                  child: Text(AppLocalizations.of(context)?.vietnamese == 'Tiếng Việt' ? 'Bỏ chọn' : 'Clear'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        if (_selectedChapterIndices.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  icon: const Icon(Icons.download_rounded, size: 18),
                                                  label: Text(AppLocalizations.of(context)?.vietnamese == 'Tiếng Việt' ? 'Tải đã chọn' : 'Download'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: primaryColor,
                                                    foregroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  ),
                                                  onPressed: _startDownloadSelected,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                                  label: Text(AppLocalizations.of(context)?.vietnamese == 'Tiếng Việt' ? 'Xoá đã chọn' : 'Delete', style: const TextStyle(color: Colors.redAccent)),
                                                  style: OutlinedButton.styleFrom(
                                                    side: const BorderSide(color: Colors.redAccent),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  ),
                                                  onPressed: _deleteSelected,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Chapter status list using lazy SliverList.builder
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList.builder(
                          itemCount: widget.chapters.length,
                          itemBuilder: (context, index) {
                            final ch = widget.chapters[index];
                            final isDownloaded = _downloadedChapterIndices.contains(ch.chapterIndex);
                            final status = _offlineService.chapterStatus[ch.chapterIndex] ?? (isDownloaded ? 'completed' : 'idle');
                            final progress = _offlineService.chapterProgress[ch.chapterIndex] ?? (isDownloaded ? 1.0 : 0.0);
                            final chSize = _chapterSizes[ch.chapterIndex] ?? 0;
                            final isSelected = _selectedChapterIndices.contains(ch.chapterIndex);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? primaryColor.withValues(alpha: 0.15)
                                    : (widget.isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
                                borderRadius: BorderRadius.circular(10),
                                border: isSelected ? Border.all(color: primaryColor, width: 1.5) : null,
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
                                              _selectedChapterIndices.add(ch.chapterIndex);
                                            } else {
                                              _selectedChapterIndices.remove(ch.chapterIndex);
                                            }
                                          });
                                        },
                                      )
                                    : null,
                                title: Text(ch.title, style: TextStyle(color: widget.textColor, fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                subtitle: status == 'downloading'
                                    ? ExcludeSemantics(
                                        child: LinearProgressIndicator(value: progress, minHeight: 3),
                                      )
                                    : (chSize > 0
                                        ? Text(
                                            _formatSize(chSize),
                                            style: TextStyle(fontSize: 11, color: primaryColor.withValues(alpha: 0.8), fontWeight: FontWeight.bold),
                                          )
                                        : null),
                                trailing: status == 'downloading'
                                    ? ExcludeSemantics(
                                        child: Text('${(progress * 100).toInt()}%', style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                      )
                                    : status == 'completed'
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                                              if (!_isMultiSelectMode)
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                                  onPressed: () async {
                                                    await _offlineService.deleteOfflineTtsForChapter(widget.book.uuid, ch.chapterIndex);
                                                    await _loadStorageAndStatus();
                                                  },
                                                ),
                                            ],
                                          )
                                        : (!_isMultiSelectMode
                                            ? IconButton(
                                                icon: const Icon(Icons.download_for_offline_outlined, size: 20),
                                                onPressed: () {
                                                  if (_settings != null) {
                                                    _offlineService.startDownload(
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
                                            _selectedChapterIndices.remove(ch.chapterIndex);
                                          } else {
                                            _selectedChapterIndices.add(ch.chapterIndex);
                                          }
                                        });
                                      }
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                      const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
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
