import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/tts_service.dart';
import '../../../core/theme_notifier.dart';
import '../../library/pronunciation_dictionary_screen.dart';
import '../../../services/supertonic_service.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ReaderSettingsSheet extends StatefulWidget {
  final TtsService ttsService;
  final String themeMode;
  final double fontSize;
  final String fontFamily;
  final double speechRate;
  final String ttsProvider;
  final List<dynamic> initialVoices;
  final Map<String, String>? initialSelectedVoice;

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
  final ValueChanged<double> onSpeechRateChanged;
  final Function(String provider, List<dynamic> voices, Map<String, String>? selectedVoice) onTtsProviderChanged;
  final ValueChanged<Map<String, String>?> onVoiceChanged;

  const ReaderSettingsSheet({
    super.key,
    required this.ttsService,
    required this.themeMode,
    required this.fontSize,
    required this.fontFamily,
    required this.speechRate,
    required this.ttsProvider,
    required this.initialVoices,
    this.initialSelectedVoice,
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
    required this.onSpeechRateChanged,
    required this.onTtsProviderChanged,
    required this.onVoiceChanged,
  });

  @override
  State<ReaderSettingsSheet> createState() => _ReaderSettingsSheetState();
}

class _ReaderSettingsSheetState extends State<ReaderSettingsSheet> {
  late String _themeMode;
  late double _fontSize;
  late String _fontFamily;
  late double _speechRate;
  late String _ttsProvider;
  late List<dynamic> _voices;
  Map<String, String>? _selectedVoice;

  late double _lineHeight;
  late double _paragraphSpacing;
  late String _textAlignment;
  late double _sideMargin;
  String? _customBackgroundColor;
  String? _customTextColor;

  final _speedController = TextEditingController();
  final _voiceSearchController = TextEditingController();
  late final TextEditingController _customBgController;
  late final TextEditingController _customTextController;
  String _selectedLanguageFilter = 'all';
  String _voiceSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _themeMode = widget.themeMode;
    _fontSize = widget.fontSize;
    _fontFamily = widget.fontFamily;
    _speechRate = widget.speechRate;
    _ttsProvider = widget.ttsProvider;
    _voices = List.from(widget.initialVoices);
    _selectedVoice = widget.initialSelectedVoice;

    _lineHeight = widget.lineHeight;
    _paragraphSpacing = widget.paragraphSpacing;
    _textAlignment = widget.textAlignment;
    _sideMargin = widget.sideMargin;
    _customBackgroundColor = widget.customBackgroundColor;
    _customTextColor = widget.customTextColor;

    _customBgController = TextEditingController(text: _customBackgroundColor);
    _customTextController = TextEditingController(text: _customTextColor);
    _speedController.text = (_speechRate * 2).toStringAsFixed(3);
  }

  @override
  void dispose() {
    _speedController.dispose();
    _voiceSearchController.dispose();
    _customBgController.dispose();
    _customTextController.dispose();
    super.dispose();
  }

  bool _getIsDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Future<void> _loadVoices(String provider) async {
    try {
      final list = await widget.ttsService.getVoicesForProvider(provider);
      final settings = await widget.ttsService.getSettings();

      Map<String, String>? initialVoice;
      if (settings.selectedVoiceName != null && settings.selectedVoiceLocale != null) {
        dynamic matched;
        for (final v in list) {
          if (v['name']?.toString() == settings.selectedVoiceName &&
              v['locale']?.toString() == settings.selectedVoiceLocale) {
            matched = v;
            break;
          }
        }
        if (matched != null) {
          initialVoice = Map<String, String>.from(
            (matched as Map).map((k, val) => MapEntry(k.toString(), val.toString())),
          );
        }
      } else if (provider == 'microsoft_edge' && list.isNotEmpty) {
        dynamic matched;
        for (final v in list) {
          if (v['name']?.toString() == 'vi-VN-HoaiMyNeural') {
            matched = v;
            break;
          }
        }
        matched ??= list.first;
        initialVoice = Map<String, String>.from(
          (matched as Map).map((k, val) => MapEntry(k.toString(), val.toString())),
        );
        widget.ttsService.updateSettings(voice: initialVoice);
      }

      setState(() {
        _voices = list;
        _selectedVoice = initialVoice;
      });
      
      widget.onTtsProviderChanged(provider, list, initialVoice);
    } catch (e) {
      debugPrint("Failed to load voices in settings sheet: $e");
    }
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
            const SizedBox(height: 20),
            Divider(color: isDark ? Colors.white10 : Colors.black12, thickness: 1),
            const SizedBox(height: 20),

            // 🗣️ NHÓM 2: TEXT-TO-SPEECH (TTS)
            Row(
              children: [
                Icon(Icons.volume_up_rounded, size: 16, color: accentColor),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.textToSpeechTts,
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
            
            // SLEEP TIMER
            Text(
              widget.ttsService.isSleepTimerActive 
                  ? AppLocalizations.of(context)!.sleepTimerRemaining('${(widget.ttsService.sleepTimerDuration! ~/ 60).toString().padLeft(2, '0')}:${(widget.ttsService.sleepTimerDuration! % 60).toString().padLeft(2, '0')}')
                  : widget.ttsService.stopAtEndOfChapter 
                      ? AppLocalizations.of(context)!.sleepTimerStopAtEnd
                      : AppLocalizations.of(context)!.sleepTimer,
              style: TextStyle(fontWeight: FontWeight.bold, color: labelColor),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text(AppLocalizations.of(context)!.off, style: const TextStyle(fontSize: 12)),
                    selected: !widget.ttsService.isSleepTimerActive && !widget.ttsService.stopAtEndOfChapter,
                    selectedColor: accentColor,
                    labelStyle: TextStyle(
                      color: (!widget.ttsService.isSleepTimerActive && !widget.ttsService.stopAtEndOfChapter) ? Colors.white : labelColor
                    ),
                    onSelected: (val) {
                      if (val) {
                        widget.ttsService.cancelSleepTimer();
                        widget.ttsService.enableStopAtEndOfChapter(false);
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('15m', style: TextStyle(fontSize: 12)),
                    selected: widget.ttsService.isSleepTimerActive && widget.ttsService.sleepTimerDuration! ~/ 60 == 15,
                    selectedColor: accentColor,
                    labelStyle: TextStyle(
                      color: (widget.ttsService.isSleepTimerActive && widget.ttsService.sleepTimerDuration! ~/ 60 == 15) ? Colors.white : labelColor
                    ),
                    onSelected: (val) {
                      if (val) {
                        widget.ttsService.startSleepTimer(15);
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('30m', style: TextStyle(fontSize: 12)),
                    selected: widget.ttsService.isSleepTimerActive && widget.ttsService.sleepTimerDuration! ~/ 60 == 30,
                    selectedColor: accentColor,
                    labelStyle: TextStyle(
                      color: (widget.ttsService.isSleepTimerActive && widget.ttsService.sleepTimerDuration! ~/ 60 == 30) ? Colors.white : labelColor
                    ),
                    onSelected: (val) {
                      if (val) {
                        widget.ttsService.startSleepTimer(30);
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('45m', style: TextStyle(fontSize: 12)),
                    selected: widget.ttsService.isSleepTimerActive && widget.ttsService.sleepTimerDuration! ~/ 60 == 45,
                    selectedColor: accentColor,
                    labelStyle: TextStyle(
                      color: (widget.ttsService.isSleepTimerActive && widget.ttsService.sleepTimerDuration! ~/ 60 == 45) ? Colors.white : labelColor
                    ),
                    onSelected: (val) {
                      if (val) {
                        widget.ttsService.startSleepTimer(45);
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(AppLocalizations.of(context)!.endChapter, style: const TextStyle(fontSize: 12)),
                    selected: widget.ttsService.stopAtEndOfChapter,
                    selectedColor: accentColor,
                    labelStyle: TextStyle(
                      color: widget.ttsService.stopAtEndOfChapter ? Colors.white : labelColor
                    ),
                    onSelected: (val) {
                      if (val) {
                        widget.ttsService.enableStopAtEndOfChapter(true);
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

             // TỐC ĐỘ NÓI
             Row(
               children: [
                 const Icon(Icons.speed_rounded),
                 const SizedBox(width: 12),
                 Text(AppLocalizations.of(context)!.readingSpeed, style: TextStyle(color: labelColor)),
                 Expanded(
                   child: Slider(
                     value: _speechRate,
                     min: 0.05,
                     max: 1.0,
                     activeColor: accentColor,
                     onChanged: (val) {
                       setState(() {
                         _speechRate = val;
                         _speedController.text = (val * 2).toStringAsFixed(3);
                       });
                       widget.onSpeechRateChanged(val);
                       widget.ttsService.updateSettings(speechRate: val);
                     },
                   ),
                 ),
                 SizedBox(
                   width: 85,
                   height: 38,
                   child: TextField(
                     controller: _speedController,
                     keyboardType: const TextInputType.numberWithOptions(decimal: true),
                     textAlign: TextAlign.center,
                     style: TextStyle(
                       fontSize: 12, 
                       fontWeight: FontWeight.bold,
                       color: labelColor,
                     ),
                     decoration: InputDecoration(
                       contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                       suffixText: 'x',
                       suffixStyle: TextStyle(
                         fontSize: 11, 
                         fontWeight: FontWeight.bold, 
                         color: accentColor
                       ),
                       filled: true,
                       fillColor: isDark ? Colors.white10 : Colors.black12,
                       border: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(10),
                         borderSide: BorderSide.none,
                       ),
                     ),
                     onChanged: (text) {
                       final double? val = double.tryParse(text);
                       if (val != null) {
                         final clampedMultiplier = val.clamp(0.1, 2.0);
                         final newRate = clampedMultiplier / 2.0;
                         setState(() {
                           _speechRate = newRate;
                         });
                         widget.onSpeechRateChanged(newRate);
                         widget.ttsService.updateSettings(speechRate: newRate);
                       }
                     },
                   ),
                 ),
               ],
             ),
            const SizedBox(height: 16),

            // CHỌN ĐỘNG CƠ TTS (TTS Provider Dropdown)
            Text(AppLocalizations.of(context)!.ttsProvider, style: TextStyle(fontWeight: FontWeight.bold, color: labelColor)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _ttsProvider,
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
                DropdownMenuItem<String>(
                  value: 'system',
                  child: Text(AppLocalizations.of(context)!.systemTtsOffline, style: const TextStyle(fontSize: 13)),
                ),
                DropdownMenuItem<String>(
                  value: 'microsoft_edge',
                  child: Text(AppLocalizations.of(context)!.edgeTtsOnline, style: const TextStyle(fontSize: 13)),
                ),
                const DropdownMenuItem<String>(
                  value: 'supertonic',
                  child: Text('Supertonic Offline AI', style: TextStyle(fontSize: 13)),
                ),
              ],
              onChanged: (val) async {
                if (val != null) {
                  setState(() {
                    _ttsProvider = val;
                    _voices = [];
                    _selectedVoice = null;
                  });

                  await widget.ttsService.updateSettings(ttsProvider: val);
                  await _loadVoices(val);
                  
                  if (val == 'supertonic') {
                    setState(() {
                      _selectedVoice = {
                        'name': 'M1',
                        'locale': 'offline',
                        'gender': 'Male',
                      };
                    });
                    widget.onVoiceChanged(_selectedVoice);
                  }
                }
              },
            ),
            if (_ttsProvider == 'supertonic') ...[
              const SizedBox(height: 16),
              ListenableBuilder(
                listenable: SupertonicService.getInstance(),
                builder: (context, _) {
                  final supertonic = SupertonicService.getInstance();
                  return FutureBuilder<bool>(
                    future: supertonic.checkModelExists(),
                    builder: (context, snapshot) {
                      final modelExists = snapshot.data ?? false;
                      
                      if (supertonic.isDownloading) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                supertonic.downloadStatus,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: labelColor),
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: supertonic.downloadProgress,
                                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                              ),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${(supertonic.downloadProgress * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: labelColor),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (!modelExists) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black12,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Offline AI Model Required',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: labelColor),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'To use Supertonic Offline AI voices, you need to download the voice model files (~96MB) to your device.',
                                style: TextStyle(fontSize: 12, color: labelColor.withValues(alpha: 0.7)),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () {
                                  supertonic.downloadModelFiles().then((success) {
                                    if (success) {
                                      supertonic.initializeEngine();
                                    }
                                  });
                                },
                                icon: const Icon(Icons.download_rounded, size: 18),
                                label: const Text('Download Voice Model (96MB)'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Offline Voice Model Ready',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                  Text(
                                    'Supertonic Offline AI is fully operational.',
                                    style: TextStyle(fontSize: 11, color: labelColor.withValues(alpha: 0.7)),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                              tooltip: 'Delete Model File',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: sheetBg,
                                    title: Text('Delete Model Files?', style: TextStyle(color: labelColor)),
                                    content: Text('Are you sure you want to delete the offline AI model files to free up space? You will need to redownload them to use this feature again.', style: TextStyle(color: labelColor.withValues(alpha: 0.8))),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          supertonic.deleteModelFiles();
                                        },
                                        child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Đóng Bottom Sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PronunciationDictionaryScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.record_voice_over_rounded),
              label: Text(AppLocalizations.of(context)!.managePronunciation),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 20),

            // CHỌN GIỌNG ĐỌC & BỘ LỌC NGÔN NGỮ
            if (_voices.isNotEmpty) ...[
              // BỘ LỌC NGÔN NGỮ
              Text(AppLocalizations.of(context)!.languageFilter, style: TextStyle(fontWeight: FontWeight.bold, color: labelColor)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedLanguageFilter,
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
                  DropdownMenuItem<String>(
                    value: 'all',
                    child: Text(AppLocalizations.of(context)!.allLanguages, style: const TextStyle(fontSize: 13)),
                  ),
                  DropdownMenuItem<String>(
                    value: 'vi',
                    child: Text(AppLocalizations.of(context)!.vietnamese, style: const TextStyle(fontSize: 13)),
                  ),
                  DropdownMenuItem<String>(
                    value: 'en',
                    child: Text(AppLocalizations.of(context)!.english, style: const TextStyle(fontSize: 13)),
                  ),
                  DropdownMenuItem<String>(
                    value: 'others',
                    child: Text(AppLocalizations.of(context)!.otherLanguages, style: const TextStyle(fontSize: 13)),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedLanguageFilter = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Ô TÌM KIẾM GIỌNG ĐỌC (Bằng tiếng Anh)
              Text(AppLocalizations.of(context)!.searchVoice, style: TextStyle(fontWeight: FontWeight.bold, color: labelColor)),
              const SizedBox(height: 8),
              TextField(
                controller: _voiceSearchController,
                style: TextStyle(color: labelColor, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.black12,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  hintText: AppLocalizations.of(context)!.searchVoiceHint,
                  hintStyle: TextStyle(color: labelColor.withValues(alpha: 0.5), fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: labelColor.withValues(alpha: 0.6)),
                  suffixIcon: _voiceSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: labelColor.withValues(alpha: 0.6)),
                          onPressed: () {
                            _voiceSearchController.clear();
                            setState(() {
                              _voiceSearchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (val) {
                  setState(() {
                    _voiceSearchQuery = val.trim().toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 16),

              Text(AppLocalizations.of(context)!.selectVoice, style: TextStyle(fontWeight: FontWeight.bold, color: labelColor)),
              const SizedBox(height: 8),
              () {
                final filteredDisplayVoices = _voices.where((v) {
                  final lang = v['locale']?.toString().toLowerCase() ?? '';
                  final name = v['name']?.toString().toLowerCase() ?? '';

                  // 1. Lọc theo ngôn ngữ
                  bool matchesLang = true;
                  if (_selectedLanguageFilter == 'vi') {
                    matchesLang = lang.startsWith('vi');
                  } else if (_selectedLanguageFilter == 'en') {
                    matchesLang = lang.startsWith('en');
                  } else if (_selectedLanguageFilter == 'others') {
                    matchesLang = !lang.startsWith('vi') && !lang.startsWith('en');
                  }

                  if (!matchesLang) return false;

                  // 2. Lọc theo ô tìm kiếm
                  if (_voiceSearchQuery.isNotEmpty) {
                    return name.contains(_voiceSearchQuery) || lang.contains(_voiceSearchQuery);
                  }

                  return true;
                }).toList();

                return DropdownButtonFormField<String>(
                  initialValue: filteredDisplayVoices.any((v) => v['name']?.toString() == _selectedVoice?['name'])
                      ? (_selectedVoice?['name'])
                      : null,
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
                  items: () {
                    final Set<String> seenNames = {};
                    final List<DropdownMenuItem<String>> menuItems = [];
                    for (final v in filteredDisplayVoices) {
                      final name = v['name']?.toString() ?? 'Unknown';
                      final locale = v['locale']?.toString() ?? '';
                      if (!seenNames.contains(name)) {
                        seenNames.add(name);
                        menuItems.add(DropdownMenuItem<String>(
                          value: name,
                          child: Text(
                            '$name ($locale)',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, color: labelColor),
                          ),
                        ));
                      }
                    }
                    return menuItems;
                  }(),
                  onChanged: (val) {
                    if (val != null) {
                      dynamic selectedMap;
                      for (final v in filteredDisplayVoices) {
                        if (v['name']?.toString() == val) {
                          selectedMap = v;
                          break;
                        }
                      }
                      if (selectedMap != null) {
                        final voiceMap = Map<String, String>.from(
                          (selectedMap as Map).map(
                            (key, value) => MapEntry(key.toString(), value.toString()),
                          ),
                        );
                        setState(() {
                          _selectedVoice = voiceMap;
                        });
                        widget.onVoiceChanged(voiceMap);
                        widget.ttsService.updateSettings(voice: voiceMap);
                      }
                    }
                  },
                );
              }(),
              
              const SizedBox(height: 20),
              Divider(color: isDark ? Colors.white10 : Colors.black12, thickness: 1),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    ),
    ),
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
