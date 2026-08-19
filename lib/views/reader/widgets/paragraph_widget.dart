import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audire_reader/services/tts_service.dart';

class ParagraphWidget extends StatefulWidget {
  final String text;
  final bool isActive;
  final bool isPlaying;
  final double fontSize;
  final double lineHeight;
  final double paragraphSpacing;
  final double paragraphIndent;
  final TextAlign textAlign;
  final int wordStart;
  final int wordEnd;
  final ValueNotifier<WordProgress>? wordProgressNotifier;
  final bool isDark;
  final String fontFamily;
  final Color textColor;
  final String? highlightColorHex;
  final bool hasNote;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ParagraphWidget({
    super.key,
    required this.text,
    required this.isActive,
    required this.isPlaying,
    required this.fontSize,
    required this.lineHeight,
    required this.paragraphSpacing,
    this.paragraphIndent = 0.0,
    required this.textAlign,
    this.wordStart = 0,
    this.wordEnd = 0,
    this.wordProgressNotifier,
    required this.isDark,
    required this.fontFamily,
    required this.textColor,
    this.highlightColorHex,
    this.hasNote = false,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<ParagraphWidget> createState() => _ParagraphWidgetState();
}

class _ParagraphWidgetState extends State<ParagraphWidget> {
  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _scrollToVisible();
    }
  }

  @override
  void didUpdateWidget(covariant ParagraphWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Tự động cuộn khi:
    // 1. Đoạn văn này vừa trở thành active (isActive: false -> true)
    // 2. Đoạn văn này đang active và TTS bắt đầu phát (isPlaying: false -> true)
    final becameActive = widget.isActive && !oldWidget.isActive;
    final startedPlayingWhileActive =
        widget.isActive && widget.isPlaying && !oldWidget.isPlaying;

    if (becameActive || startedPlayingWhileActive) {
      _scrollToVisible();
    }
  }

  void _scrollToVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.3,
        );
      }
    });
  }

  static final Map<String, Color> _hexColorCache = {};

  Color _parseHexColor(String hexStr) {
    final cached = _hexColorCache[hexStr];
    if (cached != null) return cached;

    String cleanHex = hexStr.replaceAll('#', '');
    if (cleanHex.length == 8) {
      final color = Color(int.parse(cleanHex, radix: 16));
      _hexColorCache[hexStr] = color;
      return color;
    }
    if (cleanHex.length == 6) {
      cleanHex = 'FF$cleanHex';
    }
    final color = Color(int.parse(cleanHex, radix: 16));
    _hexColorCache[hexStr] = color;
    return color;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(bottom: widget.paragraphSpacing),
        padding: EdgeInsets.zero,
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.only(right: widget.hasNote ? 24 : 0),
              child: _buildRichText(widget.textColor),
            ),
            if (widget.hasNote)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sticky_note_2_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  TextStyle _getFontFamilyStyle() {
    if (widget.fontFamily == 'System' || widget.fontFamily.isEmpty) {
      return const TextStyle();
    }
    if ([
      'Lora',
      'Merriweather',
      'Inter',
      'Nunito',
      'Roboto',
      'Open Sans',
      'Playfair Display',
      'PT Serif',
      'Quicksand',
    ].contains(widget.fontFamily)) {
      try {
        return GoogleFonts.getFont(widget.fontFamily);
      } catch (e) {
        return TextStyle(fontFamily: widget.fontFamily);
      }
    }
    return TextStyle(fontFamily: widget.fontFamily);
  }

  Widget _buildRichText(Color defaultColor) {
    Color? textBgColor;
    if (widget.isActive) {
      textBgColor = Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: widget.isDark ? 0.2 : 0.15);
    } else if (widget.highlightColorHex != null) {
      try {
        final parsedColor = _parseHexColor(widget.highlightColorHex!);
        textBgColor = parsedColor.withValues(
          alpha: widget.isDark ? 0.25 : 0.35,
        );
      } catch (e) {
        textBgColor = Colors.yellow.withValues(alpha: 0.3);
      }
    }

    final style = _getFontFamilyStyle().copyWith(
      fontSize: widget.fontSize,
      height: widget.lineHeight,
      color: defaultColor,
      letterSpacing: 0.2,
      backgroundColor: textBgColor,
    );

    if (!widget.isActive) {
      return DefaultTextStyle(
        style: style,
        textAlign: widget.textAlign,
        child: Text.rich(
          TextSpan(
            children: [
              if (widget.paragraphIndent > 0)
                WidgetSpan(child: SizedBox(width: widget.paragraphIndent)),
              TextSpan(text: widget.text),
            ],
          ),
        ),
      );
    }

    if (widget.wordProgressNotifier != null) {
      return ValueListenableBuilder<WordProgress>(
        valueListenable: widget.wordProgressNotifier!,
        builder: (context, progress, _) {
          return _buildTextWithWordHighlight(
            style: style,
            wordStart: progress.start,
            wordEnd: progress.end,
          );
        },
      );
    }

    return _buildTextWithWordHighlight(
      style: style,
      wordStart: widget.wordStart,
      wordEnd: widget.wordEnd,
    );
  }

  Widget _buildTextWithWordHighlight({
    required TextStyle style,
    required int wordStart,
    required int wordEnd,
  }) {
    if (wordStart >= wordEnd || wordEnd > widget.text.length) {
      return DefaultTextStyle(
        style: style,
        textAlign: widget.textAlign,
        child: Text.rich(
          TextSpan(
            children: [
              if (widget.paragraphIndent > 0)
                WidgetSpan(child: SizedBox(width: widget.paragraphIndent)),
              TextSpan(text: widget.text),
            ],
          ),
        ),
      );
    }

    final before = widget.text.substring(0, wordStart);
    final word = widget.text.substring(wordStart, wordEnd);
    final after = widget.text.substring(wordEnd);

    return DefaultTextStyle(
      style: style,
      textAlign: widget.textAlign,
      child: Text.rich(
        TextSpan(
          children: [
            if (widget.paragraphIndent > 0)
              WidgetSpan(child: SizedBox(width: widget.paragraphIndent)),
            TextSpan(text: before),
            TextSpan(
              text: word,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w900,
                backgroundColor: Colors.black12,
              ),
            ),
            TextSpan(text: after),
          ],
        ),
      ),
    );
  }
}
