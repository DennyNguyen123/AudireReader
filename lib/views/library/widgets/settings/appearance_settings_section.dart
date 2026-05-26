import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'settings_card.dart';

class AppearanceSettingsSection extends StatelessWidget {
  final String themeMode;
  final String? primaryColorHex;
  final double fontSize;
  final String fontFamily;
  final ValueChanged<String> onThemeModeChanged;
  final ValueChanged<String?> onPrimaryColorChanged;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<String?> onFontFamilyChanged;

  const AppearanceSettingsSection({
    super.key,
    required this.themeMode,
    this.primaryColorHex,
    required this.fontSize,
    required this.fontFamily,
    required this.onThemeModeChanged,
    required this.onPrimaryColorChanged,
    required this.onFontSizeChanged,
    required this.onFontFamilyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = theme.colorScheme.primary;

    return SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.chrome_reader_mode_rounded, color: accentColor, size: 28),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)?.readingAppearance ?? 'Reading Appearance & Typography',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // CHỦ ĐỀ ĐỌC
          Text(
            AppLocalizations.of(context)?.readingTheme ?? 'Reading Theme',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['System', 'Light', 'Dark', 'Sepia'].map((tMode) {
              final isSelected = themeMode == tMode;
              Color btnBg;
              Color textCol;
              IconData icon;
              String displayTheme = tMode;

              if (tMode == 'System') {
                btnBg = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0);
                textCol = isDark ? Colors.white70 : Colors.black87;
                icon = Icons.brightness_auto_rounded;
                displayTheme = AppLocalizations.of(context)?.system ?? 'System';
              } else if (tMode == 'Light') {
                btnBg = Colors.white;
                textCol = Colors.black87;
                icon = Icons.wb_sunny_rounded;
                displayTheme = AppLocalizations.of(context)?.light ?? 'Light';
              } else if (tMode == 'Dark') {
                btnBg = const Color(0xFF121212);
                textCol = Colors.white70;
                icon = Icons.nightlight_round;
                displayTheme = AppLocalizations.of(context)?.dark ?? 'Dark';
              } else { // Sepia
                btnBg = const Color(0xFFF4ECD8);
                textCol = const Color(0xFF5B4636);
                icon = Icons.menu_book_rounded;
                displayTheme = AppLocalizations.of(context)?.sepia ?? 'Sepia';
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () => onThemeModeChanged(tMode),
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
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          color: isSelected ? accentColor : textCol.withValues(alpha: 0.8),
                          size: 18,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayTheme,
                          style: TextStyle(
                            fontSize: 11,
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
          // MÀU CHỦ ĐẠO (PRIMARY COLOR)
          const SizedBox(height: 20),
          const Text(
            'Primary Color',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildColorOption(context, null, Colors.amber, 'Amber'),
                _buildColorOption(context, '2196F3', Colors.blue, 'Blue'),
                _buildColorOption(context, '4CAF50', Colors.green, 'Green'),
                _buildColorOption(context, '9C27B0', Colors.purple, 'Purple'),
                _buildColorOption(context, 'F44336', Colors.red, 'Red'),
                _buildColorOption(context, 'E91E63', Colors.pink, 'Pink'),
                _buildColorOption(context, '009688', Colors.teal, 'Teal'),
                if (primaryColorHex != null && !['2196F3', '4CAF50', '9C27B0', 'F44336', 'E91E63', '009688'].contains(primaryColorHex?.toUpperCase()))
                  Builder(
                    builder: (context) {
                      Color? customColor;
                      try {
                        customColor = Color(int.parse('FF$primaryColorHex', radix: 16));
                      } catch (_) {}
                      if (customColor != null) {
                        return _buildColorOption(context, primaryColorHex, customColor, 'Custom');
                      }
                      return const SizedBox();
                    }
                  ),
                _buildColorPickerButton(context),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // CỠ CHỮ SLIDER
          Row(
            children: [
              const Icon(Icons.format_size_rounded, size: 20),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)?.fontSize ?? 'Font Size',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Expanded(
                child: Slider(
                  value: fontSize,
                  min: 14.0,
                  max: 28.0,
                  divisions: 7,
                  activeColor: accentColor,
                  label: fontSize.round().toString(),
                  onChanged: onFontSizeChanged,
                ),
              ),
              Text(
                '${fontSize.round()}px',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // CHỌN PHÔNG CHỮ DROPDOWN
          Text(
            AppLocalizations.of(context)?.fontStyle ?? 'Font Style',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: [
              'System', 'Serif', 'Sans-Serif', 'Monospace', 
              'Lora', 'Merriweather', 'Inter', 'Nunito',
              'Roboto', 'Open Sans', 'Playfair Display', 'PT Serif', 'Quicksand'
            ].contains(fontFamily) ? fontFamily : 'System',
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? Colors.white10 : Colors.black12,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                        : font, // google_fonts requires exact family name in pubspec or dynamically loaded
                  ),
                ),
              );
            }).toList(),
            onChanged: onFontFamilyChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildColorOption(BuildContext context, String? hexVal, Color displayColor, String label) {
    final isSelected = primaryColorHex == hexVal || (primaryColorHex?.isEmpty == true && hexVal == null);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onPrimaryColorChanged(hexVal),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: displayColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? (isDark ? Colors.white : Colors.black87) : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: displayColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                      size: 20,
                    )
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPickerButton(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        Color currentColor = Colors.amber;
        if (primaryColorHex != null) {
          try {
            currentColor = Color(int.parse('FF$primaryColorHex', radix: 16));
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
                    onPrimaryColorChanged(hexString);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black12,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.transparent,
                  width: 3,
                ),
              ),
              child: Icon(Icons.palette_rounded, color: isDark ? Colors.white70 : Colors.black87, size: 20),
            ),
            const SizedBox(height: 6),
            const Text(
              'Custom',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
