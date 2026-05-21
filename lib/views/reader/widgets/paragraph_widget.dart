import 'package:flutter/material.dart';

class ParagraphWidget extends StatefulWidget {
  final String text;
  final bool isActive;
  final double fontSize;
  final int wordStart;
  final int wordEnd;
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
    required this.fontSize,
    required this.wordStart,
    required this.wordEnd,
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
    if (widget.isActive && !oldWidget.isActive) {
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

  Color _parseHexColor(String hexStr) {
    String cleanHex = hexStr.replaceAll('#', '');
    if (cleanHex.length == 8) {
      return Color(int.parse(cleanHex, radix: 16));
    }
    if (cleanHex.length == 6) {
      cleanHex = 'FF$cleanHex';
    }
    return Color(int.parse(cleanHex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final activeBgColor = widget.isDark ? Colors.amber[900]!.withValues(alpha: 0.2) : Colors.amber[100]!;

    Color? highlightBgColor;
    if (widget.highlightColorHex != null) {
      try {
        final parsedColor = _parseHexColor(widget.highlightColorHex!);
        highlightBgColor = parsedColor.withValues(alpha: widget.isDark ? 0.25 : 0.35);
      } catch (e) {
        highlightBgColor = Colors.yellow.withValues(alpha: 0.3);
      }
    }

    final bgColor = widget.isActive 
        ? activeBgColor 
        : (highlightBgColor ?? Colors.transparent);

    final border = widget.isActive
        ? Border.all(color: Colors.amber[700]!.withValues(alpha: 0.5), width: 1)
        : (widget.highlightColorHex != null 
            ? Border.all(color: _parseHexColor(widget.highlightColorHex!).withValues(alpha: 0.3), width: 1)
            : null);

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: border,
        ),
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
                    color: Colors.amber[700],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sticky_note_2_rounded, 
                    size: 12, 
                    color: Colors.white
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRichText(Color defaultColor) {
    final style = TextStyle(
      fontSize: widget.fontSize,
      fontFamily: widget.fontFamily == 'System' ? null : widget.fontFamily,
      height: 1.6,
      color: defaultColor,
      letterSpacing: 0.2,
    );

    if (!widget.isActive || widget.wordStart >= widget.wordEnd || widget.wordEnd > widget.text.length) {
      return Text(
        widget.text,
        style: style,
        textAlign: TextAlign.left,
      );
    }

    final before = widget.text.substring(0, widget.wordStart);
    final word = widget.text.substring(widget.wordStart, widget.wordEnd);
    final after = widget.text.substring(widget.wordEnd);

    return RichText(
      textAlign: TextAlign.left,
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: before),
          TextSpan(
            text: word,
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.w900,
              backgroundColor: Colors.black12,
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}
