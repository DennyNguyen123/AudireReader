import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/logger_service.dart';

class DeveloperConsoleScreen extends StatefulWidget {
  const DeveloperConsoleScreen({super.key});

  @override
  State<DeveloperConsoleScreen> createState() => _DeveloperConsoleScreenState();
}

class _DeveloperConsoleScreenState extends State<DeveloperConsoleScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'ALL'; // 'ALL', 'INFO', 'WARNING', 'ERROR', 'TTS', 'SYNC', 'WEBDAV'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return Colors.redAccent;
      case LogLevel.warning:
        return Colors.orangeAccent;
      case LogLevel.tts:
        return Colors.blueAccent;
      case LogLevel.sync:
        return Colors.greenAccent;
      case LogLevel.webdav:
        return Colors.purpleAccent;
      case LogLevel.info:
        return Colors.white70;
    }
  }

  Color _getTagColor(String tag) {
    switch (tag.toUpperCase()) {
      case 'TTS':
        return Colors.blue.withOpacity(0.2);
      case 'SYNC':
        return Colors.green.withOpacity(0.2);
      case 'WEBDAV':
        return Colors.purple.withOpacity(0.2);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }

  Color _getTagTextColor(String tag) {
    switch (tag.toUpperCase()) {
      case 'TTS':
        return Colors.blue[300]!;
      case 'SYNC':
        return Colors.green[300]!;
      case 'WEBDAV':
        return Colors.purple[300]!;
      default:
        return Colors.grey[300]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Debug Console',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all_rounded),
            tooltip: 'Copy All Logs',
            onPressed: () {
              final allLogs = LoggerService().logs.map((log) {
                final time = log.timestamp.toIso8601String().split('T')[1].substring(0, 8);
                return '[$time][${log.tag}][${log.levelName}] ${log.message}${log.error != null ? ' (Error: ${log.error})' : ''}';
              }).join('\n');
              
              Clipboard.setData(ClipboardData(text: allLogs));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All logs copied to clipboard.'),
                  backgroundColor: Colors.amber,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Clear Logs',
            onPressed: () {
              LoggerService().clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Console logs cleared.'),
                  backgroundColor: Colors.amber,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Panel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor, width: 1),
              ),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search logs...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      filled: true,
                      fillColor: isDark ? Colors.black26 : Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim().toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  // Filters List
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['ALL', 'INFO', 'WARNING', 'ERROR', 'TTS', 'SYNC', 'WEBDAV'].map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ChoiceChip(
                            label: Text(
                              filter,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.black87 : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: Colors.amber,
                            backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _selectedFilter = filter;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Log List view
          Expanded(
            child: ListenableBuilder(
              listenable: LoggerService(),
              builder: (context, _) {
                final allLogs = LoggerService().logs;
                
                // Filter logs based on search and level/tag filter
                final filteredLogs = allLogs.where((log) {
                  // 1. Search Query filter
                  if (_searchQuery.isNotEmpty) {
                    final msg = log.message.toLowerCase();
                    final err = log.error?.toLowerCase() ?? '';
                    final tag = log.tag.toLowerCase();
                    if (!msg.contains(_searchQuery) && !err.contains(_searchQuery) && !tag.contains(_searchQuery)) {
                      return false;
                    }
                  }

                  // 2. Select Filter type
                  if (_selectedFilter == 'ALL') return true;
                  if (_selectedFilter == 'INFO') return log.level == LogLevel.info;
                  if (_selectedFilter == 'WARNING') return log.level == LogLevel.warning;
                  if (_selectedFilter == 'ERROR') return log.level == LogLevel.error;
                  if (_selectedFilter == 'TTS') return log.level == LogLevel.tts || log.tag.toUpperCase() == 'TTS';
                  if (_selectedFilter == 'SYNC') return log.level == LogLevel.sync || log.tag.toUpperCase() == 'SYNC';
                  if (_selectedFilter == 'WEBDAV') return log.level == LogLevel.webdav || log.tag.toUpperCase() == 'WEBDAV';

                  return true;
                }).toList();

                if (filteredLogs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.speaker_notes_off_rounded, size: 48, color: Colors.grey.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'No matching logs found',
                          style: TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                // Render newest logs first
                final reversedLogs = filteredLogs.reversed.toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: reversedLogs.length,
                  itemBuilder: (context, index) {
                    final log = reversedLogs[index];
                    final time = log.timestamp.toLocal().toString().split(' ')[1].substring(0, 8);
                    return Card(
                      color: theme.cardColor.withOpacity(0.5),
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.dividerColor, width: 0.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Time
                                Text(
                                  time,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    color: isDark ? Colors.white30 : Colors.black38,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Tag
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getTagColor(log.tag),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    log.tag,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: _getTagTextColor(log.tag),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // Level
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getLevelColor(log.level).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    log.levelName,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: _getLevelColor(log.level),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Message
                            SelectableText(
                              log.message,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? Colors.white.withOpacity(0.87) : Colors.black87,
                                height: 1.4,
                              ),
                            ),
                            if (log.error != null) ...[
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: SelectableText(
                                  'Error: ${log.error}',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
