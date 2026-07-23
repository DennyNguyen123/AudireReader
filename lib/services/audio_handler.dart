import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:path/path.dart' as p;
import '../core/utils/path_helper.dart';
import 'dart:async';
import 'dart:io' show Platform, File, Process;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../core/database/database_helper.dart';
import 'edge_tts_service.dart';
import 'supertonic_service.dart';
import 'openai_tts_service.dart';
import 'bgm_service.dart';

enum TtsEngineType { system, edge, supertonic, openai }

class CachedAudio {
  final String? filePath;
  final List<EdgeMetadataChunk> metadata;
  CachedAudio({this.filePath, required this.metadata});
}

class MyAudioHandler extends BaseAudioHandler with QueueHandler {
  final FlutterTts _tts = FlutterTts();
  final ja.AudioPlayer _edgePlayer = ja.AudioPlayer();
  
  // Callback báo từ đang đọc về UI để highlight
  Function(String text, int start, int end, String word)? onWordProgress;
  
  // Callback báo khi đọc xong đoạn văn để chuyển sang đoạn tiếp theo
  Function()? onParagraphComplete;

  Function()? onSkipToNext;
  Function()? onSkipToPrevious;
  Function(int index)? onSeekToParagraph;

  List<String> _currentParagraphs = [];
  double _paragraphStartPosInChapter = 0.0;
  double _charPerSecond = 15.0;

  bool _isSpeaking = false;
  bool _isSystemTtsPaused = false; // Track trạng thái pause riêng cho System TTS native
  String _currentText = "";
  double _speechRate = 0.5; // Tốc độ nói hiện tại của TTS (0.5 tương đương 1.0x)
  Timer? _windowsTimer; // Timer giả lập hoàn thành trên Windows

  // Vị trí hiện tại được đồng bộ từ UI
  String _currentBookUuid = "";
  String _currentBookTitle = "";
  String _currentChapterTitle = "";
  int _currentChapterIndex = 0;
  int _currentParagraphIndex = 0;

  void setActiveContext({required String bookUuid, required int chapterIndex}) {
    _currentBookUuid = bookUuid;
    _currentChapterIndex = chapterIndex;
  }

  // Vị trí thực tế của đoạn âm thanh đang phát dở
  String _playingBookTitle = "";
  String _playingChapterTitle = "";
  int _playingParagraphIndex = -1;

  TtsEngineType _activeEngine = TtsEngineType.system;
  final List<EdgeMetadataChunk> _edgeMetadata = [];
  int _lastHighlightIndex = 0;
  String _lastWord = "";
  int _systemTtsCharacterOffset = 0;
  int _systemTtsResumeOffset = 0;

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
          final file = File(oldestItem.filePath!);
          if (file.existsSync()) {
            file.deleteSync();
          }
        } catch (e) {
          debugPrint("Failed to delete cached audio file: $e");
        }
      }
    }
  }

  Future<String> _synthesizeOpenAiToAudio(String text, String voiceName, double rate) async {
    return await OpenAiTtsService.synthesizeToWav(text, voiceName, rate);
  }

  Future<String> _synthesizeSupertonicToWav(String text, String voiceStyle, double rate) async {
    final supertonic = SupertonicService.getInstance();
    await supertonic.initializeEngine(voiceStyle: voiceStyle);
    
    // Nhận diện ngôn ngữ động của văn bản
    final detectedLang = supertonic.detectLanguage(text);
    
    final wavPath = await supertonic.synthesizeToWav(
      text,
      speed: rate * 2.0,
      lang: detectedLang,
    );
    if (wavPath == null) {
      throw Exception("Supertonic offline synthesis returned null");
    }
    return wavPath;
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
    
    if (provider == 'supertonic') {
      _synthesizeSupertonicToWav(text, voice, rate).then((filePath) {
        final cached = CachedAudio(filePath: filePath, metadata: []);
        _addToCache(cacheKey, cached);
        _pendingPrefetches.remove(cacheKey);
        completer.complete(cached);
      }).catchError((err) {
        _pendingPrefetches.remove(cacheKey);
        completer.completeError(err);
      });
    } else if (provider == 'system' && Platform.isWindows) {
      // System TTS trên Windows: kết xuất bằng PowerShell ngầm
      _synthesizeSystemTtsToWavWindows(text, voice, rate).then((filePath) {
        final cached = CachedAudio(filePath: filePath, metadata: []);
        _addToCache(cacheKey, cached);
        _pendingPrefetches.remove(cacheKey);
        completer.complete(cached);
      }).catchError((err) {
        _pendingPrefetches.remove(cacheKey);
        completer.completeError(err);
      });
    } else if (provider == 'openai') {
      _synthesizeOpenAiToAudio(text, voice, rate).then((filePath) {
        final cached = CachedAudio(filePath: filePath, metadata: []);
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
            if (!completer.isCompleted) completer.completeError(err);
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
              
              final cached = CachedAudio(filePath: file.path, metadata: metadata);
              _addToCache(cacheKey, cached);
              _pendingPrefetches.remove(cacheKey);
              if (!completer.isCompleted) completer.complete(cached);
            } catch (e) {
              _pendingPrefetches.remove(cacheKey);
              if (!completer.isCompleted) completer.completeError(e);
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
    final provider = (settings.ttsProvider == 'microsoft_edge') 
        ? 'microsoft_edge' 
        : (settings.ttsProvider == 'supertonic' 
            ? 'supertonic' 
            : (settings.ttsProvider == 'openai' ? 'openai' : 'system'));
    
    // Chỉ prefetch cho Edge TTS, Supertonic, OpenAI HOẶC System TTS trên Windows
    if (provider != 'microsoft_edge' && provider != 'supertonic' && provider != 'openai' && !(provider == 'system' && Platform.isWindows)) return;
    
    String voice = settings.selectedVoiceName ?? 
        (provider == 'microsoft_edge' 
            ? "vi-VN-HoaiMyNeural" 
            : (provider == 'supertonic' ? "M1" : "default"));
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
      
      final absoluteStart = start + _systemTtsResumeOffset;
      final absoluteEnd = end + _systemTtsResumeOffset;
      
      _systemTtsCharacterOffset = absoluteStart;
      onWordProgress?.call(_currentText, absoluteStart, absoluteEnd, word);

      if (_charPerSecond > 0) {
        final positionInParagraph = absoluteStart / _charPerSecond;
        final currentChapterPos = _paragraphStartPosInChapter + positionInParagraph;
        playbackState.add(playbackState.value.copyWith(
          updatePosition: Duration(milliseconds: (currentChapterPos * 1000).round()),
        ));
      }
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
      // Delay 100ms để Native TTS nhả hoàn toàn AudioSession và tránh kẹt trên iOS
      Future.delayed(const Duration(milliseconds: 100), () {
        onParagraphComplete?.call();
      });
    });

    _tts.setErrorHandler((msg) {
      if (_activeEngine != TtsEngineType.system) return;
      _isSpeaking = false;
      _isSystemTtsPaused = false;
      _windowsTimer?.cancel();
      playbackState.add(playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.error,
      ));
    });

    // Callback khi TTS thực sự pause (Android SDK >= 26, iOS, Web)
    _tts.setPauseHandler(() {
      if (_activeEngine != TtsEngineType.system) return;
      _isSystemTtsPaused = true;
      _isSpeaking = false;
    });

    // Callback khi TTS tiếp tục sau pause
    _tts.setContinueHandler(() {
      if (_activeEngine != TtsEngineType.system) return;
      _isSystemTtsPaused = false;
      _isSpeaking = true;
    });
  }

  void _initEdgePlayer() {
    _positionSub = _edgePlayer.positionStream.listen((duration) {
      if (_activeEngine != TtsEngineType.edge || !_isSpeaking) return;

      final positionInParagraph = duration.inMilliseconds / 1000.0;
      final currentChapterPos = _paragraphStartPosInChapter + positionInParagraph;

      playbackState.add(playbackState.value.copyWith(
        updatePosition: Duration(milliseconds: (currentChapterPos * 1000).round()),
      ));

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

    _completeSub = _edgePlayer.playerStateStream.listen((state) {
      if ((_activeEngine != TtsEngineType.edge && _activeEngine != TtsEngineType.supertonic && _activeEngine != TtsEngineType.openai && !(Platform.isWindows && _activeEngine == TtsEngineType.system)) || !_isSpeaking) return;

      if (state.processingState == ja.ProcessingState.completed) {
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
    String? coverPath,
    double? chapterDuration,
    double? chapterPosition,
  }) async {
    _currentBookTitle = bookTitle;
    _currentChapterTitle = chapterTitle;
    _currentParagraphIndex = paragraphIndex;

    Uri? artUri;
    if (coverPath != null && coverPath.isNotEmpty) {
      if (coverPath.startsWith('http://') || coverPath.startsWith('https://')) {
        artUri = Uri.parse(coverPath);
      } else {
        artUri = Uri.file(coverPath);
      }
    }

    final duration = chapterDuration != null 
        ? Duration(milliseconds: (chapterDuration * 1000).round())
        : Duration(seconds: totalParagraphs);

    mediaItem.add(MediaItem(
      id: 'tts_paragraph_$paragraphIndex',
      album: bookTitle,
      title: chapterTitle,
      artist: 'Audire Reader',
      duration: duration,
      artUri: artUri,
    ));

    if (chapterPosition != null) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: Duration(milliseconds: (chapterPosition * 1000).round()),
      ));
    }
  }

  Future<void> speak(String text) async {
    _playingBookTitle = _currentBookTitle;
    _playingChapterTitle = _currentChapterTitle;
    _playingParagraphIndex = _currentParagraphIndex;

    // Gọi resume nhạc nền nếu được bật
    BgmService.getInstance().resumeBgm();
    
    // Lưu lại trạng thái của Native TTS trước khi reset
    bool wasNativeTtsActive = _isSpeaking || _isSystemTtsPaused;

    // 1. Dừng mọi tác vụ phát cũ một cách an toàn và tuần tự
    _isSpeaking = false;
    _isSystemTtsPaused = false;
    _windowsTimer?.cancel();
    
    if (wasNativeTtsActive) {
      await _tts.stop();
    }
    await _edgePlayer.stop();
    
    if (wasNativeTtsActive && !Platform.isWindows) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    _currentText = text;
    _lastHighlightIndex = 0;
    _lastWord = "";
    _systemTtsCharacterOffset = 0;
    _systemTtsResumeOffset = 0;
    
    // Kiểm tra xem có file TTS Offline cục bộ cho đoạn văn này không
    if (_currentBookUuid.isNotEmpty) {
      try {
        final appDir = await PathHelper.getAppDirectory();
        final offlineAudioFile = File('${appDir.path}/tts_offline/$_currentBookUuid/ch_$_currentChapterIndex/p_$_currentParagraphIndex.wav');
        final offlineMetaFile = File('${appDir.path}/tts_offline/$_currentBookUuid/ch_$_currentChapterIndex/p_$_currentParagraphIndex.json');

        if (offlineAudioFile.existsSync() && offlineAudioFile.lengthSync() > 0) {
          debugPrint('[AudioHandler] Playing from OFFLINE TTS file: ${offlineAudioFile.path}');
          _activeEngine = TtsEngineType.edge;
          _edgeMetadata.clear();

          if (offlineMetaFile.existsSync()) {
            try {
              final jsonStr = await offlineMetaFile.readAsString();
              final List<dynamic> jsonList = jsonDecode(jsonStr);
              for (final item in jsonList) {
                _edgeMetadata.add(EdgeMetadataChunk(
                  type: item['type']?.toString() ?? 'word',
                  offset: (item['offset'] as num?)?.toInt() ?? 0,
                  duration: (item['duration'] as num?)?.toInt() ?? 0,
                  text: item['text']?.toString() ?? '',
                ));
              }
            } catch (e) {
              debugPrint("Failed to parse offline metadata JSON: $e");
            }
          }

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

          _isSpeaking = true;
          await _edgePlayer.setAudioSource(ja.AudioSource.uri(Uri.file(offlineAudioFile.path)));
          _edgePlayer.play();
          await _edgePlayer.setSpeed(_speechRate * 2.0);
          return;
        }
      } catch (e) {
        debugPrint('[AudioHandler] Failed to load offline TTS file, falling back to online: $e');
      }
    }

    // 2. Đọc cấu hình nhà cung cấp từ cơ sở dữ liệu Isar
    final db = await DatabaseHelper.getInstance();
    final settings = await db.getSettings();
    final provider = (settings.ttsProvider == 'microsoft_edge') 
        ? 'microsoft_edge' 
        : (settings.ttsProvider == 'supertonic' 
            ? 'supertonic' 
            : (settings.ttsProvider == 'openai' ? 'openai' : 'system'));
    
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

    print("--- [AudioHandler] speak() called. provider: $provider, text: ${text.substring(0, text.length > 20 ? 20 : text.length)} ---");

    if (provider == 'microsoft_edge' || provider == 'supertonic' || provider == 'openai' || (provider == 'system' && Platform.isWindows)) {
      _activeEngine = (provider == 'microsoft_edge') 
          ? TtsEngineType.edge 
          : (provider == 'supertonic' ? TtsEngineType.supertonic : (provider == 'openai' ? TtsEngineType.openai : TtsEngineType.system));

      
      String voice = settings.selectedVoiceName ?? 
          (provider == 'microsoft_edge' 
              ? "vi-VN-HoaiMyNeural" 
              : (provider == 'supertonic' ? "M1" : (provider == 'openai' ? "Alloy" : "default")));
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
            cached = await prefetchSingle(text, voice, rate, provider);
          } else if (provider == 'supertonic') {
            // Sinh file wav qua Supertonic
            final filePath = await _synthesizeSupertonicToWav(text, voice, rate);
            cached = CachedAudio(filePath: filePath, metadata: []);
            _addToCache(cacheKey, cached);
          } else if (provider == 'openai') {
            // Sinh file mp3 qua OpenAI TTS
            final filePath = await _synthesizeOpenAiToAudio(text, voice, rate);
            cached = CachedAudio(filePath: filePath, metadata: []);
            _addToCache(cacheKey, cached);
          } else {
            // Windows System TTS: sinh file wav qua PowerShell
            final filePath = await _synthesizeSystemTtsToWavWindows(text, voice, rate);
            cached = CachedAudio(filePath: filePath, metadata: []);
            _addToCache(cacheKey, cached);
          }
        }

        if (cached == null || cached.filePath == null) {
          throw Exception("Failed to obtain synthesized audio file path");
        }

        _edgeMetadata.addAll(cached.metadata);
        
        // Bắt đầu phát âm thanh
        _isSpeaking = true;
        await _edgePlayer.setAudioSource(ja.AudioSource.uri(Uri.file(cached.filePath!)));
        _edgePlayer.play();
        if (provider == 'supertonic') {
          await _edgePlayer.setSpeed(1.0); // Supertonic WAV đã có tốc độ nhúng sẵn, phát tốc độ chuẩn 1.0
        } else {
          await _edgePlayer.setSpeed(_speechRate * 2.0); // Quy đổi 0.5 -> 1.0x tốc độ chuẩn
        }
        
      } catch (e) {
        debugPrint("TTS engine failed, falling back to System TTS: $e");
        
        if (Platform.isWindows) {
          await _speakSystemFallback(text);
        } else {
          // HỆ THỐNG FALLBACK AN TOÀN trên Mobile: Chuyển về System TTS cùng ngôn ngữ
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

    final isPositionChanged = _currentBookTitle != _playingBookTitle ||
                              _currentChapterTitle != _playingChapterTitle ||
                              _currentParagraphIndex != _playingParagraphIndex;

    if (isPositionChanged) {
      if (_currentParagraphIndex >= 0 && _currentParagraphIndex < _currentParagraphs.length) {
        final textToSpeak = _currentParagraphs[_currentParagraphIndex];
        await speak(textToSpeak);
      }
      return;
    }

    if (!_isSpeaking && _currentText.isNotEmpty) {
      if (_activeEngine == TtsEngineType.edge || _activeEngine == TtsEngineType.supertonic || _activeEngine == TtsEngineType.openai || (Platform.isWindows && _activeEngine == TtsEngineType.system)) {
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
        await _edgePlayer.play();
      } else if (_isSystemTtsPaused) {
        _isSystemTtsPaused = false;
        
        // Cần gọi stop() để xoá trạng thái pause của iOS Native TTS trước khi phát tiếp
        // Đảm bảo _isSpeaking = false khi gọi stop() để tránh kích hoạt completionHandler của flutter_tts
        await _tts.stop();
        if (!Platform.isWindows) {
          await Future.delayed(const Duration(milliseconds: 50));
        }

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
        
        _systemTtsResumeOffset = _systemTtsCharacterOffset;
        if (_systemTtsResumeOffset < _currentText.length) {
          final textToSpeak = _currentText.substring(_systemTtsResumeOffset);
          await _tts.speak(textToSpeak);
        } else {
          _isSpeaking = false;
          playbackState.add(playbackState.value.copyWith(
            processingState: AudioProcessingState.completed,
          ));
          onParagraphComplete?.call();
        }
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
    
    if (_activeEngine == TtsEngineType.edge || _activeEngine == TtsEngineType.supertonic || _activeEngine == TtsEngineType.openai || (Platform.isWindows && _activeEngine == TtsEngineType.system)) {
      await _edgePlayer.pause();
    } else {
      // Sử dụng _tts.pause() thay vì _tts.stop() để giữ vị trí phát
      // Hỗ trợ Android (SDK >= 26), iOS, Web
      await _tts.pause();
      _isSystemTtsPaused = true;
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
    _isSystemTtsPaused = false;
    _windowsTimer?.cancel();
    cancelAllPrefetches();
    
    if (_activeEngine == TtsEngineType.edge || _activeEngine == TtsEngineType.supertonic || _activeEngine == TtsEngineType.openai || (Platform.isWindows && _activeEngine == TtsEngineType.system)) {
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
    if (_activeEngine == TtsEngineType.edge || _activeEngine == TtsEngineType.supertonic || _activeEngine == TtsEngineType.openai || (Platform.isWindows && _activeEngine == TtsEngineType.system)) {
      await _edgePlayer.setSpeed(speed * 2.0);
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
        if (item.filePath == null) continue; final file = File(item.filePath!);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (_) {}
    }
    _audioCache.clear();
    await _edgePlayer.dispose();
  }

  Future<void> _speakSystemFallback(String text) async {
    _activeEngine = TtsEngineType.system;
    if (Platform.isWindows) {
      try {
        final db = await DatabaseHelper.getInstance();
        final settings = await db.getSettings();
        String voice = settings.selectedVoiceName ?? "default";
        if (voice.contains('Neural') || voice.split('-').length > 2) {
          voice = "default";
        }
        final rate = _speechRate;
        final cacheKey = _computeSha256("$text|$voice|$rate");
        
        CachedAudio? cached;
        if (_audioCache.containsKey(cacheKey)) {
          cached = _audioCache[cacheKey];
        } else if (_pendingPrefetches.containsKey(cacheKey)) {
          cached = await _pendingPrefetches[cacheKey];
        }

        if (cached == null) {
          final filePath = await _synthesizeSystemTtsToWavWindows(text, voice, rate);
          cached = CachedAudio(filePath: filePath, metadata: []);
          _addToCache(cacheKey, cached);
        }
        
        _isSpeaking = true;
        await _edgePlayer.setAudioSource(ja.AudioSource.uri(Uri.file(cached.filePath!)));
        _edgePlayer.play();
        await _edgePlayer.setSpeed(_speechRate * 2.0);
      } catch (err) {
        debugPrint("System TTS fallback via PowerShell failed: $err");
        _isSpeaking = true;
        await _tts.speak(text);
        _startWindowsCompletionTimer(text);
      }
    } else {
      _isSpeaking = true;
      _isSystemTtsPaused = false;
      await _tts.speak(text);
    }
  }

  void setChapterData(List<String> paragraphs, double duration, double startPos, double charPerSecond) {
    _currentParagraphs = paragraphs;
    _paragraphStartPosInChapter = startPos;
    _charPerSecond = charPerSecond;
  }

  @override
  Future<void> seek(Duration position) async {
    final targetSec = position.inSeconds.toDouble();
    if (_currentParagraphs.isEmpty || _charPerSecond <= 0) return;
    
    double total = 0.0;
    int targetParagraphIndex = 0;
    
    for (int i = 0; i < _currentParagraphs.length; i++) {
      final pDur = _currentParagraphs[i].length / _charPerSecond;
      if (targetSec <= total + pDur) {
        targetParagraphIndex = i;
        break;
      }
      total += pDur;
      targetParagraphIndex = i;
    }
    
    onSeekToParagraph?.call(targetParagraphIndex);
  }

  @override
  Future<void> skipToNext() async {
    onSkipToNext?.call();
  }

  @override
  Future<void> skipToPrevious() async {
    onSkipToPrevious?.call();
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
