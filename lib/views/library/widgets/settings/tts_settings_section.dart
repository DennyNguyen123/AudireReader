import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'settings_card.dart';

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
              Icon(Icons.volume_up_rounded, color: Colors.amber[700], size: 28),
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
                  activeColor: Colors.amber[700],
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
                      color: isDark ? Colors.amber[300] : Colors.amber[850],
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
            ],
            onChanged: onTtsProviderChanged,
          ),
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
                    backgroundColor: Colors.amber[700],
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
