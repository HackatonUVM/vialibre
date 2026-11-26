import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vialibre/app/theme/vialibre_theme.dart';
import 'package:vialibre/core/media/audio_service.dart';
import 'package:vialibre/core/widgets/accessible_button.dart';
import 'package:vialibre/core/widgets/tactile_press.dart';
import 'package:vialibre/features/explore/presentation/explore_screen.dart';
import 'package:vialibre/features/profile/data/profile_prefs_repo.dart';
import '../data/assistant_repo.dart';

class _ChatMessage {
  const _ChatMessage({
    required this.isUser,
    required this.text,
    this.reply,
  });

  final bool isUser;
  final String text;
  final CopilotReply? reply;
}

/// Asistente conversacional "Pregúntale a VíaLibre" adaptable a Modo Claro/Oscuro.
class CopilotSheet extends ConsumerStatefulWidget {
  const CopilotSheet({
    required this.onOpenFirstTimerGuide,
    super.key,
  });

  final VoidCallback onOpenFirstTimerGuide;

  @override
  ConsumerState<CopilotSheet> createState() => _CopilotSheetState();
}

class _CopilotSheetState extends ConsumerState<CopilotSheet> {
  final TextEditingController _ctrl = TextEditingController();
  final List<_ChatMessage> _messages = <_ChatMessage>[
    const _ChatMessage(
      isUser: false,
      text:
          'Hola, soy el asistente de VíaLibre. Pregúntame cómo llegar sin escalones, cómo usar Metro o Metrobús por primera vez o qué hacer ante un obstáculo.',
    ),
  ];

  bool _loading = false;
  bool _recording = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String rawText, {File? voiceFile}) async {
    final text = rawText.trim();
    if (text.isEmpty && voiceFile == null) return;

    final display = voiceFile != null ? 'Nota de voz enviada' : text;
    _ctrl.clear();

    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: display));
      _loading = true;
    });

    final profile =
        ref.read(profileControllerProvider).valueOrNull?.profile.keyName ??
            'wheelchair';

    final reply = await ref.read(assistantRepoProvider).askCopilot(
          message: text.isNotEmpty
              ? text
              : 'Ayúdame con movilidad accesible según mi nota de voz.',
          profile: profile,
          lat: 19.4326,
          lng: -99.1332,
          voiceFile: voiceFile,
        );

    if (voiceFile != null) {
      await ref.read(audioServiceProvider).discardTempFile(voiceFile.path);
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _messages.add(
        _ChatMessage(isUser: false, text: reply.replyText, reply: reply),
      );
    });
  }

  Future<void> _toggleVoice() async {
    final audio = ref.read(audioServiceProvider);
    if (_recording) {
      final path = await audio.stopVoiceRecording();
      if (!mounted) return;
      setState(() => _recording = false);
      if (path != null) {
        await _sendMessage('', voiceFile: File(path));
      }
      return;
    }

    final started = await audio.startVoiceRecording();
    if (!mounted) return;
    if (started == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activa el permiso de micrófono para dictar tu duda.'),
        ),
      );
      return;
    }
    setState(() => _recording = true);
  }

  Future<void> _speakMessage(_ChatMessage msg) async {
    final audio = ref.read(audioServiceProvider);
    final url = msg.reply?.audioSignedUrl;
    final b64 = msg.reply?.audioBase64;
    if (b64 != null && b64.isNotEmpty) {
      await audio.playBase64Wav(b64);
    } else if (url != null && url.isNotEmpty) {
      await audio.playAudioUrl(url);
    } else {
      await audio.speakLocal(msg.text);
    }
  }

  void _executeAction(CopilotReply reply) {
    Navigator.of(context).pop();
    switch (reply.suggestedActionType) {
      case 'open_first_timer_guide':
        widget.onOpenFirstTimerGuide();
        break;
      case 'open_report':
        context.go('/report');
        break;
      case 'open_briefs':
        context.go('/briefs');
        break;
      case 'open_map_route':
        if (reply.suggestedQuery != null && reply.suggestedQuery!.isNotEmpty) {
          ref.read(pendingMapIntentProvider.notifier).state = ExploreMapIntent(
            destinationQuery: reply.suggestedQuery,
          );
        }
        context.go('/map');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ViaLibreTheme.paletteOf(context);
    const starterChips = [
      '¿Cómo uso el Metrobús por primera vez?',
      'Llévame a una clínica sin escalones',
      '¿Cómo reporto una rampa bloqueada?',
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: p.lavender,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: p.lavenderInk,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pregúntale a VíaLibre',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              'Asistente accesible impulsado por Gemini',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: starterChips
                        .map(
                          (q) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: Text(q),
                              onPressed:
                                  _loading ? null : () => _sendMessage(q),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    itemCount: _messages.length + (_loading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_loading && index == _messages.length) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 10),
                              Text('Pensando respuesta clara...'),
                            ],
                          ),
                        );
                      }
                      final msg = _messages[index];
                      return Align(
                        alignment: msg.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          constraints: const BoxConstraints(maxWidth: 320),
                          decoration: BoxDecoration(
                            color: msg.isUser ? p.ctaBg : p.sand,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectableText(
                                msg.text,
                                style: TextStyle(
                                  color: msg.isUser ? p.ctaFg : p.ink,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                              if (!msg.isUser) ...[
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                  ),
                                  onPressed: () => _speakMessage(msg),
                                  icon: Icon(
                                    Icons.volume_up_rounded,
                                    size: 18,
                                    color: p.coral,
                                  ),
                                  label: Text(
                                    'Escuchar',
                                    style: TextStyle(
                                      color: p.coral,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                              if (msg.reply != null &&
                                  msg.reply!.suggestedActionType != 'none') ...[
                                const SizedBox(height: 6),
                                AccessibleButton(
                                  label: msg.reply!.suggestedActionLabel ??
                                      'Abrir acción sugerida',
                                  onPressed: () => _executeAction(msg.reply!),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                  child: Row(
                    children: [
                      Semantics(
                        button: true,
                        label: _recording ? 'Detener dictado' : 'Dictar por voz',
                        child: TactilePress(
                          borderRadius: 24,
                          onTap: _loading ? null : _toggleVoice,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _recording ? p.alertRedSoft : p.lavender,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _recording
                                  ? Icons.stop_rounded
                                  : Icons.mic_rounded,
                              color:
                                  _recording ? p.alertRed : p.lavenderInk,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          textInputAction: TextInputAction.send,
                          style: const TextStyle(fontSize: 16),
                          decoration: const InputDecoration(
                            hintText: 'Escribe tu duda o destino...',
                          ),
                          onSubmitted: (val) => _sendMessage(val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Semantics(
                        button: true,
                        label: 'Enviar pregunta a VíaLibre',
                        child: TactilePress(
                          borderRadius: 24,
                          onTap:
                              _loading ? null : () => _sendMessage(_ctrl.text),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: p.coral,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
