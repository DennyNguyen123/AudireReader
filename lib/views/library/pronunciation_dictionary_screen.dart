import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../models/pronunciation_rule.dart';
import '../../services/tts_service.dart';
import '../../l10n/app_localizations.dart';

class PronunciationDictionaryScreen extends StatefulWidget {
  const PronunciationDictionaryScreen({super.key});

  @override
  State<PronunciationDictionaryScreen> createState() => _PronunciationDictionaryScreenState();
}

class _PronunciationDictionaryScreenState extends State<PronunciationDictionaryScreen> {
  List<PronunciationRule> _rules = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final db = await DatabaseHelper.getInstance();
      final rules = await db.getAllPronunciationRules();
      setState(() {
        _rules = rules;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.failedToLoadRules(e.toString()) ?? 'Failed to load rules: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteRule(PronunciationRule rule) async {
    try {
      final db = await DatabaseHelper.getInstance();
      await db.deletePronunciationRule(rule.id);
      
      // Cập nhật dịch vụ TTS ngay lập tức
      final tts = await TtsService.getInstance();
      await tts.loadPronunciationRules();

      _loadRules();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.ruleDeletedSuccessfully ?? 'Rule deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.failedToDeleteRule(e.toString()) ?? 'Failed to delete rule: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _toggleRuleActive(PronunciationRule rule, bool value) async {
    rule.active = value;
    try {
      final db = await DatabaseHelper.getInstance();
      await db.savePronunciationRule(rule);

      // Cập nhật dịch vụ TTS ngay lập tức
      final tts = await TtsService.getInstance();
      await tts.loadPronunciationRules();

      _loadRules();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.failedToUpdateRule(e.toString()) ?? 'Failed to update rule: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showAddEditRuleDialog({PronunciationRule? rule}) {
    final targetController = TextEditingController(text: rule?.target ?? '');
    final replacementController = TextEditingController(text: rule?.replacement ?? '');
    bool isRegex = rule?.isRegex ?? false;
    bool active = rule?.active ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              rule == null ? (AppLocalizations.of(context)?.addPronunciationRule ?? 'Add Pronunciation Rule') : (AppLocalizations.of(context)?.editPronunciationRule ?? 'Edit Pronunciation Rule'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: targetController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)?.originalTextTarget ?? 'Original Text (Target)',
                      hintText: 'e.g. ko, main, nv',
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.black12,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: replacementController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)?.readAsReplacement ?? 'Read As (Replacement)',
                      hintText: 'e.g. không, nhân vật chính',
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.black12,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(AppLocalizations.of(context)?.useRegularExpressionRegex ?? 'Use Regular Expression (Regex)'),
                    subtitle: Text(AppLocalizations.of(context)?.advancedPatternMatching ?? 'Advanced pattern matching'),
                    value: isRegex,
                    activeThumbColor: Theme.of(context).colorScheme.primary,
                    activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setDialogState(() {
                        isRegex = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final target = targetController.text.trim();
                  final replacement = replacementController.text.trim();
                  
                  if (target.isEmpty || replacement.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)?.pleaseFillBothFields ?? 'Please fill in both fields'),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    );
                    return;
                  }

                  final newRule = rule ?? PronunciationRule();
                  newRule.target = target;
                  newRule.replacement = replacement;
                  newRule.isRegex = isRegex;
                  newRule.active = active;

                  try {
                    final db = await DatabaseHelper.getInstance();
                    await db.savePronunciationRule(newRule);

                    // Cập nhật dịch vụ TTS ngay lập tức
                    final tts = await TtsService.getInstance();
                    await tts.loadPronunciationRules();

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                    _loadRules();
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(rule == null ? (AppLocalizations.of(context)?.ruleAddedSuccessfully ?? 'Rule added successfully') : (AppLocalizations.of(context)?.ruleUpdatedSuccessfully ?? 'Rule updated successfully')),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)?.failedToSaveRule(e.toString()) ?? 'Failed to save rule: $e'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(AppLocalizations.of(context)?.save ?? 'Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirm(PronunciationRule rule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.confirmDelete ?? 'Confirm Delete'),
        content: Text(AppLocalizations.of(context)?.confirmDeleteRuleTarget(rule.target) ?? 'Are you sure you want to delete the rule for "${rule.target}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRule(rule);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)?.delete ?? 'Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAF9F6),
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.dictionary ?? 'Pronunciation Dictionary',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rules.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.record_voice_over_rounded,
                        size: 80,
                        color: isDark ? Colors.white30 : Colors.black26,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)?.noCustomPronunciationRules ?? 'No custom pronunciation rules',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)?.tapToAddFirstRule ?? 'Tap the "+" button to add your first rule',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _rules.length,
                  itemBuilder: (context, index) {
                    final rule = _rules[index];
                    return Card(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDark ? Colors.white10 : Colors.black12,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                rule.target,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                rule.replacement,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              if (rule.isRegex) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)?.regex ?? 'Regex',
                                    style: const TextStyle(color: Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                rule.active ? (AppLocalizations.of(context)?.active ?? 'Active') : (AppLocalizations.of(context)?.inactive ?? 'Inactive'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: rule.active ? Colors.green : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: rule.active,
                              activeThumbColor: Theme.of(context).colorScheme.primary,
                              activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                              onChanged: (val) => _toggleRuleActive(rule, val),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent),
                              onPressed: () => _showAddEditRuleDialog(rule: rule),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                              onPressed: () => _showDeleteConfirm(rule),
                            ),
                          ],
                        ),
                        onTap: () => _showAddEditRuleDialog(rule: rule),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditRuleDialog(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
