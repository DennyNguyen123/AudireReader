import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/settings.dart';
import '../../../services/tts_service.dart';
import '../../../l10n/app_localizations.dart';
import 'reader_tts_settings_sheet.dart';
import 'bgm_player_sheet.dart';

class AssistiveButton extends StatefulWidget {
  final TtsService ttsService;
  final AppSettings settings;
  final Function(double x, double y) onPositionChanged;
  final VoidCallback? onExitFullscreen;
  final bool isDark;

  const AssistiveButton({
    super.key,
    required this.ttsService,
    required this.settings,
    required this.onPositionChanged,
    this.onExitFullscreen,
    required this.isDark,
  });

  @override
  State<AssistiveButton> createState() => _AssistiveButtonState();
}

class _AssistiveButtonState extends State<AssistiveButton> {
  late double _x;
  late double _y;
  bool _isInitialized = false;
  bool _isDragging = false;
  double _opacity = 0.85;
  Timer? _dimTimer;

  static const double buttonSize = 48.0;

  @override
  void initState() {
    super.initState();
    _x = widget.settings.assistiveButtonX;
    _y = widget.settings.assistiveButtonY;
    _resetDimTimer();
  }

  @override
  void didUpdateWidget(covariant AssistiveButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.settings.assistiveButtonX != oldWidget.settings.assistiveButtonX ||
        widget.settings.assistiveButtonY != oldWidget.settings.assistiveButtonY) {
      setState(() {
        _x = widget.settings.assistiveButtonX;
        _y = widget.settings.assistiveButtonY;
      });
    }
  }

  @override
  void dispose() {
    _dimTimer?.cancel();
    super.dispose();
  }

  void _resetDimTimer() {
    _dimTimer?.cancel();
    if (mounted) {
      setState(() {
        _opacity = 0.85;
      });
    }
    _dimTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isDragging) {
        setState(() {
          _opacity = 0.35;
        });
      }
    });
  }

  void _showControlMenu(BuildContext context) {
    _resetDimTimer();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        final isDark = widget.isDark;
        final bg = isDark ? const Color(0xFF1E1E2C) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;

        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.readerControlsTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 20),

              // Player Controls Row
              ListenableBuilder(
                listenable: widget.ttsService,
                builder: (context, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.skip_previous_rounded),
                        tooltip: l10n.actionPrevChapter,
                        onPressed: () {
                          if (widget.ttsService.currentChapterIndex > 0) {
                            widget.ttsService.previousChapter();
                          }
                        },
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.fast_rewind_rounded),
                        tooltip: l10n.actionPrevParagraph,
                        onPressed: () => widget.ttsService.previousParagraph(),
                      ),
                      IconButton.filled(
                        iconSize: 32,
                        icon: Icon(widget.ttsService.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                        tooltip: l10n.actionPlayPause,
                        onPressed: () => widget.ttsService.togglePlayPause(),
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.fast_forward_rounded),
                        tooltip: l10n.actionNextParagraph,
                        onPressed: () => widget.ttsService.nextParagraph(),
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.skip_next_rounded),
                        tooltip: l10n.actionNextChapter,
                        onPressed: () {
                          if (widget.ttsService.currentChapterIndex < widget.ttsService.chapters.length - 1) {
                            widget.ttsService.nextChapter();
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Bottom Actions: TTS, BGM, Exit Fullscreen
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.tune_rounded, size: 20),
                    label: Text(l10n.voice),
                    onPressed: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) => ReaderTtsSettingsSheet(
                          ttsService: widget.ttsService,
                        ),
                      );
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.music_note_rounded, size: 20),
                    label: Text(l10n.bgmLocalFile),
                    onPressed: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) => const BgmPlayerSheet(),
                      );
                    },
                  ),
                  if (widget.onExitFullscreen != null)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.errorContainer,
                        foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      icon: const Icon(Icons.fullscreen_exit_rounded, size: 20),
                      label: Text(l10n.exitFullscreen),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onExitFullscreen?.call();
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    // Thiết lập vị trí mặc định nếu chưa lưu (góc dưới cùng bên phải)
    if (!_isInitialized) {
      if (_x < 0 || _y < 0) {
        _x = screenSize.width - buttonSize - 16.0;
        _y = screenSize.height - buttonSize - 120.0;
      }
      _isInitialized = true;
    }

    // Giới hạn tọa độ trong màn hình
    final minX = 8.0;
    final maxX = screenSize.width - buttonSize - 8.0;
    final minY = padding.top + 8.0;
    final maxY = screenSize.height - padding.bottom - buttonSize - 8.0;

    _x = _x.clamp(minX, maxX);
    _y = _y.clamp(minY, maxY);

    return Positioned(
      left: _x,
      top: _y,
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _isDragging = true;
            _opacity = 0.85;
          });
          _dimTimer?.cancel();
        },
        onPanUpdate: (details) {
          setState(() {
            _x += details.delta.dx;
            _y += details.delta.dy;
            _x = _x.clamp(minX, maxX);
            _y = _y.clamp(minY, maxY);
          });
        },
        onPanEnd: (details) {
          setState(() {
            _isDragging = false;
          });
          widget.onPositionChanged(_x, _y);
          _resetDimTimer();

          // Nếu kéo gần tới đáy màn hình -> Tự động dock về thanh đáy (Thoát Fullscreen)
          if (_y >= maxY - 30.0 && widget.onExitFullscreen != null) {
            widget.onExitFullscreen!();
          }
        },
        onTap: () {
          _resetDimTimer();
          widget.ttsService.nextParagraph();
        },
        onLongPress: () => _showControlMenu(context),
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 250),
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Icons.fast_forward_rounded,
              color: Colors.white.withValues(alpha: 0.95),
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
