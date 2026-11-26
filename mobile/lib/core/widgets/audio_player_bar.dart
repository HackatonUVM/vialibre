import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/vialibre_theme.dart';
import '../media/audio_service.dart';
import 'tactile_press.dart';

/// Control cálido y accesible para escuchar resúmenes o guías en voz clara (0.8x / 1.0x),
/// adaptable a Modo Claro / Oscuro con respaldo TTS local (`fallbackText`).
class AudioPlayerBar extends ConsumerStatefulWidget {
  const AudioPlayerBar({
    required this.title,
    this.base64Wav,
    this.audioUrl,
    this.fallbackText,
    this.onRequestAudio,
    super.key,
  });

  final String title;
  final String? base64Wav;
  final String? audioUrl;
  final String? fallbackText;
  final Future<void> Function()? onRequestAudio;

  @override
  ConsumerState<AudioPlayerBar> createState() => _AudioPlayerBarState();
}

class _AudioPlayerBarState extends ConsumerState<AudioPlayerBar> {
  double _rate = 1.0;
  bool _loading = false;

  Future<void> _togglePlay() async {
    final audio = ref.read(audioServiceProvider);
    if (widget.base64Wav != null && widget.base64Wav!.isNotEmpty) {
      await audio.playBase64Wav(widget.base64Wav!, rate: _rate);
      return;
    }
    if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
      await audio.playAudioUrl(widget.audioUrl!, rate: _rate);
      return;
    }

    if (widget.onRequestAudio != null) {
      setState(() => _loading = true);
      try {
        await widget.onRequestAudio!();
      } finally {
        if (mounted) setState(() => _loading = false);
      }
      return;
    }

    if (widget.fallbackText != null && widget.fallbackText!.trim().isNotEmpty) {
      await audio.speakLocal(widget.fallbackText!, rate: _rate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ViaLibreTheme.paletteOf(context);
    final audio = ref.read(audioServiceProvider);
    final hasRemoteAudio =
        (widget.base64Wav != null && widget.base64Wav!.isNotEmpty) ||
            (widget.audioUrl != null && widget.audioUrl!.isNotEmpty);
    final hasAnySource = hasRemoteAudio ||
        widget.onRequestAudio != null ||
        (widget.fallbackText != null && widget.fallbackText!.trim().isNotEmpty);

    return ValueListenableBuilder<bool>(
      valueListenable: audio.isSpeakingLocal,
      builder: (context, speakingLocal, _) {
        return StreamBuilder<PlayerState>(
          stream: audio.playerStateStream,
          builder: (context, snapshot) {
            final isPlaying =
                snapshot.data == PlayerState.playing || speakingLocal;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: p.sand,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: p.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: p.lavender,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.volume_up_rounded,
                          color: p.lavenderInk,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                color: p.ink,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              hasRemoteAudio
                                  ? 'Audio Gemini listo para escuchar'
                                  : (hasAnySource
                                      ? 'Lectura en voz clara disponible'
                                      : 'Sin texto disponible'),
                              style: TextStyle(
                                color: p.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TactilePress(
                          borderRadius: 24,
                          onTap: (_loading || !hasAnySource)
                              ? null
                              : () => isPlaying
                                  ? audio.stopPlayback()
                                  : _togglePlay(),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 48),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: hasAnySource ? p.coral : p.border,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_loading)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                else
                                  Icon(
                                    isPlaying
                                        ? Icons.stop_rounded
                                        : Icons.play_arrow_rounded,
                                    color:
                                        hasAnySource ? Colors.white : p.muted,
                                  ),
                                const SizedBox(width: 8),
                                Text(
                                  isPlaying
                                      ? 'Detener voz'
                                      : 'Escuchar en voz clara',
                                  style: TextStyle(
                                    color:
                                        hasAnySource ? Colors.white : p.muted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () async {
                          final nextRate = _rate == 1.0 ? 0.8 : 1.0;
                          setState(() => _rate = nextRate);
                          await audio.setPlaybackRate(nextRate);
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: p.card,
                          minimumSize: const Size(64, 48),
                        ),
                        child: Text(
                          '${_rate}x',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
