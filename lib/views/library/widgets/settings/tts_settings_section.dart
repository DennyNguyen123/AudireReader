import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'settings_card.dart';
import '../../../../services/supertonic_service.dart';

class TtsSettingsSection extends StatelessWidget {
  final double speechRate;
  final TextEditingController speedController;
  final String ttsProvider;
  final List<dynamic> voices;
  final Map<String, String>? selectedVoice;
  final String selectedLanguageFilter;
  final TextEditingController voiceSearchController;
  final String voiceSearchQuery;
  final ValueChanged<double> onSpeechRateSliderChanged;
  final ValueChanged<String> onSpeechRateTextChanged;
  final ValueChanged<String?> onTtsProviderChanged;
  final ValueChanged<String?> onLanguageFilterChanged;
  final ValueChanged<String> onVoiceSearchChanged;
  final VoidCallback onClearVoiceSearch;
  final ValueChanged<Map<String, String>> onVoiceSelected;
  final VoidCallback onManagePronunciation;

  const TtsSettingsSection({
    super.key,
    required this.speechRate,
    required this.speedController,
    required this.ttsProvider,
    required this.voices,
    required this.selectedVoice,
    required this.selectedLanguageFilter,
    required this.voiceSearchController,
    required this.voiceSearchQuery,
    required this.onSpeechRateSliderChanged,
    required this.onSpeechRateTextChanged,
    required this.onTtsProviderChanged,
    required this.onLanguageFilterChanged,
    required this.onVoiceSearchChanged,
    required this.onClearVoiceSearch,
    required this.onVoiceSelected,
    required this.onManagePronunciation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.volume_up_rounded, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)?.ttsSettings ?? 'TTS Settings',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // TỐC ĐỘ ĐỌC TTS SLIDER
          Row(
            children: [
              const Icon(Icons.speed_rounded, size: 20),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)?.readingSpeed ?? 'Reading Speed',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Expanded(
                child: Slider(
                  value: speechRate,
                  min: 0.05,
                  max: 1.0,
                  activeColor: theme.colorScheme.primary,
                  onChanged: onSpeechRateSliderChanged,
                ),
              ),
              // Hộp nhập số tốc độ chính xác 3 số lẻ thập phân
              SizedBox(
                width: 85,
                height: 38,
                child: TextField(
                  controller: speedController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    suffixText: 'x',
                    suffixStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.white10 : Colors.black12,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: onSpeechRateTextChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // CHỌN TTS PROVIDER DROPDOWN
          Text(
            AppLocalizations.of(context)?.ttsProvider ?? 'TTS Provider',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: ttsProvider,
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
              DropdownMenuItem<String>(
                value: 'system',
                child: Text(
                  AppLocalizations.of(context)?.systemTtsOffline ?? 'System TTS (Offline)',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              DropdownMenuItem<String>(
                value: 'microsoft_edge',
                child: Text(
                  AppLocalizations.of(context)?.edgeTtsOnline ?? 'Microsoft Edge TTS (Online)',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const DropdownMenuItem<String>(
                value: 'supertonic',
                child: Text(
                  'Supertonic Offline AI (New)',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
            onChanged: onTtsProviderChanged,
          ),
          if (ttsProvider == 'supertonic') ...[
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
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              supertonic.downloadStatus,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: supertonic.downloadProgress,
                              backgroundColor: isDark ? Colors.white10 : Colors.black12,
                              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${(supertonic.downloadProgress * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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
                            const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Offline AI Model Required',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'To use Supertonic Offline AI voices, you need to download the voice model files (~96MB) to your device.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
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
                                backgroundColor: theme.colorScheme.primary,
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
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Offline Voice Model Ready',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                                Text(
                                  'Supertonic Offline AI is fully operational.',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
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
                                  title: const Text('Delete Model Files?'),
                                  content: const Text('Are you sure you want to delete the offline AI model files to free up space? You will need to redownload them to use this feature again.'),
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

          // CHỌN GIỌNG ĐỌC & BỘ LỌC NGÔN NGỮ DROPDOWN
          if (voices.isNotEmpty) ...[
            // BỘ LỌC NGÔN NGỮ
            Text(
              AppLocalizations.of(context)?.languageFilter ?? 'Language Filter',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedLanguageFilter,
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
                DropdownMenuItem<String>(
                  value: 'all',
                  child: Text(
                    AppLocalizations.of(context)?.allLanguages ?? 'All Languages',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                DropdownMenuItem<String>(
                  value: 'vi',
                  child: Text(
                    AppLocalizations.of(context)?.vietnamese ?? 'Vietnamese',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                DropdownMenuItem<String>(
                  value: 'en',
                  child: Text(
                    AppLocalizations.of(context)?.english ?? 'English',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                DropdownMenuItem<String>(
                  value: 'others',
                  child: Text(
                    AppLocalizations.of(context)?.otherLanguages ?? 'Others (Japanese, French...)',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
              onChanged: onLanguageFilterChanged,
            ),
            const SizedBox(height: 16),

            // Ô TÌM KIẾM GIỌNG ĐỌC
            Text(
              AppLocalizations.of(context)?.searchVoice ?? 'Search Voice',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: voiceSearchController,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.black12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                hintText: AppLocalizations.of(context)?.searchVoiceHint ?? 'Type to search voice name...',
                hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.7), fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.withValues(alpha: 0.8)),
                suffixIcon: voiceSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, color: Colors.grey.withValues(alpha: 0.8)),
                        onPressed: onClearVoiceSearch,
                      )
                    : null,
              ),
              onChanged: onVoiceSearchChanged,
            ),
            const SizedBox(height: 16),

            Text(
              AppLocalizations.of(context)?.selectVoice ?? 'Select Voice',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final filteredDisplayVoices = voices.where((v) {
                  final lang = v['locale']?.toString().toLowerCase() ?? '';
                  final name = v['name']?.toString().toLowerCase() ?? '';

                  // Lọc theo ngôn ngữ
                  bool matchesLang = true;
                  if (selectedLanguageFilter == 'vi') {
                    matchesLang = lang.startsWith('vi');
                  } else if (selectedLanguageFilter == 'en') {
                    matchesLang = lang.startsWith('en');
                  } else if (selectedLanguageFilter == 'others') {
                    matchesLang = !lang.startsWith('vi') && !lang.startsWith('en');
                  }

                  if (!matchesLang) return false;

                  // Lọc theo ô tìm kiếm
                  if (voiceSearchQuery.isNotEmpty) {
                    return name.contains(voiceSearchQuery) || lang.contains(voiceSearchQuery);
                  }

                  return true;
                }).toList();

                return DropdownButtonFormField<String>(
                  initialValue: filteredDisplayVoices.any((v) => v['name']?.toString() == selectedVoice?['name'])
                      ? (selectedVoice?['name'])
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
                  dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                            style: const TextStyle(fontSize: 13),
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
                          (selectedMap as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
                        );
                        onVoiceSelected(voiceMap);
                      }
                    }
                  },
                );
              },
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onManagePronunciation,
                  icon: const Icon(Icons.record_voice_over_rounded),
                  label: Text(
                    AppLocalizations.of(context)?.managePronunciation ?? 'Manage Pronunciation Rules',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
