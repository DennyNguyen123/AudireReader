import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';

class FontPickerSheet extends StatefulWidget {
  final String currentFontFamily;
  final String currentFontWeight;
  final ValueChanged<String> onFontFamilyChanged;
  final ValueChanged<String> onFontWeightChanged;

  const FontPickerSheet({
    super.key,
    required this.currentFontFamily,
    required this.currentFontWeight,
    required this.onFontFamilyChanged,
    required this.onFontWeightChanged,
  });

  static Future<void> show({
    required BuildContext context,
    required String currentFontFamily,
    required String currentFontWeight,
    required ValueChanged<String> onFontFamilyChanged,
    required ValueChanged<String> onFontWeightChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FontPickerSheet(
        currentFontFamily: currentFontFamily,
        currentFontWeight: currentFontWeight,
        onFontFamilyChanged: onFontFamilyChanged,
        onFontWeightChanged: onFontWeightChanged,
      ),
    );
  }

  @override
  State<FontPickerSheet> createState() => _FontPickerSheetState();
}

class _FontPickerSheetState extends State<FontPickerSheet> {
  late String _selectedFont;
  late String _selectedWeight;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'featured'; // 'featured', 'all', 'serif', 'sans', 'mono', 'handwriting'

  static const List<String> _systemFonts = [
    'System',
    'Serif',
    'Sans-Serif',
    'Monospace',
  ];

  static const List<String> _featuredVietnameseFonts = [
    'Be Vietnam Pro',
    'Literata',
    'Lora',
    'Merriweather',
    'Plus Jakarta Sans',
    'Lexend',
    'EB Garamond',
    'Inter',
    'Nunito',
    'Roboto',
    'Open Sans',
    'Source Serif 4',
    'Noto Serif',
    'Playfair Display',
    'Bitter',
    'Montserrat',
    'Mulish',
    'Poppins',
    'Work Sans',
    'Quicksand',
    'Faustina',
    'Vollkorn',
    'Spectral',
    'Alegreya',
    'JetBrains Mono',
    'Fira Code',
    'Patrick Hand',
    'Caveat',
    'Dancing Script',
  ];

  static const List<String> _serifFonts = [
    'Literata',
    'Lora',
    'Merriweather',
    'EB Garamond',
    'Source Serif 4',
    'Noto Serif',
    'Playfair Display',
    'PT Serif',
    'Bitter',
    'Faustina',
    'Vollkorn',
    'Spectral',
    'Alegreya',
    'Libre Baskerville',
    'Cinzel',
    'Newsreader',
  ];

  static const List<String> _sansFonts = [
    'Be Vietnam Pro',
    'Plus Jakarta Sans',
    'Lexend',
    'Inter',
    'Nunito',
    'Roboto',
    'Open Sans',
    'Montserrat',
    'Mulish',
    'Poppins',
    'Work Sans',
    'Manrope',
    'Quicksand',
    'Source Sans 3',
    'Cabin',
    'Lato',
    'Raleway',
    'Comfortaa',
  ];

  static const List<String> _monoFonts = [
    'JetBrains Mono',
    'Fira Code',
    'Inconsolata',
    'Source Code Pro',
    'Roboto Mono',
    'Space Mono',
  ];

  static const List<String> _handwritingFonts = [
    'Patrick Hand',
    'Caveat',
    'Dancing Script',
    'Mali',
    'Pacifico',
  ];

  late final List<String> _allGoogleFonts;

  @override
  void initState() {
    super.initState();
    _selectedFont = widget.currentFontFamily;
    _selectedWeight = widget.currentFontWeight;
    
    // Lấy toàn bộ 1.500+ font từ GoogleFonts
    final allKeys = GoogleFonts.asMap().keys.toList();
    allKeys.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _allGoogleFonts = allKeys;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  FontWeight _getFontWeight(String weight) {
    switch (weight) {
      case 'w300':
      case 'light':
        return FontWeight.w300;
      case 'w500':
      case 'medium':
        return FontWeight.w500;
      case 'w600':
      case 'semiBold':
        return FontWeight.w600;
      case 'w700':
      case 'bold':
        return FontWeight.w700;
      case 'w800':
      case 'extraBold':
        return FontWeight.w800;
      case 'w400':
      case 'normal':
      default:
        return FontWeight.w400;
    }
  }

  TextStyle _getPreviewStyle(String fontName) {
    final weight = _getFontWeight(_selectedWeight);
    if (fontName == 'System' || fontName.isEmpty) {
      return TextStyle(fontWeight: weight);
    }
    if (fontName == 'Serif' || fontName == 'Sans-Serif' || fontName == 'Monospace') {
      return TextStyle(fontFamily: fontName.toLowerCase(), fontWeight: weight);
    }
    try {
      return GoogleFonts.getFont(fontName, fontWeight: weight);
    } catch (_) {
      return TextStyle(fontFamily: fontName, fontWeight: weight);
    }
  }

  List<String> _getFilteredFonts() {
    List<String> baseList;
    switch (_selectedCategory) {
      case 'featured':
        baseList = [..._systemFonts, ..._featuredVietnameseFonts];
        break;
      case 'serif':
        baseList = ['Serif', ..._serifFonts];
        break;
      case 'sans':
        baseList = ['Sans-Serif', ..._sansFonts];
        break;
      case 'mono':
        baseList = ['Monospace', ..._monoFonts];
        break;
      case 'handwriting':
        baseList = _handwritingFonts;
        break;
      case 'all':
      default:
        baseList = [..._systemFonts, ..._allGoogleFonts];
        break;
    }

    if (_searchQuery.trim().isEmpty) {
      return baseList;
    }

    final query = _searchQuery.trim().toLowerCase();
    // Khi đang tìm kiếm, tìm trên toàn bộ Google Fonts + System Fonts
    final searchPool = [..._systemFonts, ..._allGoogleFonts];
    final Set<String> matched = {};
    for (final f in searchPool) {
      if (f.toLowerCase().contains(query)) {
        matched.add(f);
      }
    }
    return matched.toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final primaryColor = theme.colorScheme.primary;
    final filteredFonts = _getFilteredFonts();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header kéo thanh
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Title & Close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.font_download_rounded, color: primaryColor, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(context)?.fontStyle ?? 'Phông chữ & Kiểu chữ',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Bộ chọn Font Weight (Độ đậm nhạt)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Độ đậm chữ (Font Weight)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    Text(
                      _getWeightLabel(_selectedWeight),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'light', label: Text('300')),
                      ButtonSegment(value: 'normal', label: Text('400')),
                      ButtonSegment(value: 'medium', label: Text('500')),
                      ButtonSegment(value: 'semiBold', label: Text('600')),
                      ButtonSegment(value: 'bold', label: Text('700')),
                    ],
                    selected: {_selectedWeight},
                    onSelectionChanged: (newSet) {
                      final val = newSet.first;
                      setState(() {
                        _selectedWeight = val;
                      });
                      widget.onFontWeightChanged(val);
                    },
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Ô Tìm kiếm (Search Bar)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm trong 1.500+ Google Fonts...',
                hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Thanh cuộn Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildCategoryChip('featured', '⭐ Nổi bật & Tiếng Việt'),
                _buildCategoryChip('all', 'Tất cả (1.500+)'),
                _buildCategoryChip('serif', 'Có chân (Serif)'),
                _buildCategoryChip('sans', 'Không chân (Sans)'),
                _buildCategoryChip('mono', 'Đều nét (Mono)'),
                _buildCategoryChip('handwriting', 'Viết tay'),
              ],
            ),
          ),

          const Divider(height: 16),

          // Danh sách Font kèm Live Preview
          Expanded(
            child: filteredFonts.isEmpty
                ? Center(
                    child: Text(
                      'Không tìm thấy font "$_searchQuery"',
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    itemCount: filteredFonts.length,
                    itemBuilder: (context, index) {
                      final fontName = filteredFonts[index];
                      final isSelected = _selectedFont.toLowerCase() == fontName.toLowerCase();

                      return _buildFontCard(
                        fontName: fontName,
                        isSelected: isSelected,
                        isDark: isDark,
                        primaryColor: primaryColor,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _getWeightLabel(String weight) {
    switch (weight) {
      case 'light':
      case 'w300':
        return 'Light (300)';
      case 'medium':
      case 'w500':
        return 'Medium (500)';
      case 'semiBold':
      case 'w600':
        return 'Semi-Bold (600)';
      case 'bold':
      case 'w700':
        return 'Bold (700)';
      case 'normal':
      case 'w400':
      default:
        return 'Regular (400)';
    }
  }

  Widget _buildCategoryChip(String categoryId, String label) {
    final isSelected = _selectedCategory == categoryId && _searchQuery.isEmpty;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : null,
          ),
        ),
        selected: isSelected,
        selectedColor: primaryColor,
        checkmarkColor: Colors.white,
        showCheckmark: false,
        onSelected: (_) {
          setState(() {
            _selectedCategory = categoryId;
            _searchController.clear();
            _searchQuery = '';
          });
        },
      ),
    );
  }

  Widget _buildFontCard({
    required String fontName,
    required bool isSelected,
    required bool isDark,
    required Color primaryColor,
  }) {
    final previewStyle = _getPreviewStyle(fontName);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? primaryColor.withValues(alpha: isDark ? 0.18 : 0.1)
            : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? primaryColor : (isDark ? Colors.white10 : Colors.black12),
          width: isSelected ? 1.8 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            _selectedFont = fontName;
          });
          widget.onFontFamilyChanged(fontName);
          widget.onFontWeightChanged(_selectedWeight);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Thông tin font & Demo text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          fontName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? primaryColor : null,
                          ),
                        ),
                        if (_featuredVietnameseFonts.contains(fontName)) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'UTF-8 VN',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Hương thơm trang sách mở ra chân trời mới 0123456789',
                      style: previewStyle.copyWith(
                        fontSize: 15,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Checkbox indicator
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                )
              else
                Icon(
                  Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
