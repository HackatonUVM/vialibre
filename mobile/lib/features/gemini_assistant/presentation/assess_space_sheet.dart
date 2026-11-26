import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:vialibre/app/theme/vialibre_theme.dart';
import 'package:vialibre/core/media/audio_service.dart';
import 'package:vialibre/core/media/image_sanitizer.dart';
import 'package:vialibre/core/widgets/accessible_button.dart';
import 'package:vialibre/features/profile/data/profile_prefs_repo.dart';
import 'package:vialibre/features/report_barrier/presentation/bounding_box_overlay.dart';
import '../data/assistant_repo.dart';

/// Evaluador visual "¿Puedo entrar aquí?": usa Gemini Vision sobre una foto
/// para diagnosticar rampas, escalones, puerta y pavimento táctil.
class AssessSpaceSheet extends ConsumerStatefulWidget {
  const AssessSpaceSheet({super.key});

  @override
  ConsumerState<AssessSpaceSheet> createState() => _AssessSpaceSheetState();
}

class _AssessSpaceSheetState extends ConsumerState<AssessSpaceSheet> {
  final ImagePicker _picker = ImagePicker();

  SanitizedImage? _photo;
  SpaceAssessmentResult? _assessment;
  bool _loading = false;
  String? _error;

  Future<void> _takePhotoAndAssess() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (picked == null) return;

      setState(() {
        _loading = true;
        _error = null;
        _assessment = null;
      });

      final clean = await ImageSanitizer.sanitizeForUpload(File(picked.path));
      if (!mounted) return;
      setState(() => _photo = clean);

      final profile =
          ref.read(profileControllerProvider).valueOrNull?.profile.keyName ??
              'wheelchair';

      final result = await ref.read(assistantRepoProvider).assessSpacePhoto(
            cleanImage: clean,
            profile: profile,
          );
      if (!mounted) return;
      setState(() => _assessment = result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error =
            'Conecta el backend con Gemini para evaluar la foto en vivo ($e).';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ViaLibreTheme.paletteOf(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      builder: (context, scrollCtrl) {
        return SafeArea(
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '¿Puedo entrar aquí?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Toma una foto de la entrada de una clínica, estación o camión y Gemini evaluará su accesibilidad (sin guardar metadatos EXIF).',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              AccessibleButton(
                label: _photo == null ? 'Tomar foto del lugar' : 'Tomar otra foto',
                icon: Icons.camera_alt_rounded,
                isLoading: _loading,
                onPressed: _takePhotoAndAssess,
              ),
              if (_photo != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(_photo!.filePath),
                          fit: BoxFit.cover,
                        ),
                        if (_assessment != null)
                          BoundingBoxOverlay(boxes: _assessment!.boundingBoxes),
                      ],
                    ),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.amberSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: p.amberInk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (_assessment != null) ...[
                const SizedBox(height: 16),
                _VerdictCard(assessment: _assessment!),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final text =
                              '${_assessment!.verdictLabel}. ${_assessment!.summary}. ${_assessment!.recommendation}';
                          ref.read(audioServiceProvider).speakLocal(text);
                        },
                        icon: const Icon(Icons.volume_up_rounded),
                        label: const Text('Escuchar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.go('/report');
                        },
                        icon: const Icon(Icons.add_alert_outlined),
                        label: const Text('Reportar obstáculo'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _VerdictCard extends StatelessWidget {
  const _VerdictCard({required this.assessment});

  final SpaceAssessmentResult assessment;

  @override
  Widget build(BuildContext context) {
    final p = ViaLibreTheme.paletteOf(context);
    Color bg;
    Color fg;
    IconData icon;

    switch (assessment.verdict) {
      case 'accessible':
        bg = p.mintSoft;
        fg = p.mintInk;
        icon = Icons.check_circle_rounded;
        break;
      case 'inaccessible':
        bg = p.alertRedSoft;
        fg = p.alertRed;
        icon = Icons.cancel_rounded;
        break;
      default:
        bg = p.amberSoft;
        fg = p.amberInk;
        icon = Icons.warning_amber_rounded;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: fg, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    assessment.verdictLabel,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SelectableText(
              assessment.summary,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (assessment.featuresDetected.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: assessment.featuresDetected
                    .map(
                      (f) => Chip(
                        label: Text(f),
                        backgroundColor: p.sand,
                      ),
                    )
                    .toList(),
              ),
            ],
            if (assessment.recommendation.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.sand,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  assessment.recommendation,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
