import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/tts_service.dart';
import '../../../core/theme_notifier.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ReaderSettingsSheet extends StatefulWidget {
  final TtsService ttsService;
  final String themeMode;
  final double fontSize;
  final String fontFamily;

  final double lineHeight;
  final double paragraphSpacing;
  final String textAlignment;
  final double sideMargin;
  final String? customBackgroundColor;
  final String? customTextColor;

  final ValueChanged<String> onThemeModeChanged;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<String> onFontFamilyChanged;
  final ValueChanged<double> onLineHeightChanged;
  final ValueChanged<double> onParagraphSpacingChanged;
  final ValueChanged<String> onTextAlignmentChanged;
  final ValueChanged<double> onSideMarginChanged;
  final Function(String? bg, String? text) onCustomColorChanged;

  const ReaderSettingsSheet({
    super.key,
    required this.ttsService,
    required this.themeMode,
    required this.fontSize,
    required this.fontFamily,
    required this.lineHeight,
    required this.paragraphSpacing,
    required this.textAlignment,
    required this.sideMargin,
    this.customBackgroundColor,
    this.customTextColor,
    required this.onThemeModeChanged,
    required this.onFontSizeChanged,
    required this.onFontFamilyChanged,
    required this.onLineHeightChanged,
    required this.onParagraphSpacingChanged,
    required this.onTextAlignmentChanged,
    required this.onSideMarginChanged,
    required this.onCustomColorChanged,
  });

  @override
  State<ReaderSettingsSheet> createState() => _ReaderSettingsSheetState();
}

class _ReaderSettingsSheetState extends State<ReaderSettingsSheet> {
  late String _themeMode;
  late double _fontSize;
  late String _fontFamily;

  late double _lineHeight;
  late double _paragraphSpacing;
  late String _textAlignment;
  late double _sideMargin;
  String? _customBackgroundColor;
  String? _customTextColor;

  late final TextEditingController _customBgController;
  late final TextEditingController _customTextController;

  bool _showAssistiveButton = false;
  String _assistiveSingleTapAction = 'nextParagraph';
  String _assistiveDoubleTapAction = 'prevParagraph';
  String _assistiveLongPressAction = 'playPause';

  @override
  void initState() {
    super.initState();
    _themeMode = widget.themeMode;
    _fontSize = widget.fontSize;
    _fontFamily = widget.fontFamily;

    _lineHeight = widget.lineHeight;
    _paragraphSpacing = widget.paragraphSpacing;
    _textAlignment = widget.textAlignment;
    _sideMargin = widget.sideMargin;
    _customBackgroundColor = widget.customBackgroundColor;
    _customTextColor = widget.customTextColor;

    _customBgController = TextEditingController(text: _customBackgroundColor);
    _customTextController = TextEditingController(text: _customTextColor);
    
    _loadAssistiveSettings();
  }

  void _loadAssistiveSettings() async {
    final settings = await widget.ttsService.getSettings();
    if (mounted) {
      setState(() {
        _showAssistiveButton = settings.showAssistiveButton;
        _assistiveSingleTapAction = settings.assistiveSingleTapAction;
        _assistiveDoubleTapAction = settings.assistiveDoubleTapAction;
        _assistiveLongPressAction = settings.assistiveLongPressAction;
      });
    }
  }

  @override
  void dispose() {
    _customBgController.dispose();
    _customTextController.dispose();
    super.dispose();
  }

  bool _getIsDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = _getIsDark(context);
    final sheetBg = theme.scaffoldBackgroundColor;
    final labelColor = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white70 : Colors.black87);
    final accentColor = theme.colorScheme.primary;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                sheetBg.withValues(alpha: isDark ? 0.75 : 0.85),
                sheetBg.withValues(alpha: isDark ? 0.85 : 0.95),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.06),
                width: 1.5,
              ),
            ),
          ),
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.readerSettings,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 🎨 NHÓM 1: DISPLAY & TYPOGRAPHY
                Row(
                  children: [
                    Icon(Icons.format_paint_rounded, size: 16, color: accentColor),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.displayTypography,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // CHỌN CHỦ ĐỀ ĐỌC (Theme Mode Row)
            Text(AppLocalizations.of(context)!.readingTheme, style: TextStyle(fontWeight: FontWeight.bold, color: labelColor)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['System', 'Light', 'Dark', 'Sepia', 'Custom'].map((theme) {
                final isSelected = _themeMode == theme;
                Color btnBg;
                Color textCol;
                IconData icon;
                
                if (theme == 'System') {
                  btnBg = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0);
                  textCol = isDark ? Colors.white70 : Colors.black87;
                  icon = Icons.brightness_auto_rounded;
                } else if (theme == 'Light') {
                  btnBg = Colors.white;
                  textCol = Colors.black87;
                  icon = Icons.wb_sunny_rounded;
                } else if (theme == 'Dark') {
                  btnBg = const Color(0xFF121212);
                  textCol = Colors.white70;
                  icon = Icons.nightlight_round;
                } else if (theme == 'Sepia') {
                  btnBg = const Color(0xFFF4ECD8);
                  textCol = const Color(0xFF5B4636);
                  icon = Icons.menu_book_rounded;
                } else {
                  btnBg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE8EAF6);
                  textCol = isDark ? Colors.tealAccent : Colors.indigo;
                  icon = Icons.color_lens_rounded;
                }
                
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _themeMode = theme;
                      });
                      widget.onThemeModeChanged(theme);
                      widget.ttsService.updateSettings(themeMode: theme);
                      ThemeNotifier.instance.updateTheme(theme);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: btnBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                              ? accentColor 
                              : (isDark ? Colors.white10 : Colors.black12),
                          width: isSelected ? 2.5 : 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ] : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon, 
                            color: isSelected ? accentColor : textCol.withValues(alpha: 0.8), 
                            size: 18
                          ),
                          const SizedBox(height: 4),
                          Text(
                            theme == 'System' 
                                ? AppLocalizations.of(context)!.system 
                                : theme == 'Light' 
                                    ? AppLocalizations.of(context)!.light 
                                    : theme == 'Dark' 
                                        ? AppLocalizations.of(context)!.dark 
                                        : theme == 'Sepia'
                                            ? AppLocalizations.of(context)!.sepia
                                            : 'Custom',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? accentColor : textCol,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // CỠ CHỮ VÀ FONT
            Text(AppLocalizations.of(context)!.fontStyle, style: TextStyle(fontWeight: FontWeight.bold, color: labelColor)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: ['System', 'Serif', 'Sans-Serif', 'Monospace', 'Lora', 'Merriweather', 'Inter', 'Nunito'].contains(_fontFamily) 
                  ? _fontFamily 
                  : 'System',
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.black12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              dropdownColor: sheetBg,
              items: ['System', 'Serif', 'Sans-Serif', 'Monospace', 'Lora', 'Merriweather', 'Inter', 'Nunito'].map((font) {
                return DropdownMenuItem<String>(
                  value: font,
                  child: Text(
                    font,
                    style: TextStyle(
                      color: labelColor,
                      fontFamily: font == 'System' ? null : font.toLowerCase()
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _fontFamily = val;
                  });
                  widget.onFontFamilyChanged(val);
                  widget.ttsService.updateSettings(fontFamily: val);
                }
              },
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                const Icon(Icons.format_size_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: _fontSize,
                    min: 14.0,
                    max: 28.0,
                    divisions: 14,
                    activeColor: accentColor,
                    label: _fontSize.round().toString(),
                    onChanged: (val) {
                      setState(() {
                        _fontSize = val;
                      });
                      widget.onFontSizeChanged(val);
                      widget.ttsService.updateSettings(fontSize: val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
 
            // KHOẢNG CÁCH DÒNG (LINE HEIGHT)
            Row(
              children: [
                const Icon(Icons.format_line_spacing_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: _lineHeight,
                    min: 1.2,
                    max: 2.2,
                    divisions: 10,
                    activeColor: accentColor,
                    label: _lineHeight.toStringAsFixed(1),
                    onChanged: (val) {
                      setState(() {
                        _lineHeight = val;
                      });
                      widget.onLineHeightChanged(val);
                      widget.ttsService.updateSettings(lineHeight: val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
 
            // KHOẢNG CÁCH ĐOẠN VÀ LỀ HAI BÊN
            Row(
              children: [
                const Icon(Icons.straighten_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Paragraph Spacing', style: TextStyle(fontSize: 12, color: labelColor)),
                      Slider(
                        value: _paragraphSpacing,
                        min: 4.0,
                        max: 32.0,
                        divisions: 14,
                        activeColor: accentColor,
                        label: _paragraphSpacing.round().toString(),
                        onChanged: (val) {
                          setState(() {
                            _paragraphSpacing = val;
                          });
                          widget.onParagraphSpacingChanged(val);
                          widget.ttsService.updateSettings(paragraphSpacing: val);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Side Margin', style: TextStyle(fontSize: 12, color: labelColor)),
                      Slider(
                        value: _sideMargin,
                        min: 0.0,
                        max: 60.0,
                        divisions: 12,
                        activeColor: accentColor,
                        label: _sideMargin.round().toString(),
                        onChanged: (val) {
                          setState(() {
                            _sideMargin = val;
                          });
                          widget.onSideMarginChanged(val);
                          widget.ttsService.updateSettings(sideMargin: val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // CHỌN PHÔNG CHỮ (Font Family Dropdown)
            Row(
              children: [
                const Icon(Icons.font_download_rounded),
                const SizedBox(width: 12),
                Text(AppLocalizations.of(context)!.fontStyle, style: TextStyle(fontWeight: FontWeight.bold, color: labelColor)),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: [
                'System', 'Serif', 'Sans-Serif', 'Monospace', 
                'Lora', 'Merriweather', 'Inter', 'Nunito',
                'Roboto', 'Open Sans', 'Playfair Display', 'PT Serif', 'Quicksand'
              ].contains(_fontFamily) ? _fontFamily : 'System',
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.black12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              dropdownColor: sheetBg,
              items: [
                'System', 'Serif', 'Sans-Serif', 'Monospace', 
                'Lora', 'Merriweather', 'Inter', 'Nunito',
                'Roboto', 'Open Sans', 'Playfair Display', 'PT Serif', 'Quicksand'
              ].map((font) {
                return DropdownMenuItem<String>(
                  value: font,
                  child: Text(
                    font,
                    style: TextStyle(
                      fontFamily: ['System', 'Serif', 'Sans-Serif', 'Monospace'].contains(font)
                          ? (font == 'System' ? null : font.toLowerCase())
                          : font,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _fontFamily = val;
                  });
                  widget.onFontFamilyChanged(val);
                  widget.ttsService.updateSettings(fontFamily: val);
                }
              },
            ),
            const SizedBox(height: 16),

            // CĂN LỀ TEXT (ALIGNMENT)
            Row(
              children: [
                const Icon(Icons.format_align_left_rounded),
                const SizedBox(width: 12),
                Text('Text Alignment', style: TextStyle(fontWeight: FontWeight.bold, color: labelColor)),
                const Spacer(),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'left', icon: Icon(Icons.format_align_left_rounded)),
                    ButtonSegment(value: 'justify', icon: Icon(Icons.format_align_justify_rounded)),
                  ],
                  selected: {_textAlignment},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _textAlignment = newSelection.first;
                    });
                    widget.onTextAlignmentChanged(newSelection.first);
                    widget.ttsService.updateSettings(textAlignment: newSelection.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_themeMode == 'Custom') ...[
              const SizedBox(height: 16),
              Text('Custom Colors', style: TextStyle(fontWeight: FontWeight.bold, color: labelColor)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customBgController,
                      decoration: InputDecoration(
                        labelText: 'Background (Hex)',
                        filled: true,
                        fillColor: isDark ? Colors.white10 : Colors.black12,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.palette_rounded),
                          onPressed: () => _showColorPicker(_customBackgroundColor ?? '', (val) {
                            setState(() {
                              _customBackgroundColor = val;
                              _customBgController.text = val;
                            });
                            widget.onCustomColorChanged(_customBackgroundColor, _customTextColor);
                            widget.ttsService.updateSettings(customBackgroundColor: val);
                          }),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _customBackgroundColor = val;
                        });
                        widget.onCustomColorChanged(_customBackgroundColor, _customTextColor);
                        widget.ttsService.updateSettings(customBackgroundColor: val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _customTextController,
                      decoration: InputDecoration(
                        labelText: 'Text (Hex)',
                        filled: true,
                        fillColor: isDark ? Colors.white10 : Colors.black12,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.palette_rounded),
                          onPressed: () => _showColorPicker(_customTextColor ?? '', (val) {
                            setState(() {
                              _customTextColor = val;
                              _customTextController.text = val;
                            });
                            widget.onCustomColorChanged(_customBackgroundColor, _customTextColor);
                            widget.ttsService.updateSettings(customTextColor: val);
                          }),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _customTextColor = val;
                        });
                        widget.onCustomColorChanged(_customBackgroundColor, _customTextColor);
                        widget.ttsService.updateSettings(customTextColor: val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Enter hex color like #1A1A1A or FFFFFF and press Enter', style: TextStyle(fontSize: 10, color: labelColor)),
            ],
            
            const SizedBox(height: 24),
            
            // ⚙️ NHÓM 3: HỖ TRỢ ĐỌC TRUYỆN (ASSISTIVE BUTTON)
            Row(
              children: [
                Icon(Icons.accessibility_new_rounded, size: 16, color: accentColor),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.assistiveButtonTitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Switch Bật/Tắt Nút Trợ Năng
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.showAssistiveButtonLabel, style: TextStyle(fontWeight: FontWeight.bold, color: labelColor)),
                Switch(
                  value: _showAssistiveButton,
                  activeColor: accentColor,
                  onChanged: (val) {
                    setState(() {
                      _showAssistiveButton = val;
                    });
                    widget.ttsService.updateSettings(showAssistiveButton: val);
                  },
                ),
              ],
            ),
            
            if (_showAssistiveButton) ...[
              const SizedBox(height: 16),
              // Dropdown gán Single Tap
              _buildGestureDropdown(
                label: AppLocalizations.of(context)!.singleTapLabel,
                value: _assistiveSingleTapAction,
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _assistiveSingleTapAction = val;
                    });
                    widget.ttsService.updateSettings(assistiveSingleTapAction: val);
                  }
                },
                labelColor: labelColor,
                sheetBg: sheetBg,
              ),
              const SizedBox(height: 16),
              // Dropdown gán Double Tap
              _buildGestureDropdown(
                label: AppLocalizations.of(context)!.doubleTapLabel,
                value: _assistiveDoubleTapAction,
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _assistiveDoubleTapAction = val;
                    });
                    widget.ttsService.updateSettings(assistiveDoubleTapAction: val);
                  }
                },
                labelColor: labelColor,
                sheetBg: sheetBg,
              ),
              const SizedBox(height: 16),
              // Dropdown gán Long Press
              _buildGestureDropdown(
                label: AppLocalizations.of(context)!.longPressLabel,
                value: _assistiveLongPressAction,
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _assistiveLongPressAction = val;
                    });
                    widget.ttsService.updateSettings(assistiveLongPressAction: val);
                  }
                },
                labelColor: labelColor,
                sheetBg: sheetBg,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    widget.ttsService.updateSettings(
                      assistiveButtonX: -1.0,
                      assistiveButtonY: -1.0,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.resetButtonPositionSuccess),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.restore_rounded, size: 16),
                  label: Text(AppLocalizations.of(context)!.resetButtonPosition, style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildGestureDropdown({
  required String label,
  required String value,
  required ValueChanged<String?> onChanged,
  required Color labelColor,
  required Color sheetBg,
}) {
  final l10n = AppLocalizations.of(context)!;
  final actionsMap = {
    'none': l10n.actionNone,
    'nextParagraph': l10n.actionNextParagraph,
    'prevParagraph': l10n.actionPrevParagraph,
    'playPause': l10n.actionPlayPause,
    'nextChapter': l10n.actionNextChapter,
    'prevChapter': l10n.actionPrevChapter,
    'openTtsSettings': l10n.actionOpenTtsSettings,
    'openBgmSettings': l10n.actionOpenBgmSettings,
  };

  // Đảm bảo value hợp lệ
  final String safeValue = actionsMap.containsKey(value) ? value : 'none';

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 13, color: labelColor.withValues(alpha: 0.8))),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        value: safeValue,
        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black12,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        dropdownColor: sheetBg,
        items: actionsMap.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Text(entry.value, style: TextStyle(color: labelColor, fontSize: 13)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    ],
  );
}

  void _showColorPicker(String currentColorHex, ValueChanged<String> onColorSelected) {
    Color currentColor = Colors.white;
    if (currentColorHex.isNotEmpty) {
      String hex = currentColorHex.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      try {
        currentColor = Color(int.parse(hex, radix: 16));
      } catch (_) {}
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        Color tempColor = currentColor;
        return AlertDialog(
          title: const Text('Pick a Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: (color) {
                tempColor = color;
              },
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hsvWithHue,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                String hexString = tempColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
                onColorSelected('#$hexString');
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
