import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/env.dart';
import '../../../core/media/image_sanitizer.dart';
import '../../../core/network/bff_client.dart';
import '../../../core/offline/offline_db.dart';
import '../../../core/offline/sync_manager.dart';

class BoundingBoxItem {
  const BoundingBoxItem({
    required this.label,
    required this.box2d,
  });

  final String label;

  /// `[ymin, xmin, ymax, xmax]` en escala normalizada `0..1000`.
  final List<int> box2d;

  factory BoundingBoxItem.fromJson(Map<String, dynamic> json) {
    final raw = (json['box_2d'] as List?) ?? const [];
    return BoundingBoxItem(
      label: (json['label'] as String?) ?? 'Obstáculo',
      box2d: raw.map((e) => (e as num).toInt()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'box_2d': box2d,
      };
}

class BarrierAnalysisResult {
  const BarrierAnalysisResult({
    required this.category,
    required this.title,
    required this.description,
    required this.severity,
    required this.confidenceScore,
    this.isImageClear = true,
    this.ambiguityReason,
    this.profileFlags = const {},
    this.boundingBoxes = const [],
    this.dispatchAgency,
  });

  final bool isImageClear;
  final String? ambiguityReason;
  final String category;
  final String title;
  final String description;
  final int severity;
  final double confidenceScore;
  final Map<String, dynamic> profileFlags;
  final List<BoundingBoxItem> boundingBoxes;
  final String? dispatchAgency;

  String get suggestedAgency {
    if (dispatchAgency != null && dispatchAgency!.isNotEmpty) {
      return dispatchAgency!;
    }
    switch (category) {
      case 'broken_elevator':
        return 'Mantenimiento Metro / Transporte Público';
      case 'blocked_ramp':
      case 'missing_curb_cut':
        return 'Movilidad Urbana y Tránsito';
      case 'broken_sidewalk':
      case 'steep_slope':
        return 'Obras Públicas y Servicios Urbanos';
      case 'audible_signal_issue':
      case 'missing_tactile':
        return 'Señalización Vial e Inclusión';
      default:
        return 'Atención Ciudadana Municipal';
    }
  }

  Map<String, dynamic> toJson() => {
        'isImageClear': isImageClear,
        'ambiguityReason': ambiguityReason,
        'category': category,
        'title': title,
        'description': description,
        'severity': severity,
        'confidenceScore': confidenceScore,
        'profileFlags': profileFlags,
        'boundingBoxes': boundingBoxes.map((b) => b.toJson()).toList(),
      };

  factory BarrierAnalysisResult.fromJson(Map<String, dynamic> json) {
    final payload = json['analysis'] is Map<String, dynamic>
        ? json['analysis'] as Map<String, dynamic>
        : json;
    final boxesRaw = (payload['boundingBoxes'] as List?) ?? const [];
    return BarrierAnalysisResult(
      isImageClear: (payload['isImageClear'] as bool?) ?? true,
      ambiguityReason: payload['ambiguityReason'] as String?,
      category: (payload['category'] as String?) ?? 'other',
      title: (payload['title'] as String?) ?? 'Obstáculo urbano',
      description: (payload['description'] as String?) ?? '',
      severity: (payload['severity'] as num?)?.toInt() ?? 3,
      confidenceScore:
          (payload['confidenceScore'] as num?)?.toDouble() ??
              (payload['confidence'] as num?)?.toDouble() ??
              0.9,
      profileFlags:
          (payload['profileFlags'] as Map<String, dynamic>?) ?? const {},
      boundingBoxes: boxesRaw
          .whereType<Map<String, dynamic>>()
          .map(BoundingBoxItem.fromJson)
          .toList(),
      dispatchAgency: payload['dispatchAgency'] as String?,
    );
  }
}

class ReportOutcome {
  const ReportOutcome({
    required this.savedOffline,
    required this.message,
    this.barrierId,
    this.actionTaken,
  });

  final bool savedOffline;
  final String message;
  final int? barrierId;
  final String? actionTaken;
}

/// Repositorio alineado con `/api/barriers/analyze`, `/api/barriers/upload-url`,
/// `/api/barriers/report` y respaldo SQLite offline (`idempotencyKey`).
class ReportRepo {
  ReportRepo(this._bff, this._syncManager, this._ref);

  final BffClient _bff;
  final SyncManager _syncManager;
  final Ref _ref;

  Future<BarrierAnalysisResult> analyzeSanitizedImage({
    required SanitizedImage cleanImage,
    required String profile,
  }) async {
    final json = await _bff.postJson('/api/barriers/analyze', {
      'imageBase64': cleanImage.base64Data,
      'mimeType': 'image/jpeg',
      'profile': profile,
    });
    return BarrierAnalysisResult.fromJson(json);
  }

  Future<String?> _uploadSignedPhoto(File file) async {
    if (!Env.isSupabaseConfigured) return null;
    final ticket = await _bff.postJson('/api/barriers/upload-url', {
      'mimeType': 'image/jpeg',
      'fileExt': 'jpg',
    });
    final objectPath = ticket['objectPath'] as String?;
    final token = ticket['token'] as String?;
    if (objectPath == null || token == null) return null;

    await Supabase.instance.client.storage
        .from('barrier-evidence')
        .uploadToSignedUrl(objectPath, token, file);
    return objectPath;
  }

  Future<ReportOutcome> submitReport({
    required double lat,
    required double lng,
    required double? accuracyMeters,
    required String inputMode, // 'photo' | 'voice' | 'text'
    String? textNote,
    SanitizedImage? sanitizedPhoto,
    BarrierAnalysisResult? analysis,
    File? voiceFile,
  }) async {
    final idempotencyKey = const Uuid().v4();
    String? audioBase64;
    if (voiceFile != null && await voiceFile.exists()) {
      final audioBytes = await voiceFile.readAsBytes();
      audioBase64 = base64Encode(audioBytes);
    }

    final basePayload = <String, dynamic>{
      'idempotencyKey': idempotencyKey,
      'lat': lat,
      'lng': lng,
      if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
      'inputMode': inputMode,
      if (textNote != null && textNote.isNotEmpty) 'textNote': textNote,
      if (sanitizedPhoto != null) 'imageBase64': sanitizedPhoto.base64Data,
      if (audioBase64 != null) 'audioBase64': audioBase64,
      if (audioBase64 != null) 'audioMimeType': 'audio/mp4',
      if (analysis != null) 'preAnalyzed': analysis.toJson(),
    };

    try {
      String? photoPath;
      if (sanitizedPhoto != null) {
        try {
          photoPath = await _uploadSignedPhoto(File(sanitizedPhoto.filePath));
        } catch (_) {
          // Conserva imageBase64 en el reporte si falla la carga previa a Storage.
        }
      }

      if (photoPath != null) {
        basePayload['photoPath'] = photoPath;
      }

      final resp = await _bff.postJson('/api/barriers/report', basePayload);
      final barrierId = (resp['barrierId'] as num?)?.toInt();
      final actionTaken = resp['actionTaken'] as String?;

      return ReportOutcome(
        savedOffline: false,
        barrierId: barrierId,
        actionTaken: actionTaken,
        message: actionTaken == 'confirmed' || actionTaken == 'deduplicated'
            ? 'Ya existía un reporte cercano. Se sumó tu confirmación.'
            : '¡Reporte procesado (${actionTaken ?? "publicado"}) en tiempo real!',
      );
    } catch (_) {
      final item = OfflineReportItem(
        idempotencyKey: idempotencyKey,
        lat: lat,
        lng: lng,
        accuracyMeters: accuracyMeters,
        inputMode: inputMode,
        localPhotoPath: sanitizedPhoto?.filePath,
        textNote: textNote,
        payloadJson: jsonEncode(basePayload),
        createdAtIso: DateTime.now().toIso8601String(),
      );
      await _syncManager.enqueue(item);
      final remaining = await _syncManager.pendingCount();
      _ref.read(pendingOfflineCountProvider.notifier).state = remaining;

      return const ReportOutcome(
        savedOffline: true,
        message:
            'Sin conexión o BFF no disponible. Borrador guardado en tu teléfono para enviarse al volver.',
      );
    }
  }

  Future<SanitizedImage> sanitizeFile(File rawFile) {
    return ImageSanitizer.sanitizeForUpload(rawFile);
  }
}

final reportRepoProvider = Provider<ReportRepo>(
  (ref) => ReportRepo(
    ref.read(bffClientProvider),
    ref.read(syncManagerProvider),
    ref,
  ),
);
