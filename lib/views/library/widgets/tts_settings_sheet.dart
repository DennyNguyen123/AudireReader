import 'package:flutter/material.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../services/tts_service.dart';
import '../../../../models/settings.dart';
import '../../../../l10n/app_localizations.dart';
import '../pronunciation_dictionary_screen.dart';
import 'settings/tts_settings_section.dart';

class TtsSettingsSheet extends StatefulWidget {
  const TtsSettingsSheet({super.key});

  @override
  State<TtsSettingsSheet> createState() => _TtsSettingsSheetState();
}

class _TtsSettingsSheetState extends State<TtsSettingsSheet> {
  final _speedController = TextEditingController();
  final _voiceSearchController = TextEditingController();

  double _speechRate = 0.5;
  String _ttsProvider = 'system';
  List<dynamic> _voices = [];
  Map<String, String>? _selectedVoice;
  String _selectedLanguageFilter = 'all';
  String _voiceSearchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _speedController.dispose();
    _voiceSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final ttsService = await TtsService.getInstance();
      final settings = await ttsService.getSettings();

      setState(() {
        _speechRate = settings.speechRate;
        _speedController.text = (_speechRate * 2).toStringAsFixed(3);
        _ttsProvider = settings.ttsProvider;
      });

      await _loadVoices(settings);
    } catch (e) {
      // ignore: avoid_print
      print("Failed to load TTS settings in sheet: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadVoices(AppSettings settings) async {
    try {
      final ttsService = await TtsService.getInstance();
      final list = await ttsService.getVoicesForProvider(settings.ttsProvider);

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
      } else if (settings.ttsProvider == 'microsoft_edge' && list.isNotEmpty) {
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
        ttsService.updateSettings(voice: initialVoice);
      }

      if (mounted) {
        setState(() {
          _voices = list;
          _selectedVoice = initialVoice;
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print("Failed to load voices in sheet: $e");
    }
  }

  Future<void> _saveReadingPreference({
    double? speechRate,
    Map<String, String>? voice,
    String? ttsProvider,
  }) async {
    try {
      final ttsService = await TtsService.getInstance();
      await ttsService.updateSettings(
        speechRate: speechRate,
        voice: voice,
        ttsProvider: ttsProvider,
      );
    } catch (e) {
      // ignore: avoid_print
      print("Failed to save TTS settings in sheet: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161616) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar for drag and title
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    AppLocalizations.of(context)?.ttsSettings ?? 'TTS Settings',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: _isLoading
                  ? const SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: TtsSettingsSection(
                        speechRate: _speechRate,
                        speedController: _speedController,
                        ttsProvider: _ttsProvider,
                        voices: _voices,
                        selectedVoice: _selectedVoice,
                        selectedLanguageFilter: _selectedLanguageFilter,
                        voiceSearchController: _voiceSearchController,
                        voiceSearchQuery: _voiceSearchQuery,
                        onSpeechRateSliderChanged: (val) {
                          setState(() {
                            _speechRate = val;
                            _speedController.text = (val * 2).toStringAsFixed(3);
                          });
                          _saveReadingPreference(speechRate: val);
                        },
                        onSpeechRateTextChanged: (text) {
                          final double? val = double.tryParse(text);
                          if (val != null) {
                            final clampedMultiplier = val.clamp(0.1, 2.0);
                            final newRate = clampedMultiplier / 2.0;
                            setState(() {
                              _speechRate = newRate;
                            });
                            _saveReadingPreference(speechRate: newRate);
                          }
                        },
                        onTtsProviderChanged: (val) async {
                          if (val != null) {
                            setState(() {
                              _ttsProvider = val;
                              _isLoading = true;
                            });
                            await _saveReadingPreference(ttsProvider: val);
                            final db = await DatabaseHelper.getInstance();
                            final settings = await db.getSettings();
                            await _loadVoices(settings);
                            if (val == 'supertonic') {
                              setState(() {
                                _selectedVoice = {
                                  'name': 'M1',
                                  'locale': 'offline',
                                  'gender': 'Male',
                                };
                              });
                            }
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                        onLanguageFilterChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedLanguageFilter = val;
                            });
                          }
                        },
                        onVoiceSearchChanged: (val) {
                          setState(() {
                            _voiceSearchQuery = val.trim().toLowerCase();
                          });
                        },
                        onClearVoiceSearch: () {
                          _voiceSearchController.clear();
                          setState(() {
                            _voiceSearchQuery = '';
                          });
                        },
                        onVoiceSelected: (voiceMap) {
                          setState(() {
                            _selectedVoice = voiceMap;
                          });
                          _saveReadingPreference(voice: voiceMap);
                        },
                        onManagePronunciation: () {
                          Navigator.pop(context); // Close bottom sheet
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PronunciationDictionaryScreen(),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Function to show the sheet
void showTtsSettingsBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const TtsSettingsSheet(),
      );
    },
  );
}
