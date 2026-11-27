import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/media/image_sanitizer.dart';
import '../../../core/network/bff_client.dart';

class SimplifiedBrief {
  const SimplifiedBrief({
    required this.title,
    required this.whatHappened,
    required this.whoIsAffected,
    required this.actionToday,
    this.issuer = 'Aviso oficial',
    this.estimatedDuration,
    this.audioDurationSeconds,
    this.audioSignedUrl,
    this.audioBase64,
    this.cached = false,
  });

  final String title;
  final String whatHappened;
  final String whoIsAffected;
  final String actionToday;
  final String issuer;
  final String? estimatedDuration;
  final int? audioDurationSeconds;
  final String? audioSignedUrl;
  final String? audioBase64;
  final bool cached;

  factory SimplifiedBrief.fromJson(
    Map<String, dynamic> json, {
    required String fallbackTitle,
  }) {
    final summary = json['plainSummary'] is Map<String, dynamic>
        ? json['plainSummary'] as Map<String, dynamic>
        : json;
    final issuer = (json['issuer'] as String?) ?? 'Aviso oficial';
    return SimplifiedBrief(
      cached: (json['cached'] as bool?) ?? false,
      title: (json['title'] as String?) ?? '$issuer · $fallbackTitle',
      issuer: issuer,
      whatHappened: (summary['whatHappened'] as String?) ?? '',
      whoIsAffected: (summary['whoIsAffected'] as String?) ?? '',
      actionToday: (summary['whatToDoToday'] as String?) ??
          (summary['actionToday'] as String?) ??
          '',
      estimatedDuration: json['estimatedDuration'] as String?,
      audioDurationSeconds: (json['audioDurationSeconds'] as num?)?.toInt(),
      audioSignedUrl: json['audioSignedUrl'] as String?,
      audioBase64: json['audioBase64'] as String?,
    );
  }
}

/// Repositorio alineado con `/api/briefs/upload-url`, `uploadToSignedUrl`
/// y `/api/briefs/simplify`.
class BriefsRepo {
  BriefsRepo(this._bff);

  final BffClient _bff;

  Future<SimplifiedBrief> simplifyPdf({
    required File pdfFile,
    required String title,
  }) async {
    if (!Env.isSupabaseConfigured) {
      throw StateError(
        'Configura SUPABASE_ANON_KEY para subir archivos PDF a Storage.',
      );
    }

    final ticket = await _bff.postJson('/api/briefs/upload-url', {
      'mimeType': 'application/pdf',
      'fileExt': 'pdf',
    });

    final objectPath = ticket['objectPath'] as String?;
    final token = ticket['token'] as String?;
    if (objectPath == null || token == null) {
      throw StateError('El backend no devolvió credenciales de carga para PDF.');
    }

    if (!Env.isInitialized) {
      throw StateError('Supabase no está disponible en este momento.');
    }

    await Supabase.instance.client.storage
        .from('public-briefs')
        .uploadToSignedUrl(objectPath, token, pdfFile);

    final resp = await _bff.postJson('/api/briefs/simplify', {
      'storagePath': objectPath,
      'mimeType': 'application/pdf',
      'generateAudio': true,
    });
    return SimplifiedBrief.fromJson(resp, fallbackTitle: title);
  }

  Future<SimplifiedBrief> simplifyPhoto({
    required File photoFile,
    required String title,
  }) async {
    final clean = await ImageSanitizer.sanitizeForUpload(photoFile);
    final resp = await _bff.postJson('/api/briefs/simplify', {
      'imageBase64': clean.base64Data,
      'mimeType': 'image/jpeg',
      'generateAudio': true,
    });
    return SimplifiedBrief.fromJson(resp, fallbackTitle: title);
  }

  Future<SimplifiedBrief> simplifyText({
    required String title,
    required String textContent,
  }) async {
    final resp = await _bff.postJson('/api/briefs/simplify', {
      'textContent': textContent,
      'mimeType': 'text/plain',
      'generateAudio': true,
    });
    return SimplifiedBrief.fromJson(resp, fallbackTitle: title);
  }
}

final briefsRepoProvider = Provider<BriefsRepo>(
  (ref) => BriefsRepo(ref.read(bffClientProvider)),
);
