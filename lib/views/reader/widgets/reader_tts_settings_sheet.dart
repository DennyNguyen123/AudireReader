import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/tts_service.dart';
import '../../../models/settings.dart';
import '../../library/widgets/settings/tts_settings_section.dart';
import '../../library/pronunciation_dictionary_screen.dart';
import '../../../core/database/database_helper.dart';

class ReaderTtsSettingsSheet extends StatefulWidget {
  final TtsService ttsService;

  const ReaderTtsSettingsSheet({
    super.key,
    required this.ttsService,
  });

  @override
  State<ReaderTtsSettingsSheet> createState() => _ReaderTtsSettingsSheetState();
}

class _ReaderTtsSettingsSheetState extends State<ReaderTtsSettingsSheet> {
  final _speedController = TextEditingController();
  final _voiceSearchController = TextEditingController();

  double _speechRate = 0.5;
  String _ttsProvider = 'system';
  List<dynamic> _voices = [];
  Map<String, String>? _selectedVoice;
  String _selectedLanguageFilter = 'all';
  String _voiceSearchQuery = '';
  bool _isLoading = true;

  String _openAiTtsEndpoint = 'https://api.openai.com/v1';
  String _openAiTtsApiKey = '';
  String _openAiTtsModel = 'tts-1';

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
      final settings = await widget.ttsService.getSettings();

      setState(() {
        _speechRate = settings.speechRate;
        _speedController.text = (_speechRate * 2).toStringAsFixed(3);
        _ttsProvider = settings.ttsProvider;
      });

      await _loadVoices(settings);
    } catch (e) {
      // ignore: avoid_print
      print("Failed to load TTS settings in reader sheet: $e");
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
      final list = await widget.ttsService.getVoicesForProvider(settings.ttsProvider);

      _ttsProvider = settings.ttsProvider;
      _openAiTtsEndpoint = settings.openAiTtsEndpoint;
      _openAiTtsApiKey = settings.openAiTtsApiKey;
      _openAiTtsModel = settings.openAiTtsModel;
        
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
        } else if (settings.ttsProvider == 'openai') {
          initialVoice = {
            'name': settings.selectedVoiceName!,
            'locale': settings.selectedVoiceLocale!,
            'gender': 'Neutral'
          };
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
        widget.ttsService.updateSettings(voice: initialVoice);
      }

      if (mounted) {
        setState(() {
          _voices = list;
          _selectedVoice = initialVoice;
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print("Failed to load voices in reader sheet: $e");
    }
  }

  Future<void> _saveReadingPreference({
    double? speechRate,
    Map<String, String>? voice,
    String? ttsProvider,
    String? openAiTtsEndpoint,
    String? openAiTtsApiKey,
    String? openAiTtsModel,
  }) async {
    try {
      await widget.ttsService.updateSettings(
        speechRate: speechRate,
        voice: voice,
        ttsProvider: ttsProvider,
        openAiTtsEndpoint: openAiTtsEndpoint,
        openAiTtsApiKey: openAiTtsApiKey,
        openAiTtsModel: openAiTtsModel,
      );
    } catch (e) {
      // ignore: avoid_print
      print("Failed to save TTS settings in reader sheet: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = theme.scaffoldBackgroundColor;
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
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: ListenableBuilder(
            listenable: widget.ttsService,
            builder: (context, _) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.volume_up_rounded, size: 20, color: accentColor),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)?.textToSpeechTts ?? 'TEXT-TO-SPEECH (TTS)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // --- TTS SECTION ---
                    _isLoading
                        ? const SizedBox(
                            height: 150,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : TtsSettingsSection(
                            speechRate: _speechRate,
                            speedController: _speedController,
                            ttsProvider: _ttsProvider,
                            voices: _voices,
                            selectedVoice: _selectedVoice,
                            selectedLanguageFilter: _selectedLanguageFilter,
                            voiceSearchController: _voiceSearchController,
                            voiceSearchQuery: _voiceSearchQuery,
                            openAiTtsEndpoint: _openAiTtsEndpoint,
                            openAiTtsApiKey: _openAiTtsApiKey,
                            openAiTtsModel: _openAiTtsModel,
                            onOpenAiEndpointChanged: (val) {
                              setState(() => _openAiTtsEndpoint = val);
                              _saveReadingPreference(openAiTtsEndpoint: val);
                            },
                            onOpenAiApiKeyChanged: (val) {
                              setState(() => _openAiTtsApiKey = val);
                              _saveReadingPreference(openAiTtsApiKey: val);
                            },
                            onOpenAiModelChanged: (val) {
                              setState(() => _openAiTtsModel = val);
                              _saveReadingPreference(openAiTtsModel: val);
                            },
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
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
