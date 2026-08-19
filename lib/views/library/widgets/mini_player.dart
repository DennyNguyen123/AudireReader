import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'dart:io';
import 'package:audire_reader/services/tts_service.dart';
import 'package:audire_reader/views/reader/reader_screen.dart';
import 'package:audire_reader/core/utils/path_helper.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  TtsService? _ttsService;

  @override
  void initState() {
    super.initState();
    TtsService.getInstance().then((instance) {
      if (mounted) {
        setState(() {
          _ttsService = instance;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_ttsService == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return StreamBuilder<MediaItem?>(
      stream: _ttsService!.audioHandler.mediaItem,
      builder: (context, mediaItemSnapshot) {
        final mediaItem = mediaItemSnapshot.data;
        if (mediaItem == null || _ttsService!.activeBook == null) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<PlaybackState>(
          stream: _ttsService!.audioHandler.playbackState,
          builder: (context, playbackStateSnapshot) {
            final playbackState = playbackStateSnapshot.data;
            final isPlaying = playbackState?.playing ?? false;
            final isProcessing =
                playbackState?.processingState ==
                    AudioProcessingState.buffering ||
                playbackState?.processingState == AudioProcessingState.loading;

            // Không hiện nếu không play và không pause (trạng thái idle/stopped)
            if (playbackState?.processingState == AudioProcessingState.idle) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.08),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.25 : 0.08,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: isDark
                      ? const Color(0xFF2C2C2C).withValues(alpha: 0.95)
                      : Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(15),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ReaderScreen()),
                      );
                    },
                    child: Row(
                        children: [
                          // Cover image
                          Builder(
                            builder: (context) {
                              final rawPath = mediaItem.artUri != null
                                  ? (mediaItem.artUri!.isScheme('file')
                                      ? mediaItem.artUri!.toFilePath()
                                      : mediaItem.artUri!.path)
                                  : null;
                              final resolvedPath = PathHelper.resolveCoverPathSync(
                                rawPath,
                                uuid: _ttsService?.activeBook?.uuid,
                              );
                              final hasValidImage = resolvedPath != null &&
                                  File(resolvedPath).existsSync();

                              return Container(
                                width: 48,
                                height: 48,
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: isDark
                                      ? Colors.grey[850]
                                      : Colors.grey[300],
                                  image: hasValidImage
                                      ? DecorationImage(
                                          image: ResizeImage(
                                            FileImage(
                                              File(resolvedPath),
                                            ),
                                            width: 96,
                                            height: 96,
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: !hasValidImage
                                    ? Icon(
                                        Icons.music_note_rounded,
                                        color: isDark
                                            ? Colors.white30
                                            : Colors.black38,
                                      )
                                    : null,
                              );
                            },
                          ),

                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  mediaItem.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  mediaItem.album ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Controls
                          if (isProcessing)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryColor,
                                ),
                              ),
                            )
                          else
                            IconButton(
                              icon: Icon(
                                isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 32,
                              ),
                              color: primaryColor,
                              onPressed: () {
                                if (isPlaying) {
                                  _ttsService!.pauseSpeaking();
                                } else {
                                  _ttsService!.togglePlayPause();
                                }
                              },
                            ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
      },
    );
  }
}
