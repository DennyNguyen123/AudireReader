import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../../services/bgm_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/bgm_track.dart';
import '../../../services/bgm/radio_browser_provider.dart';
import '../../../services/bgm/open_lofi_provider.dart';

class BgmPlayerSheet extends StatefulWidget {
  const BgmPlayerSheet({super.key});

  @override
  State<BgmPlayerSheet> createState() => _BgmPlayerSheetState();
}

class _BgmPlayerSheetState extends State<BgmPlayerSheet> {
  bool _showAddBgmForm = false;
  final _bgmNameController = TextEditingController();
  final _bgmUrlController = TextEditingController();
  String? _bgmLocalPath;

  // Trạng thái tìm kiếm Radio
  final _searchController = TextEditingController();
  bool _isLoadingRadio = false;
  bool _isSearching = false;
  List<BgmTrack> _searchedRadioTracks = [];

  // Trạng thái thêm nhạc theo nguồn
  String _addSourceType = 'file'; // 'file', 'link', 'radio', 'lofi'
  bool _isLoadingLofi = false;
  List<BgmTrack> _lofiTracks = [];

  Future<void> _loadLofiTracks() async {
    if (_lofiTracks.isNotEmpty) return;
    setState(() {
      _isLoadingLofi = true;
    });
    try {
      final provider = OpenLofiProvider();
      final results = await provider.fetchTracks();
      setState(() {
        _lofiTracks = results;
        _isLoadingLofi = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingLofi = false;
      });
    }
  }

  Future<void> _performRadioSearch(String val) async {
    if (val.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchedRadioTracks = [];
      });
      return;
    }
    setState(() {
      _isLoadingRadio = true;
      _isSearching = true;
    });
    try {
      final provider = RadioBrowserProvider();
      final results = await provider.searchTracks(val);
      setState(() {
        _searchedRadioTracks = results;
        _isLoadingRadio = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingRadio = false;
      });
    }
  }

  Widget _buildSourceChip(String value, IconData icon, String label) {
    final theme = Theme.of(context);
    final isSelected = _addSourceType == value;
    final accentColor = theme.colorScheme.primary;
    final labelColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final isDark = theme.brightness == Brightness.dark;

    return ChoiceChip(
      showCheckmark: false,
      iconTheme: IconThemeData(
        color: isSelected
            ? (isDark ? Colors.black : Colors.white)
            : labelColor.withValues(alpha: 0.6),
        size: 16,
      ),
      avatar: Icon(icon),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isSelected
              ? (isDark ? Colors.black : Colors.white)
              : labelColor.withValues(alpha: 0.8),
        ),
      ),
      selected: isSelected,
      selectedColor: accentColor,
      backgroundColor: labelColor.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? accentColor : Colors.transparent),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _addSourceType = value;
            _bgmNameController.clear();
            _bgmUrlController.clear();
            _bgmLocalPath = null;
            if (value == 'lofi') {
              _loadLofiTracks();
            }
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _bgmNameController.dispose();
    _bgmUrlController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = theme.scaffoldBackgroundColor;
    final cardBg = theme.cardColor;
    final labelColor =
        theme.textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : Colors.black);
    final secondaryColor = labelColor.withValues(alpha: 0.6);
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
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.06),
                width: 1.5,
              ),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: secondaryColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Background Music",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: labelColor,
                      ),
                    ),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: secondaryColor.withValues(alpha: 0.1),
                        padding: const EdgeInsets.all(8),
                      ),
                      icon: Icon(
                        Icons.close_rounded,
                        color: secondaryColor,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                ListenableBuilder(
                  listenable: BgmService.getInstance(),
                  builder: (context, _) {
                    final bgmService = BgmService.getInstance();

                    final playlist =
                        (_isSearching &&
                            bgmService.bgmProviderId == 'radio_browser')
                        ? _searchedRadioTracks
                        : bgmService.bgmPlaylist;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // GENERAL SETTINGS CARD
                        Container(
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Enable BGM Row
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: accentColor.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.music_note_rounded,
                                            color: accentColor,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          "Enable Music",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: labelColor,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Switch.adaptive(
                                      value: bgmService.bgmEnabled,
                                      onChanged: (val) async {
                                        await bgmService.updateSettings(
                                          bgmEnabled: val,
                                        );
                                        if (val &&
                                            bgmService.currentTrack != null) {
                                          await bgmService.playTrack(
                                            bgmService.currentTrack!,
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              if (bgmService.bgmEnabled) ...[
                                Divider(
                                  height: 1,
                                  color: secondaryColor.withValues(alpha: 0.2),
                                  indent: 56,
                                ),

                                // Volume Row
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.volume_down_rounded,
                                        size: 24,
                                        color: secondaryColor,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: SliderTheme(
                                          data: SliderTheme.of(context).copyWith(
                                            trackHeight: 4,
                                            thumbShape:
                                                const RoundSliderThumbShape(
                                                  enabledThumbRadius: 6,
                                                ),
                                            overlayShape:
                                                const RoundSliderOverlayShape(
                                                  overlayRadius: 14,
                                                ),
                                          ),
                                          child: Slider(
                                            value: bgmService.bgmVolume,
                                            min: 0.0,
                                            max: 0.5,
                                            activeColor: accentColor,
                                            inactiveColor: secondaryColor
                                                .withValues(alpha: 0.2),
                                            onChanged: (val) {
                                              bgmService.updateVolumeInMemory(
                                                val,
                                              );
                                            },
                                            onChangeEnd: (val) {
                                              bgmService.updateSettings(
                                                bgmVolume: val,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          "${(bgmService.bgmVolume * 200).round()}%",
                                          textAlign: TextAlign.end,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: secondaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Divider(
                                  height: 1,
                                  color: secondaryColor.withValues(alpha: 0.2),
                                  indent: 56,
                                ),

                                // Loop Mode Row
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.repeat_rounded,
                                            size: 22,
                                            color: secondaryColor,
                                          ),
                                          const SizedBox(width: 16),
                                          Text(
                                            "Loop Mode",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: labelColor,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SegmentedButton<String>(
                                        showSelectedIcon: false,
                                        style: SegmentedButton.styleFrom(
                                          selectedBackgroundColor: accentColor
                                              .withValues(alpha: 0.15),
                                          selectedForegroundColor: accentColor,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        segments: const [
                                          ButtonSegment(
                                            value: 'none',
                                            label: Text(
                                              'Off',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          ButtonSegment(
                                            value: 'one',
                                            label: Text(
                                              'Track',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          ButtonSegment(
                                            value: 'all',
                                            label: Text(
                                              'All',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                        selected: {bgmService.bgmLoopMode},
                                        onSelectionChanged: (val) {
                                          bgmService.updateSettings(
                                            bgmLoopMode: val.first,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // PLAYLIST SECTION
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Playlist",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: labelColor,
                                fontSize: 18,
                              ),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: accentColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                backgroundColor: accentColor.withValues(
                                  alpha: 0.1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              icon: Icon(
                                _showAddBgmForm
                                    ? Icons.close_rounded
                                    : Icons.add_rounded,
                                size: 18,
                              ),
                              label: Text(
                                _showAddBgmForm
                                    ? (AppLocalizations.of(context)?.cancel ??
                                          "Cancel")
                                    : "Add Track",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _showAddBgmForm = !_showAddBgmForm;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Add Track Form (Animated)
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                          child: !_showAddBgmForm
                              ? const SizedBox.shrink()
                              : Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: accentColor.withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Bộ chọn nguồn nhạc (Chips)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: [
                                              _buildSourceChip(
                                                'file',
                                                Icons.folder_open_rounded,
                                                AppLocalizations.of(
                                                      context,
                                                    )?.bgmLocalFile ??
                                                    "File cục bộ",
                                              ),
                                              const SizedBox(width: 8),
                                              _buildSourceChip(
                                                'link',
                                                Icons.link_rounded,
                                                AppLocalizations.of(
                                                      context,
                                                    )?.bgmPasteLink ??
                                                    "Dán link",
                                              ),
                                              const SizedBox(width: 8),
                                              _buildSourceChip(
                                                'radio',
                                                Icons.radio_rounded,
                                                AppLocalizations.of(
                                                      context,
                                                    )?.bgmInternetRadio ??
                                                    "Internet Radio",
                                              ),
                                              const SizedBox(width: 8),
                                              _buildSourceChip(
                                                'lofi',
                                                Icons.coffee_rounded,
                                                AppLocalizations.of(
                                                      context,
                                                    )?.bgmLofiSuggestions ??
                                                    "Lofi gợi ý",
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      if (_addSourceType == 'file') ...[
                                        // Track Name Input
                                        TextField(
                                          controller: _bgmNameController,
                                          style: TextStyle(
                                            color: labelColor,
                                            fontSize: 14,
                                          ),
                                          decoration: InputDecoration(
                                            labelText:
                                                AppLocalizations.of(
                                                  context,
                                                )?.trackName ??
                                                "Tên nhạc nền/đài phát",
                                            labelStyle: TextStyle(
                                              color: secondaryColor,
                                              fontSize: 13,
                                            ),
                                            floatingLabelStyle: TextStyle(
                                              color: accentColor,
                                            ),
                                            filled: true,
                                            fillColor: secondaryColor
                                                .withValues(alpha: 0.05),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide(
                                                color: accentColor,
                                                width: 1,
                                              ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 14,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        // Local Audio Picker Button
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: secondaryColor
                                                .withValues(alpha: 0.1),
                                            foregroundColor: labelColor,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          icon: Icon(
                                            Icons.folder_open_rounded,
                                            size: 18,
                                            color: secondaryColor,
                                          ),
                                          label: Text(
                                            _bgmLocalPath != null
                                                ? p.basename(_bgmLocalPath!)
                                                : AppLocalizations.of(
                                                        context,
                                                      )?.selectLocalFile ??
                                                      "Select Audio File",
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          onPressed: () async {
                                            final result = await FilePicker
                                                .platform
                                                .pickFiles(
                                                  type: FileType.custom,
                                                  allowedExtensions: [
                                                    'mp3',
                                                    'm4a',
                                                    'wav',
                                                    'ogg',
                                                    'flac',
                                                  ],
                                                  allowMultiple: false,
                                                );
                                            if (result != null &&
                                                result.files.single.path !=
                                                    null) {
                                              setState(() {
                                                _bgmLocalPath =
                                                    result.files.single.path;
                                                if (_bgmNameController.text
                                                    .trim()
                                                    .isEmpty) {
                                                  _bgmNameController.text = p
                                                      .basenameWithoutExtension(
                                                        _bgmLocalPath!,
                                                      );
                                                }
                                              });
                                            }
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        // Import Button
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: accentColor,
                                            foregroundColor: Colors.white,
                                            elevation: 2,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: _bgmLocalPath == null
                                              ? null
                                              : () async {
                                                  try {
                                                    await bgmService
                                                        .addTrackFromLocal(
                                                          _bgmNameController
                                                              .text,
                                                          _bgmLocalPath!,
                                                        );
                                                    setState(() {
                                                      _showAddBgmForm = false;
                                                      _bgmNameController
                                                          .clear();
                                                      _bgmLocalPath = null;
                                                    });
                                                    if (!context.mounted)
                                                      return;
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          AppLocalizations.of(
                                                                context,
                                                              )?.addSuccess ??
                                                              "Track added successfully!",
                                                        ),
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                        backgroundColor:
                                                            Colors.green[700],
                                                      ),
                                                    );
                                                  } catch (e) {
                                                    if (!context.mounted)
                                                      return;
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          "Failed to add track: $e",
                                                        ),
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                        backgroundColor:
                                                            Colors.red[700],
                                                      ),
                                                    );
                                                  }
                                                },
                                          child: Text(
                                            AppLocalizations.of(
                                                  context,
                                                )?.importTrack ??
                                                "Import Track",
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ] else if (_addSourceType == 'link') ...[
                                        // Track Name Input
                                        TextField(
                                          controller: _bgmNameController,
                                          style: TextStyle(
                                            color: labelColor,
                                            fontSize: 14,
                                          ),
                                          decoration: InputDecoration(
                                            labelText:
                                                AppLocalizations.of(
                                                  context,
                                                )?.trackName ??
                                                "Tên nhạc nền/đài phát",
                                            labelStyle: TextStyle(
                                              color: secondaryColor,
                                              fontSize: 13,
                                            ),
                                            floatingLabelStyle: TextStyle(
                                              color: accentColor,
                                            ),
                                            filled: true,
                                            fillColor: secondaryColor
                                                .withValues(alpha: 0.05),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide(
                                                color: accentColor,
                                                width: 1,
                                              ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 14,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        // URL Input
                                        TextField(
                                          controller: _bgmUrlController,
                                          style: TextStyle(
                                            color: labelColor,
                                            fontSize: 14,
                                          ),
                                          decoration: InputDecoration(
                                            labelText:
                                                AppLocalizations.of(
                                                  context,
                                                )?.trackUrl ??
                                                "Đường dẫn Link (URL)",
                                            labelStyle: TextStyle(
                                              color: secondaryColor,
                                              fontSize: 13,
                                            ),
                                            floatingLabelStyle: TextStyle(
                                              color: accentColor,
                                            ),
                                            filled: true,
                                            fillColor: secondaryColor
                                                .withValues(alpha: 0.05),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide(
                                                color: accentColor,
                                                width: 1,
                                              ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 14,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        // Import Button
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: accentColor,
                                            foregroundColor: Colors.white,
                                            elevation: 2,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed:
                                              _bgmUrlController.text
                                                  .trim()
                                                  .isEmpty
                                              ? null
                                              : () async {
                                                  try {
                                                    final url =
                                                        _bgmUrlController.text
                                                            .trim();
                                                    if (!url.startsWith(
                                                          'http://',
                                                        ) &&
                                                        !url.startsWith(
                                                          'https://',
                                                        )) {
                                                      throw Exception(
                                                        "URL must start with http:// or https://",
                                                      );
                                                    }
                                                    await bgmService
                                                        .addTrackFromUrl(
                                                          _bgmNameController
                                                              .text,
                                                          url,
                                                          sourceType:
                                                              'direct_url',
                                                        );
                                                    setState(() {
                                                      _showAddBgmForm = false;
                                                      _bgmNameController
                                                          .clear();
                                                      _bgmUrlController.clear();
                                                    });
                                                    if (!context.mounted)
                                                      return;
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          AppLocalizations.of(
                                                                context,
                                                              )?.addSuccess ??
                                                              "Track added successfully!",
                                                        ),
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                        backgroundColor:
                                                            Colors.green[700],
                                                      ),
                                                    );
                                                  } catch (e) {
                                                    if (!context.mounted)
                                                      return;
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          "Failed to add track: $e",
                                                        ),
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                        backgroundColor:
                                                            Colors.red[700],
                                                      ),
                                                    );
                                                  }
                                                },
                                          child: Text(
                                            AppLocalizations.of(
                                                  context,
                                                )?.importTrack ??
                                                "Import Track",
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ] else if (_addSourceType == 'radio') ...[
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: _searchController,
                                                style: TextStyle(
                                                  color: labelColor,
                                                  fontSize: 14,
                                                ),
                                                decoration: InputDecoration(
                                                  hintText:
                                                      AppLocalizations.of(
                                                        context,
                                                      )?.searchStation ??
                                                      "Tìm kiếm đài phát...",
                                                  hintStyle: TextStyle(
                                                    color: secondaryColor,
                                                    fontSize: 13,
                                                  ),
                                                  prefixIcon: Icon(
                                                    Icons.search_rounded,
                                                    color: secondaryColor,
                                                    size: 20,
                                                  ),
                                                  suffixIcon:
                                                      _searchController
                                                          .text
                                                          .isNotEmpty
                                                      ? IconButton(
                                                          icon: Icon(
                                                            Icons.clear_rounded,
                                                            color:
                                                                secondaryColor,
                                                            size: 20,
                                                          ),
                                                          onPressed: () {
                                                            setState(() {
                                                              _searchController
                                                                  .clear();
                                                              _isSearching =
                                                                  false;
                                                              _searchedRadioTracks =
                                                                  [];
                                                            });
                                                          },
                                                        )
                                                      : null,
                                                  filled: true,
                                                  fillColor: secondaryColor
                                                      .withValues(alpha: 0.05),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color: accentColor,
                                                          width: 1,
                                                        ),
                                                      ),
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 12,
                                                      ),
                                                ),
                                                onSubmitted: (val) =>
                                                    _performRadioSearch(val),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: accentColor,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 14,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              onPressed: () =>
                                                  _performRadioSearch(
                                                    _searchController.text,
                                                  ),
                                              child: const Icon(
                                                Icons.search_rounded,
                                                size: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        if (_isLoadingRadio)
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 20,
                                            ),
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          )
                                        else if (_isSearching &&
                                            _searchedRadioTracks.isEmpty)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 20,
                                            ),
                                            child: Center(
                                              child: Text(
                                                AppLocalizations.of(
                                                      context,
                                                    )?.emptySearch ??
                                                    "No matching results found",
                                                style: TextStyle(
                                                  color: secondaryColor,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          )
                                        else if (_searchedRadioTracks
                                            .isNotEmpty)
                                          Container(
                                            constraints: const BoxConstraints(
                                              maxHeight: 180,
                                            ),
                                            child: ListView.separated(
                                              shrinkWrap: true,
                                              itemCount:
                                                  _searchedRadioTracks.length,
                                              separatorBuilder:
                                                  (context, index) => Divider(
                                                    height: 1,
                                                    color: secondaryColor
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                  ),
                                              itemBuilder: (context, index) {
                                                final track =
                                                    _searchedRadioTracks[index];
                                                return ListTile(
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                  title: Text(
                                                    track.name,
                                                    style: TextStyle(
                                                      color: labelColor,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  trailing: IconButton(
                                                    style: IconButton.styleFrom(
                                                      backgroundColor:
                                                          accentColor
                                                              .withValues(
                                                                alpha: 0.1,
                                                              ),
                                                      foregroundColor:
                                                          accentColor,
                                                      padding:
                                                          const EdgeInsets.all(
                                                            4,
                                                          ),
                                                    ),
                                                    icon: const Icon(
                                                      Icons.add_rounded,
                                                      size: 18,
                                                    ),
                                                    onPressed: () async {
                                                      try {
                                                        await bgmService
                                                            .addTrackFromUrl(
                                                              track.name,
                                                              track.sourcePath,
                                                              sourceType:
                                                                  'radio',
                                                            );
                                                        if (!context.mounted)
                                                          return;
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              AppLocalizations.of(
                                                                    context,
                                                                  )?.addSuccess ??
                                                                  "Added to library successfully!",
                                                            ),
                                                            behavior:
                                                                SnackBarBehavior
                                                                    .floating,
                                                            backgroundColor:
                                                                Colors
                                                                    .green[700],
                                                          ),
                                                        );
                                                      } catch (e) {
                                                        if (!context.mounted)
                                                          return;
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              "Failed: $e",
                                                            ),
                                                            behavior:
                                                                SnackBarBehavior
                                                                    .floating,
                                                            backgroundColor:
                                                                Colors.red[700],
                                                          ),
                                                        );
                                                      }
                                                    },
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                      ] else if (_addSourceType == 'lofi') ...[
                                        if (_isLoadingLofi)
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 20,
                                            ),
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          )
                                        else if (_lofiTracks.isEmpty)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 20,
                                            ),
                                            child: Center(
                                              child: Text(
                                                "Không có bản nhạc Lofi nào gợi ý",
                                                style: TextStyle(
                                                  color: secondaryColor,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          )
                                        else
                                          Container(
                                            constraints: const BoxConstraints(
                                              maxHeight: 180,
                                            ),
                                            child: ListView.separated(
                                              shrinkWrap: true,
                                              itemCount: _lofiTracks.length,
                                              separatorBuilder:
                                                  (context, index) => Divider(
                                                    height: 1,
                                                    color: secondaryColor
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                  ),
                                              itemBuilder: (context, index) {
                                                final track =
                                                    _lofiTracks[index];
                                                return ListTile(
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                  title: Text(
                                                    track.name,
                                                    style: TextStyle(
                                                      color: labelColor,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  trailing: IconButton(
                                                    style: IconButton.styleFrom(
                                                      backgroundColor:
                                                          accentColor
                                                              .withValues(
                                                                alpha: 0.1,
                                                              ),
                                                      foregroundColor:
                                                          accentColor,
                                                      padding:
                                                          const EdgeInsets.all(
                                                            4,
                                                          ),
                                                    ),
                                                    icon: const Icon(
                                                      Icons.add_rounded,
                                                      size: 18,
                                                    ),
                                                    onPressed: () async {
                                                      try {
                                                        await bgmService
                                                            .addTrackFromUrl(
                                                              track.name,
                                                              track.sourcePath,
                                                              sourceType:
                                                                  'openlofi',
                                                            );
                                                        if (!context.mounted)
                                                          return;
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              AppLocalizations.of(
                                                                    context,
                                                                  )?.addSuccess ??
                                                                  "Added to library successfully!",
                                                            ),
                                                            behavior:
                                                                SnackBarBehavior
                                                                    .floating,
                                                            backgroundColor:
                                                                Colors
                                                                    .green[700],
                                                          ),
                                                        );
                                                      } catch (e) {
                                                        if (!context.mounted)
                                                          return;
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              "Failed: $e",
                                                            ),
                                                            behavior:
                                                                SnackBarBehavior
                                                                    .floating,
                                                            backgroundColor:
                                                                Colors.red[700],
                                                          ),
                                                        );
                                                      }
                                                    },
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                      ],
                                    ],
                                  ),
                                ),
                        ),

                        // PLAYLIST TRACKS
                        if (_isLoadingRadio)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (playlist.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                Icon(
                                  Icons.music_off_rounded,
                                  size: 48,
                                  color: secondaryColor.withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(context)?.emptySearch ??
                                      "No matching results found",
                                  style: TextStyle(
                                    color: secondaryColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: playlist.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final track = playlist[index];
                              // Đối với radio, do list nạp lại hashcode khác nhau, ta so khớp theo URL để bôi đậm bài đang phát
                              final isCurrent =
                                  bgmService.currentTrack?.sourcePath ==
                                  track.sourcePath;

                              return Container(
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? accentColor.withValues(alpha: 0.12)
                                      : cardBg.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isCurrent
                                        ? accentColor.withValues(alpha: 0.4)
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                  boxShadow: isCurrent
                                      ? [
                                          BoxShadow(
                                            color: accentColor.withValues(
                                              alpha: 0.15,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.02,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  leading: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isCurrent
                                          ? accentColor.withValues(alpha: 0.15)
                                          : secondaryColor.withValues(
                                              alpha: 0.1,
                                            ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: isCurrent && bgmService.isPlaying
                                        ? Center(
                                            child: BgmEqVisualizer(
                                              isPlaying: true,
                                              color: accentColor,
                                            ),
                                          )
                                        : Icon(
                                            (track.sourceType == 'direct_url' ||
                                                    track.sourceType ==
                                                        'radio' ||
                                                    track.sourceType ==
                                                        'openlofi')
                                                ? Icons.radio_rounded
                                                : Icons.music_note_rounded,
                                            color: isCurrent
                                                ? accentColor
                                                : secondaryColor,
                                            size: 22,
                                          ),
                                  ),
                                  title: Text(
                                    track.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isCurrent
                                          ? accentColor
                                          : labelColor,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        style: IconButton.styleFrom(
                                          backgroundColor: isCurrent
                                              ? accentColor
                                              : secondaryColor.withValues(
                                                  alpha: 0.1,
                                                ),
                                          foregroundColor: isCurrent
                                              ? Colors.white
                                              : labelColor,
                                        ),
                                        icon: Icon(
                                          isCurrent && bgmService.isPlaying
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          if (isCurrent &&
                                              bgmService.isPlaying) {
                                            bgmService.pauseBgm();
                                          } else {
                                            bgmService.playTrack(track);
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        style: IconButton.styleFrom(
                                          foregroundColor: accentColor,
                                        ),
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 22,
                                        ),
                                        onPressed: () {
                                          final editNameController =
                                              TextEditingController(
                                                text: track.name,
                                              );
                                          final editUrlController =
                                              TextEditingController(
                                                text: track.sourcePath,
                                              );

                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              backgroundColor: cardBg,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              title: Text(
                                                AppLocalizations.of(
                                                      context,
                                                    )?.editTrack ??
                                                    "Sửa thông tin nhạc",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  TextField(
                                                    controller:
                                                        editNameController,
                                                    style: TextStyle(
                                                      color: labelColor,
                                                    ),
                                                    decoration: InputDecoration(
                                                      labelText:
                                                          AppLocalizations.of(
                                                            context,
                                                          )?.trackName ??
                                                          "Tên bài hát",
                                                    ),
                                                  ),
                                                  if (track.sourceType ==
                                                      'direct_url') ...[
                                                    const SizedBox(height: 12),
                                                    TextField(
                                                      controller:
                                                          editUrlController,
                                                      style: TextStyle(
                                                        color: labelColor,
                                                      ),
                                                      decoration: InputDecoration(
                                                        labelText:
                                                            AppLocalizations.of(
                                                              context,
                                                            )?.trackUrl ??
                                                            "Link URL",
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: Text(
                                                    AppLocalizations.of(
                                                          context,
                                                        )?.cancel ??
                                                        "Hủy",
                                                    style: TextStyle(
                                                      color: secondaryColor,
                                                    ),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        accentColor,
                                                    foregroundColor:
                                                        Colors.white,
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed: () async {
                                                    try {
                                                      await bgmService.updateTrack(
                                                        track,
                                                        name: editNameController
                                                            .text,
                                                        sourcePath:
                                                            track.sourceType ==
                                                                'direct_url'
                                                            ? editUrlController
                                                                  .text
                                                            : null,
                                                      );
                                                      if (!context.mounted)
                                                        return;
                                                      Navigator.pop(context);
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            AppLocalizations.of(
                                                                  context,
                                                                )?.updateSuccess ??
                                                                "Updated successfully!",
                                                          ),
                                                          behavior:
                                                              SnackBarBehavior
                                                                  .floating,
                                                          backgroundColor:
                                                              Colors.green[700],
                                                        ),
                                                      );
                                                    } catch (e) {
                                                      if (!context.mounted)
                                                        return;
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            "Failed to update: $e",
                                                          ),
                                                          behavior:
                                                              SnackBarBehavior
                                                                  .floating,
                                                          backgroundColor:
                                                              Colors.red[700],
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  child: Text(
                                                    AppLocalizations.of(
                                                          context,
                                                        )?.save ??
                                                        "Lưu",
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        style: IconButton.styleFrom(
                                          foregroundColor: Colors.redAccent,
                                        ),
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 22,
                                        ),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              backgroundColor: cardBg,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              title: Text(
                                                AppLocalizations.of(
                                                      context,
                                                    )?.confirmDelete ??
                                                    "Confirm Delete",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              content: Text(
                                                "Are you sure you want to delete '${track.name}'?",
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: Text(
                                                    AppLocalizations.of(
                                                          context,
                                                        )?.cancel ??
                                                        "Cancel",
                                                    style: TextStyle(
                                                      color: secondaryColor,
                                                    ),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.redAccent,
                                                    foregroundColor:
                                                        Colors.white,
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    bgmService.deleteTrack(
                                                      track,
                                                    );
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text(
                                                    AppLocalizations.of(
                                                          context,
                                                        )?.confirm ??
                                                        "Delete",
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BgmEqVisualizer extends StatefulWidget {
  final bool isPlaying;
  final Color color;

  const BgmEqVisualizer({
    super.key,
    required this.isPlaying,
    required this.color,
  });

  @override
  State<BgmEqVisualizer> createState() => _BgmEqVisualizerState();
}

class _BgmEqVisualizerState extends State<BgmEqVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(BgmEqVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            double value = 0.2;
            if (widget.isPlaying) {
              final phase = (index * 0.25) * 2 * math.pi;
              value =
                  0.3 +
                  0.7 *
                      (0.5 +
                          0.5 *
                              math.sin(
                                _controller.value * 2 * math.pi + phase,
                              ));
            }
            return Container(
              width: 3,
              height: 18 * value,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        );
      },
    );
  }
}
