import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/settings.dart';
import '../../../services/tts_service.dart';
import 'reader_tts_settings_sheet.dart';
import 'bgm_player_sheet.dart';

class AssistiveButton extends StatefulWidget {
  final TtsService ttsService;
  final AppSettings settings;
  final Function(double x, double y) onPositionChanged;
  final bool isDark;

  const AssistiveButton({
    super.key,
    required this.ttsService,
    required this.settings,
    required this.onPositionChanged,
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
    // Nếu tọa độ lưu trong settings thay đổi từ bên ngoài (ví dụ reset)
    if (widget.settings.assistiveButtonX !=
            oldWidget.settings.assistiveButtonX ||
        widget.settings.assistiveButtonY !=
            oldWidget.settings.assistiveButtonY) {
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

  void _executeAction(BuildContext context, String actionType) {
    _resetDimTimer();
    switch (actionType) {
      case 'nextParagraph':
        widget.ttsService.nextParagraph();
        break;
      case 'prevParagraph':
        widget.ttsService.previousParagraph();
        break;
      case 'playPause':
        widget.ttsService.togglePlayPause();
        break;
      case 'nextChapter':
        if (widget.ttsService.currentChapterIndex <
            widget.ttsService.chapters.length - 1) {
          widget.ttsService.nextChapter();
        }
        break;
      case 'prevChapter':
        if (widget.ttsService.currentChapterIndex > 0) {
          widget.ttsService.previousChapter();
        }
        break;
      case 'openTtsSettings':
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) =>
              ReaderTtsSettingsSheet(ttsService: widget.ttsService),
        );
        break;
      case 'openBgmSettings':
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => const BgmPlayerSheet(),
        );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    // Thiết lập vị trí mặc định nếu chưa lưu (góc dưới cùng bên phải)
    if (!_isInitialized) {
      if (_x < 0 || _y < 0) {
        _x = screenSize.width - buttonSize - 16.0;
        // Đặt ở tầm 2/3 chiều cao màn hình để tránh đè lên Bottom Panel
        _y = screenSize.height - buttonSize - 120.0;
      }
      _isInitialized = true;
    }

    // Giới hạn tọa độ trong màn hình để nút không bị biến mất
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
        },
        onTap: () =>
            _executeAction(context, widget.settings.assistiveSingleTapAction),
        onDoubleTap: () =>
            _executeAction(context, widget.settings.assistiveDoubleTapAction),
        onLongPress: () =>
            _executeAction(context, widget.settings.assistiveLongPressAction),
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 250),
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.8),
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
              Icons.blur_circular_rounded,
              color: Colors.white.withValues(alpha: 0.9),
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
