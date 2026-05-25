import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../core/utils/path_helper.dart';
import 'dart:async';
import 'dart:io' show Platform, File, Process;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../core/database/database_helper.dart';
import 'edge_tts_service.dart';
import 'supertonic_service.dart';
import 'bgm_service.dart';

enum TtsEngineType { system, edge, supertonic }

class CachedAudio {
  final String filePath;
  final List<EdgeMetadataChunk> metadata;
  CachedAudio(this.filePath, this.metadata);
}

class MyAudioHandler extends BaseAudioHandler with QueueHandler {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _edgePlayer = AudioPlayer();
  
  // Callback báo từ đang đọc về UI để highlight
  Function(String text, int start, int end, String word)? onWordProgress;
  
  // Callback báo khi đọc xong đoạn văn để chuyển sang đoạn tiếp theo
  Function()? onParagraphComplete;

  bool _isSpeaking = false;
  String _currentText = "";
  double _speechRate = 0.5; // Tốc độ nói hiện tại của TTS (0.5 tương đương 1.0x)
  Timer? _windowsTimer; // Timer giả lập hoàn thành trên Windows

  TtsEngineType _activeEngine = TtsEngineType.system;
  final List<EdgeMetadataChunk> _edgeMetadata = [];
  int _lastHighlightIndex = 0;
  String _lastWord = "";

  StreamSubscription? _positionSub;
  StreamSubscription? _completeSub;

  // Cache key helper and manager attributes
  final Map<String, CachedAudio> _audioCache = {};
  final Map<String, Future<CachedAudio>> _pendingPrefetches = {};
  final Map<String, StreamSubscription> _activePrefetches = {};

  String _computeSha256(String text) {
    return sha256.convert(utf8.encode(text)).toString();
  }

  void _addToCache(String key, CachedAudio item) {
    _audioCache[key] = item;
    if (_audioCache.length > 15) {
      final oldestKey = _audioCache.keys.first;
      final oldestItem = _audioCache.remove(oldestKey);
      if (oldestItem != null) {
        try {
          final file = File(oldestItem.filePath);
          if (file.existsSync()) {
            file.deleteSync();
          }
        } catch (e) {
          debugPrint("Failed to delete cached audio file: $e");
        }
      }
    }
  }

  Future<String> _synthesizeSystemTtsToWavWindows(String text, String voiceName, double rate) async {
    final cacheKey = _computeSha256("$text|$voiceName|$rate");
    final tempDir = await PathHelper.getAppCacheDirectory();
    final wavPath = '${tempDir.path}\\sys_tts_$cacheKey.wav';
    final wavFile = File(wavPath);
    
    if (wavFile.existsSync() && wavFile.lengthSync() > 0) {
      return wavPath;
    }
    
    final txtPath = '${tempDir.path}\\sys_text_$cacheKey.txt';
    final ps1Path = '${tempDir.path}\\sys_synth_$cacheKey.ps1';
    
    // Ghi file text tạm (UTF-8)
    await File(txtPath).writeAsString(text, encoding: utf8);
    
    // Tạo script powershell
    final escapedWavPath = wavPath.replaceAll('\\', '\\\\');
    final escapedTxtPath = txtPath.replaceAll('\\', '\\\\');
    
    final ps1Content = '''
try {
    [void][Windows.Media.SpeechSynthesis.SpeechSynthesizer, Windows.Media, ContentType=WindowsRuntime]
    
    # Load assembly chứa WindowsRuntimeSystemExtensions
    \$assembly = [System.Reflection.Assembly]::Load("System.Runtime.WindowsRuntime, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
    \$extType = \$assembly.GetType("System.WindowsRuntimeSystemExtensions")
    
    \$synth = New-Object Windows.Media.SpeechSynthesis.SpeechSynthesizer
    
    # Cấu hình giọng đọc
    \$selectedVoice = '$voiceName'
    \$voices = [Windows.Media.SpeechSynthesis.SpeechSynthesizer]::AllVoices
    \$voice = \$null
    
    if (\$selectedVoice -ne '' -and \$selectedVoice -ne 'default') {
        \$voice = \$voices | Where-Object { \$_.DisplayName -eq \$selectedVoice -or \$_.Id -eq \$selectedVoice -or \$_.DisplayName -like "*\$selectedVoice*" } | Select-Object -First 1
    }
    
    if (\$voice -eq \$null) {
        # Tự động tìm giọng tiếng Việt nếu chưa setup voice hoặc không tìm thấy voice đã chọn
        \$voice = \$voices | Where-Object { \$_.Language -like '*vi*' -or \$_.DisplayName -like '*An*' } | Select-Object -First 1
    }
    
    if (\$voice -ne \$null) {
        \$synth.Voice = \$voice
    }
    
    # Cấu hình Rate (Tốc độ đọc)
    # WinRT SpeechRate từ 0.5 đến 6.0. Mặc định là 1.0 (tương đương với rate 0.5 từ Flutter)
    \$winrtRate = $rate * 2.0
    if (\$winrtRate -lt 0.5) { \$winrtRate = 0.5 }
    if (\$winrtRate -gt 6.0) { \$winrtRate = 6.0 }
    \$synth.Options.SpeakingRate = \$winrtRate
    
    # Đọc text từ file
    \$text = Get-Content -Path '$escapedTxtPath' -Raw -Encoding UTF8
    
    \$asyncOp = \$synth.SynthesizeTextToStreamAsync(\$text)
    
    # Chuyển đổi AsTask
    \$asTaskMethod = \$extType.GetMethods() | Where-Object { \$_.Name -eq 'AsTask' -and \$_.IsGenericMethodDefinition } | Select-Object -First 1
    \$streamType = [Windows.Media.SpeechSynthesis.SpeechSynthesisStream, Windows.Media, ContentType=WindowsRuntime]
    \$concreteMethod = \$asTaskMethod.MakeGenericMethod(\$streamType)
    
    \$task = \$concreteMethod.Invoke(\$null, @(\$asyncOp))
    \$task.Wait()
    \$stream = \$task.Result
    
    # Ghi file
    \$fileStream = [System.IO.File]::Create('$escapedWavPath')
    \$inputStream = \$stream.GetInputStreamAt(0)
    \$reader = New-Object Windows.Storage.Streams.DataReader(\$inputStream)
    
    \$loadOp = \$reader.LoadAsync(\$stream.Size)
    \$uintType = [System.UInt32]
    \$concreteMethodLoad = \$asTaskMethod.MakeGenericMethod(\$uintType)
    \$loadTask = \$concreteMethodLoad.Invoke(\$null, @(\$loadOp))
    \$loadTask.Wait()
    
    \$bytes = New-Object Byte[](\$stream.Size)
    \$reader.ReadBytes(\$bytes)
    \$fileStream.Write(\$bytes, 0, \$bytes.Length)
    \$fileStream.Close()
    \$reader.Dispose()
    \$stream.Dispose()
    \$synth.Dispose()
} catch {
    Write-Error \$_
    exit 1
}
''';
    
    await File(ps1Path).writeAsString(ps1Content, encoding: utf8);
    
    // Thực thi PowerShell ngầm
    final result = await Process.run('powershell', [
      '-ExecutionPolicy', 'Bypass',
      '-File', ps1Path
    ]);
    
    // Dọn dẹp files tạm
    try {
      await File(txtPath).delete();
      await File(ps1Path).delete();
    } catch (_) {}
    
    if (result.exitCode != 0) {
      throw Exception("PowerShell SpeechSynthesis failed: ${result.stderr}");
    }
    
    if (!wavFile.existsSync() || wavFile.lengthSync() == 0) {
      throw Exception("Wav file was not generated or is empty");
    }
    
    return wavPath;
  }

  Future<CachedAudio?> prefetchSingle(String text, String voice, double rate, String provider) async {
    final cacheKey = _computeSha256("$text|$voice|$rate");
    
    if (_audioCache.containsKey(cacheKey)) {
      return _audioCache[cacheKey];
    }
    
    if (_pendingPrefetches.containsKey(cacheKey)) {
      return _pendingPrefetches[cacheKey];
    }
    
    final completer = Completer<CachedAudio>();
    _pendingPrefetches[cacheKey] = completer.future;
    
    if (provider == 'system' && Platform.isWindows) {
      // System TTS trên Windows: kết xuất bằng PowerShell ngầm
      _synthesizeSystemTtsToWavWindows(text, voice, rate).then((filePath) {
        final cached = CachedAudio(filePath, []);
        _addToCache(cacheKey, cached);
        _pendingPrefetches.remove(cacheKey);
        completer.complete(cached);
      }).catchError((err) {
        _pendingPrefetches.remove(cacheKey);
        completer.completeError(err);
      });
    } else {
      // Edge TTS
      StreamSubscription? subscription;
      try {
        final audioBytes = <int>[];
        final metadata = <EdgeMetadataChunk>[];
        
        final stream = EdgeTtsService.synthesize(
          text: text,
          voice: voice,
        );
        
        subscription = stream.listen(
          (chunk) {
            if (chunk is EdgeAudioChunk) {
              audioBytes.addAll(chunk.data);
            } else if (chunk is EdgeMetadataChunk) {
              metadata.add(chunk);
            }
          },
          onError: (err) {
            _pendingPrefetches.remove(cacheKey);
            _activePrefetches.remove(cacheKey);
            completer.completeError(err);
          },
          onDone: () async {
            _activePrefetches.remove(cacheKey);
            try {
              if (audioBytes.isEmpty) {
                throw Exception("Empty audio bytes");
              }
              final tempDir = await PathHelper.getAppCacheDirectory();
              final file = File('${tempDir.path}/tts_$cacheKey.mp3');
              await file.writeAsBytes(audioBytes, flush: true);
              
              final cached = CachedAudio(file.path, metadata);
              _addToCache(cacheKey, cached);
              _pendingPrefetches.remove(cacheKey);
              completer.complete(cached);
            } catch (e) {
              _pendingPrefetches.remove(cacheKey);
              completer.completeError(e);
            }
          },
          cancelOnError: true,
        );
        
        _activePrefetches[cacheKey] = subscription;
        
      } catch (e) {
        _pendingPrefetches.remove(cacheKey);
        _activePrefetches.remove(cacheKey);
        completer.completeError(e);
      }
    }
    
    return completer.future;
  }

  Future<void> prefetch(List<String> texts) async {
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();
    final provider = (settings.ttsProvider == 'microsoft_edge') ? 'microsoft_edge' : 'system';
    
    // Chỉ prefetch cho Edge TTS HOẶC System TTS trên Windows
    if (provider != 'microsoft_edge' && !(provider == 'system' && Platform.isWindows)) return;
    
    String voice = settings.selectedVoiceName ?? (provider == 'microsoft_edge' ? "vi-VN-HoaiMyNeural" : "default");
    if (provider == 'system' && (voice.contains('Neural') || voice.split('-').length > 2)) {
      voice = "default";
    }
    final rate = _speechRate;
    
    for (final text in texts) {
      if (!playbackState.value.playing) break;
      try {
        await prefetchSingle(text, voice, rate, provider);
      } catch (e) {
        debugPrint("Failed to prefetch text: $e");
      }
    }
  }

  void cancelOtherPrefetches(String activeCacheKey) {
    final keysToCancel = _activePrefetches.keys.where((k) => k != activeCacheKey).toList();
    for (final key in keysToCancel) {
      _activePrefetches[key]?.cancel();
      _activePrefetches.remove(key);
      _pendingPrefetches.remove(key);
    }
  }

  void cancelAllPrefetches() {
    for (final sub in _activePrefetches.values) {
      sub.cancel();
    }
    _activePrefetches.clear();
    _pendingPrefetches.clear();
  }

  MyAudioHandler() {
    _initTts();
    _initEdgePlayer();
    _cleanOldCacheFiles();
  }

  void _initTts() {
    if (!Platform.isWindows) {
      _tts.setSharedInstance(true);
    }
    _tts.setProgressHandler((String text, int start, int end, String word) {
      if (_activeEngine != TtsEngineType.system) return;
      _currentText = text;
      onWordProgress?.call(text, start, end, word);
    });

    _tts.setCompletionHandler(() {
      if (Platform.isWindows) return;
      if (_activeEngine != TtsEngineType.system) return;

      // Nếu trạng thái phát đã bị dừng hoặc ngắt bởi mã nguồn, bỏ qua hoàn toàn sự kiện
      if (!_isSpeaking) return;
      
      _isSpeaking = false;
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.completed,
      ));
      
      // Đưa việc gọi callback ra ngoài Native Thread sang Dart Event Loop (Platform Thread)
      Future.delayed(Duration.zero, () {
        onParagraphComplete?.call();
      });
    });

    _tts.setErrorHandler((msg) {
      if (_activeEngine != TtsEngineType.system) return;
      _isSpeaking = false;
      _windowsTimer?.cancel();
      playbackState.add(playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.error,
      ));
    });
  }

  void _initEdgePlayer() {
    _positionSub = _edgePlayer.onPositionChanged.listen((duration) {
      if (_activeEngine != TtsEngineType.edge || !_isSpeaking) return;

      final currentMs = duration.inMilliseconds;
      EdgeMetadataChunk? currentWordChunk;

      for (final chunk in _edgeMetadata) {
        if (currentMs >= chunk.offset && currentMs <= chunk.offset + chunk.duration) {
          currentWordChunk = chunk;
          break;
        }
      }

      if (currentWordChunk != null && currentWordChunk.text != _lastWord) {
        _lastWord = currentWordChunk.text;
        
        // Stateful search để tìm chính xác index của từ lặp lại trong chuỗi
        int startIdx = _currentText.indexOf(_lastWord, _lastHighlightIndex);
        if (startIdx == -1) {
          // Fallback nếu không tìm thấy từ kế tiếp, tìm từ đầu
          startIdx = _currentText.indexOf(_lastWord);
        }
        
        if (startIdx != -1) {
          _lastHighlightIndex = startIdx + _lastWord.length;
          onWordProgress?.call(_currentText, startIdx, startIdx + _lastWord.length, _lastWord);
        }
      }
    });

    _completeSub = _edgePlayer.onPlayerComplete.listen((_) {
      if ((_activeEngine != TtsEngineType.edge && _activeEngine != TtsEngineType.supertonic && !(Platform.isWindows && _activeEngine == TtsEngineType.system)) || !_isSpeaking) return;

      _isSpeaking = false;
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.completed,
      ));

      Future.delayed(Duration.zero, () {
        onParagraphComplete?.call();
      });
    });
  }
  void _startWindowsCompletionTimer(String text) {
    _windowsTimer?.cancel();
    
    final speedMultiplier = _speechRate * 2.0; 
    final endPunctCount = RegExp(r'[.!?…]').allMatches(text).length;
    final midPunctCount = RegExp(r'[,;:\-]').allMatches(text).length;
    
    final baseDurationMs = text.length * 80.0;
    final pauseDurationMs = (endPunctCount * 300.0) + (midPunctCount * 150.0);
    
    final durationMs = ((baseDurationMs + pauseDurationMs + 750.0) / speedMultiplier).round();
    
    _windowsTimer = Timer(Duration(milliseconds: durationMs), () {
      if (_isSpeaking && _activeEngine == TtsEngineType.system) {
        _isSpeaking = false;
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.completed,
        ));
        
        Future.delayed(Duration.zero, () {
          onParagraphComplete?.call();
        });
      }
    });
  }
  Future<void> updateMetadata({
    required String bookTitle,
    required String chapterTitle,
    required int paragraphIndex,
    required int totalParagraphs,
  }) async {
    mediaItem.add(MediaItem(
      id: 'tts_paragraph_$paragraphIndex',
      album: bookTitle,
      title: chapterTitle,
      artist: 'Audire Reader',
      duration: Duration(seconds: totalParagraphs), // Duration giả lập hiển thị
    ));
  }

  Future<void> speak(String text) async {
    // Gọi resume nhạc nền nếu được bật
    BgmService.getInstance().resumeBgm();
    
    // 1. Dừng mọi tác vụ phát cũ một cách an toàn và tuần tự
    _isSpeaking = false;
    _windowsTimer?.cancel();
    
    await _tts.stop();
    await _edgePlayer.stop();
    
    if (!Platform.isWindows) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    _currentText = text;
    _lastHighlightIndex = 0;
    _lastWord = "";
    
    // 2. Đọc cấu hình nhà cung cấp từ cơ sở dữ liệu Isar
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();
    final provider = (settings.ttsProvider == 'microsoft_edge') 
        ? 'microsoft_edge' 
        : (settings.ttsProvider == 'supertonic' ? 'supertonic' : 'system');
    
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.pause,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
      },
      androidCompactActionIndices: const [0, 1, 2],
      playing: true,
      processingState: AudioProcessingState.ready,
    ));

    if (provider == 'supertonic') {
      _activeEngine = TtsEngineType.supertonic;
      try {
        final supertonic = SupertonicService.getInstance();
        final voiceName = settings.selectedVoiceName ?? 'M1';
        
        // Đảm bảo Engine offline đã được khởi tạo
        await supertonic.initializeEngine(voiceStyle: voiceName);
        
        // Sinh WAV offline
        final wavPath = await supertonic.synthesizeToWav(text, speed: _speechRate * 2.0);
        
        if (wavPath != null) {
          _isSpeaking = true;
          await _edgePlayer.play(DeviceFileSource(wavPath));
          await _edgePlayer.setPlaybackRate(1.0); // Supertonic WAV đã có tốc độ nhúng sẵn, phát tốc độ chuẩn 1.0
        } else {
          throw Exception("Offline WAV generation failed");
        }
      } catch (e) {
        debugPrint("Supertonic offline TTS failed, falling back to System TTS: $e");
        _activeEngine = TtsEngineType.system;
        _isSpeaking = true;
        if (Platform.isWindows) {
          await _tts.speak(text);
          _startWindowsCompletionTimer(text);
        } else {
          await _tts.speak(text);
        }
      }
    } else if (provider == 'microsoft_edge' || (provider == 'system' && Platform.isWindows)) {
      _activeEngine = (provider == 'microsoft_edge') ? TtsEngineType.edge : TtsEngineType.system;
      
      String voice = settings.selectedVoiceName ?? (provider == 'microsoft_edge' ? "vi-VN-HoaiMyNeural" : "default");
      if (provider == 'system' && (voice.contains('Neural') || voice.split('-').length > 2)) {
        voice = "default";
      }
      final rate = _speechRate;
      final cacheKey = _computeSha256("$text|$voice|$rate");
      
      cancelOtherPrefetches(cacheKey);
      _edgeMetadata.clear();
      
      try {
        CachedAudio? cached;
        if (_audioCache.containsKey(cacheKey)) {
          cached = _audioCache[cacheKey];
        } else if (_pendingPrefetches.containsKey(cacheKey)) {
          cached = await _pendingPrefetches[cacheKey];
        }

        if (cached == null) {
          if (provider == 'microsoft_edge') {
            final audioBytes = <int>[];
            final completer = Completer<void>();
            
            final stream = EdgeTtsService.synthesize(
              text: text,
              voice: voice,
            );

            final subscription = stream.listen(
              (chunk) {
                if (chunk is EdgeAudioChunk) {
                  audioBytes.addAll(chunk.data);
                } else if (chunk is EdgeMetadataChunk) {
                  _edgeMetadata.add(chunk);
                }
              },
              onError: (err) {
                debugPrint("MyAudioHandler.speak: Stream error occurred: $err");
                completer.completeError(err);
              },
              onDone: () {
                completer.complete();
              },
              cancelOnError: true,
            );

            try {
              await completer.future;
            } catch (e) {
              subscription.cancel();
              rethrow;
            }
            
            if (audioBytes.isEmpty) {
              throw Exception("No audio bytes received from Microsoft Edge TTS");
            }
            
            final tempDir = await getTemporaryDirectory();
            final file = File('${tempDir.path}/tts_$cacheKey.mp3');
            await file.writeAsBytes(audioBytes, flush: true);
            cached = CachedAudio(file.path, List.from(_edgeMetadata));
            _addToCache(cacheKey, cached);
          } else {
            // Windows System TTS: sinh file wav qua PowerShell
            final filePath = await _synthesizeSystemTtsToWavWindows(text, voice, rate);
            cached = CachedAudio(filePath, []);
            _addToCache(cacheKey, cached);
          }
        } else {
          _edgeMetadata.addAll(cached.metadata);
        }
        
        // Bắt đầu phát âm thanh bằng audioplayers
        _isSpeaking = true;
        await _edgePlayer.play(DeviceFileSource(cached.filePath));
        await _edgePlayer.setPlaybackRate(_speechRate * 2.0); // Quy đổi 0.5 -> 1.0x tốc độ chuẩn
        
      } catch (e) {
        debugPrint("TTS engine failed, falling back to direct System TTS: $e");
        
        // HỆ THỐNG FALLBACK AN TOÀN: Chuyển về System TTS cùng ngôn ngữ
        _activeEngine = TtsEngineType.system;
        _isSpeaking = true;

        // Tìm giọng System TTS cùng locale với Edge TTS voice đang dùng
        String? matchedVoiceName;
        try {
          final localeParts = voice.split('-');
          if (localeParts.length >= 2) {
            final targetLocale = '${localeParts[0]}-${localeParts[1]}';
            final systemVoices = await _tts.getVoices as List;
            dynamic matchedVoice;
            for (final v in systemVoices) {
              final voiceLocale = v['locale']?.toString() ?? '';
              if (voiceLocale.toLowerCase().startsWith(targetLocale.toLowerCase())) {
                matchedVoice = v;
                break;
              }
            }
            if (matchedVoice != null) {
              matchedVoiceName = matchedVoice['name'].toString();
              await _tts.setVoice({
                'name': matchedVoiceName,
                'locale': matchedVoice['locale'].toString(),
              });
              debugPrint("Edge TTS fallback: using system voice '$matchedVoiceName' (${matchedVoice['locale']})");
            } else {
              debugPrint("Edge TTS fallback: no system voice found for locale '$targetLocale', using default");
            }
          }
        } catch (voiceErr) {
          debugPrint("Edge TTS fallback: failed to set matching system voice: $voiceErr");
        }

        if (Platform.isWindows) {
          await _tts.speak(text);
          _startWindowsCompletionTimer(text);
        } else {
          await _tts.speak(text);
        }
      }
    } else {
      // Luồng chạy mặc định sử dụng System TTS trên Mobile
      _activeEngine = TtsEngineType.system;
      _isSpeaking = true;
      await _tts.speak(text);
    }
  }

  @override
  Future<void> play() async {
    BgmService.getInstance().resumeBgm();
    if (!_isSpeaking && _currentText.isNotEmpty) {
      if (_activeEngine == TtsEngineType.edge || _activeEngine == TtsEngineType.supertonic || (Platform.isWindows && _activeEngine == TtsEngineType.system)) {
        _isSpeaking = true;
        playbackState.add(playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            MediaControl.pause,
            MediaControl.skipToNext,
          ],
          playing: true,
          processingState: AudioProcessingState.ready,
        ));
        await _edgePlayer.resume();
      } else {
        await speak(_currentText);
      }
    }
  }

  @override
  Future<void> pause() async {
    BgmService.getInstance().pauseBgm();
    _isSpeaking = false;
    _windowsTimer?.cancel();
    cancelAllPrefetches();
    
    if (_activeEngine == TtsEngineType.edge || _activeEngine == TtsEngineType.supertonic || (Platform.isWindows && _activeEngine == TtsEngineType.system)) {
      await _edgePlayer.pause();
    } else {
      await _tts.stop();
    }
    
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.skipToNext,
      ],
      playing: false,
      processingState: AudioProcessingState.ready,
    ));
  }

  @override
  Future<void> stop() async {
    BgmService.getInstance().stopBgm();
    _isSpeaking = false;
    _windowsTimer?.cancel();
    cancelAllPrefetches();
    
    if (_activeEngine == TtsEngineType.edge || _activeEngine == TtsEngineType.supertonic || (Platform.isWindows && _activeEngine == TtsEngineType.system)) {
      await _edgePlayer.stop();
    } else {
      await _tts.stop();
    }
    
    playbackState.add(playbackState.value.copyWith(
      controls: [],
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
  }

  @override
  Future<void> setSpeed(double speed) async {
    _speechRate = speed;
    await _tts.setSpeechRate(speed);
    if (_activeEngine == TtsEngineType.edge || _activeEngine == TtsEngineType.supertonic || (Platform.isWindows && _activeEngine == TtsEngineType.system)) {
      await _edgePlayer.setPlaybackRate(speed * 2.0);
    }
  }

  Future<void> setPitch(double pitch) async {
    await _tts.setPitch(pitch);
  }

  Future<void> setVoice(Map<String, String> voice) async {
    await _tts.setVoice(voice);
  }

  Future<List<dynamic>> getVoices() async {
    return await _tts.getVoices;
  }

  Future<void> cleanUp() async {
    await _positionSub?.cancel();
    await _completeSub?.cancel();
    cancelAllPrefetches();
    for (final item in _audioCache.values) {
      try {
        final file = File(item.filePath);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (_) {}
    }
    _audioCache.clear();
    await _edgePlayer.dispose();
  }

  Future<void> _cleanOldCacheFiles() async {
    try {
      final cacheDir = await PathHelper.getAppCacheDirectory();
      if (await cacheDir.exists()) {
        final now = DateTime.now();
        final files = cacheDir.listSync();
        for (final file in files) {
          if (file is File) {
            final fileName = p.basename(file.path);
            if (fileName.startsWith('sys_tts_') ||
                fileName.startsWith('sys_text_') ||
                fileName.startsWith('sys_synth_') ||
                fileName.startsWith('tts_')) {
              final stat = await file.stat();
              if (now.difference(stat.modified).inDays >= 1) {
                try {
                  await file.delete();
                } catch (_) {}
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Failed to clean old cache files: $e");
    }
  }
}
