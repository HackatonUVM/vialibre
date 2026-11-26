import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Gestiona grabación de notas de voz breves, reproducción WAV remota (Gemini TTS)
/// y síntesis de voz local en español (`flutter_tts`) como respaldo inmediato.
class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  final ValueNotifier<bool> isSpeakingLocal = ValueNotifier<bool>(false);
  bool _ttsInitialized = false;

  Future<void> _ensureTtsInitialized() async {
    if (_ttsInitialized) return;
    _ttsInitialized = true;
    try {
      await _tts.setLanguage('es-MX');
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      _tts.setStartHandler(() => isSpeakingLocal.value = true);
      _tts.setCompletionHandler(() => isSpeakingLocal.value = false);
      _tts.setCancelHandler(() => isSpeakingLocal.value = false);
      _tts.setErrorHandler((_) => isSpeakingLocal.value = false);
    } catch (_) {
      // En entornos de prueba unitaria no hay canal nativo TTS.
    }
  }

  Future<bool> hasMicPermission() => _recorder.hasPermission();

  Future<String?> startVoiceRecording() async {
    final allowed = await _recorder.hasPermission();
    if (!allowed) return null;

    final dir = await getTemporaryDirectory();
    final outPath = p.join(
      dir.path,
      'report_voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
      path: outPath,
    );
    return outPath;
  }

  Future<String?> stopVoiceRecording() => _recorder.stop();

  Future<void> discardTempFile(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> playBase64Wav(String base64Wav, {double rate = 1.0}) async {
    await stopPlayback();
    final bytes = base64Decode(base64Wav);
    await _player.setPlaybackRate(rate);
    await _player.play(BytesSource(bytes));
  }

  Future<void> playAudioUrl(String url, {double rate = 1.0}) async {
    await stopPlayback();
    await _player.setPlaybackRate(rate);
    await _player.play(UrlSource(url));
  }

  Future<void> speakLocal(String text, {double rate = 1.0}) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;
    await stopPlayback();
    await _ensureTtsInitialized();
    // Android TTS toma 0.5 como velocidad natural aproximada.
    final nativeRate = (rate * 0.52).clamp(0.32, 0.9);
    try {
      await _tts.setSpeechRate(nativeRate);
      isSpeakingLocal.value = true;
      await _tts.speak(cleaned);
    } catch (_) {
      isSpeakingLocal.value = false;
    }
  }

  Future<void> setPlaybackRate(double rate) async {
    try {
      await _player.setPlaybackRate(rate);
      if (_ttsInitialized) {
        await _tts.setSpeechRate((rate * 0.52).clamp(0.32, 0.9));
      }
    } catch (_) {}
  }

  Future<void> stopPlayback() async {
    isSpeakingLocal.value = false;
    try {
      await _player.stop();
    } catch (_) {}
    try {
      if (_ttsInitialized) {
        await _tts.stop();
      }
    } catch (_) {}
  }

  Stream<PlayerState> get playerStateStream => _player.onPlayerStateChanged;

  void dispose() {
    _recorder.dispose();
    _player.dispose();
    if (_ttsInitialized) {
      _tts.stop();
    }
    isSpeakingLocal.dispose();
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(service.dispose);
  return service;
});
