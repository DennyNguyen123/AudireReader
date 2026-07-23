import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'dart:io';
import 'package:audire_reader/services/tts_service.dart';
import 'package:audire_reader/views/reader/reader_screen.dart';

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

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReaderScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2C2C2C).withValues(alpha: 0.75)
                            : Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.05,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Cover image
                          Container(
                            width: 48,
                            height: 48,
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: isDark
                                  ? Colors.grey[850]
                                  : Colors.grey[300],
                              image:
                                  (mediaItem.artUri != null &&
                                      File(mediaItem.artUri!.path).existsSync())
                                  ? DecorationImage(
                                      image: FileImage(
                                        File(mediaItem.artUri!.path),
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child:
                                (mediaItem.artUri == null ||
                                    !File(mediaItem.artUri!.path).existsSync())
                                ? Icon(
                                    Icons.music_note_rounded,
                                    color: isDark
                                        ? Colors.white30
                                        : Colors.black38,
                                  )
                                : null,
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
              ),
            );
          },
        );
      },
    );
  }
}
