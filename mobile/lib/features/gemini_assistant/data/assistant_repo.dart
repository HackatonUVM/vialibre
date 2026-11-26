import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/media/image_sanitizer.dart';
import '../../../core/network/bff_client.dart';
import '../../report_barrier/data/report_repo.dart';

class CopilotReply {
  const CopilotReply({
    required this.replyText,
    this.suggestedActionType = 'none',
    this.suggestedActionLabel,
    this.suggestedQuery,
    this.quickFollowUps = const [],
    this.audioSignedUrl,
    this.audioBase64,
    this.isFallback = false,
  });

  final String replyText;

  /// 'open_map_route' | 'open_first_timer_guide' | 'open_report' | 'open_briefs' | 'none'
  final String suggestedActionType;
  final String? suggestedActionLabel;
  final String? suggestedQuery;
  final List<String> quickFollowUps;
  final String? audioSignedUrl;
  final String? audioBase64;
  final bool isFallback;

  factory CopilotReply.fromJson(Map<String, dynamic> json) {
    final action = json['suggestedAction'] as Map<String, dynamic>?;
    final followUpsRaw = (json['quickFollowUps'] as List?) ?? const [];
    return CopilotReply(
      replyText: (json['replyText'] as String?) ?? '',
      suggestedActionType: (action?['type'] as String?) ?? 'none',
      suggestedActionLabel: action?['label'] as String?,
      suggestedQuery: action?['query'] as String?,
      quickFollowUps: followUpsRaw.map((e) => e.toString()).toList(),
      audioSignedUrl: json['audioSignedUrl'] as String?,
      audioBase64: json['audioBase64'] as String?,
    );
  }
}

class SpaceAssessmentResult {
  const SpaceAssessmentResult({
    required this.verdict,
    required this.verdictLabel,
    required this.summary,
    required this.featuresDetected,
    required this.recommendation,
    this.boundingBoxes = const [],
  });

  /// 'accessible' | 'caution' | 'inaccessible'
  final String verdict;
  final String verdictLabel;
  final String summary;
  final List<String> featuresDetected;
  final String recommendation;
  final List<BoundingBoxItem> boundingBoxes;

  factory SpaceAssessmentResult.fromJson(Map<String, dynamic> json) {
    final payload = json['assessment'] is Map<String, dynamic>
        ? json['assessment'] as Map<String, dynamic>
        : json;
    final verdict = (payload['verdict'] as String?) ?? 'caution';
    final featuresRaw = (payload['featuresDetected'] as List?) ?? const [];
    final boxesRaw = (payload['boundingBoxes'] as List?) ?? const [];

    String defaultLabel;
    switch (verdict) {
      case 'accessible':
        defaultLabel = 'Acceso apto';
        break;
      case 'inaccessible':
        defaultLabel = 'No accesible';
        break;
      default:
        defaultLabel = 'Acceso con precaución';
    }

    return SpaceAssessmentResult(
      verdict: verdict,
      verdictLabel: (payload['verdictLabel'] as String?) ?? defaultLabel,
      summary: (payload['summary'] as String?) ?? '',
      featuresDetected: featuresRaw.map((e) => e.toString()).toList(),
      recommendation: (payload['recommendation'] as String?) ?? '',
      boundingBoxes: boxesRaw
          .whereType<Map<String, dynamic>>()
          .map(BoundingBoxItem.fromJson)
          .toList(),
    );
  }
}

/// Repositorio del Copiloto conversacional (`POST /api/assistant/chat`)
/// y Evaluador visual de accesibilidad (`POST /api/places/assess-photo`).
class AssistantRepo {
  AssistantRepo(this._bff);

  final BffClient _bff;

  Future<CopilotReply> askCopilot({
    required String message,
    required String profile,
    required double lat,
    required double lng,
    File? voiceFile,
  }) async {
    String? audioBase64;
    if (voiceFile != null && await voiceFile.exists()) {
      audioBase64 = base64Encode(await voiceFile.readAsBytes());
    }

    try {
      final json = await _bff.postJson('/api/assistant/chat', {
        'message': message,
        if (audioBase64 != null) 'audioBase64': audioBase64,
        if (audioBase64 != null) 'audioMimeType': 'audio/mp4',
        'profile': profile,
        'location': {'lat': lat, 'lng': lng},
        'generateAudio': true,
      });
      return CopilotReply.fromJson(json);
    } catch (_) {
      return _offlineGuidanceFallback(message, profile);
    }
  }

  Future<SpaceAssessmentResult> assessSpacePhoto({
    required SanitizedImage cleanImage,
    required String profile,
  }) async {
    final json = await _bff.postJson('/api/places/assess-photo', {
      'imageBase64': cleanImage.base64Data,
      'mimeType': 'image/jpeg',
      'profile': profile,
    });
    return SpaceAssessmentResult.fromJson(json);
  }

  CopilotReply _offlineGuidanceFallback(String message, String profile) {
    final lower = message.toLowerCase();
    if (lower.contains('metro') ||
        lower.contains('metrobús') ||
        lower.contains('metrobus') ||
        lower.contains('camión') ||
        lower.contains('camion') ||
        lower.contains('primera vez')) {
      return const CopilotReply(
        replyText:
            'El servidor de Gemini en vivo no está conectado aún, pero puedo abrirte la guía paso a paso para abordar Metro, Metrobús o camión sin dudas y escucharla en voz alta.',
        suggestedActionType: 'open_first_timer_guide',
        suggestedActionLabel: 'Abrir guía Modo Primera Vez',
        quickFollowUps: ['Rutas accesibles cerca', 'Cómo reportar una rampa'],
        isFallback: true,
      );
    }
    if (lower.contains('report') ||
        lower.contains('rampa') ||
        lower.contains('banqueta')) {
      return const CopilotReply(
        replyText:
            'El servidor Gemini no responde en este momento. Puedes ir directo a Reportar para tomar foto o grabar nota de voz y guardarla sin conexión.',
        suggestedActionType: 'open_report',
        suggestedActionLabel: 'Ir a Reportar obstáculo',
        quickFollowUps: ['Abrir avisos en lenguaje claro'],
        isFallback: true,
      );
    }
    if (lower.contains('aviso') || lower.contains('pdf')) {
      return const CopilotReply(
        replyText:
            'El servidor Gemini no responde todavía. En Avisos claros puedes ver el ejemplo en 3 pasos y escucharlo en voz clara.',
        suggestedActionType: 'open_briefs',
        suggestedActionLabel: 'Abrir Avisos claros',
        isFallback: true,
      );
    }
    return CopilotReply(
      replyText:
          'Aún no hay conexión con el backend de Gemini para responder en vivo (perfil activo: $profile). Mientras tanto puedes abrir el Mapa, consultar la guía Primera Vez o guardar un reporte.',
      suggestedActionType: 'open_map_route',
      suggestedActionLabel: 'Ir al Mapa',
      suggestedQuery: message.trim().length > 3 ? message.trim() : null,
      quickFollowUps: const [
        '¿Cómo uso el Metrobús por primera vez?',
        'Quiero reportar una rampa bloqueada',
      ],
      isFallback: true,
    );
  }
}

final assistantRepoProvider = Provider<AssistantRepo>(
  (ref) => AssistantRepo(ref.read(bffClientProvider)),
);
