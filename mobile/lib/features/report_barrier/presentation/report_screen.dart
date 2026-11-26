import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import 'package:vialibre/app/theme/vialibre_theme.dart';
import 'package:vialibre/core/media/audio_service.dart';
import 'package:vialibre/core/media/image_sanitizer.dart';
import 'package:vialibre/core/widgets/accessible_button.dart';
import 'package:vialibre/core/widgets/screen_header.dart';
import 'package:vialibre/core/widgets/tactile_press.dart';
import 'package:vialibre/features/profile/data/profile_prefs_repo.dart';
import '../data/report_repo.dart';
import 'bounding_box_overlay.dart';
import 'pending_queue_banner.dart';

/// Pantalla de reporte ciudadano adaptable a Modo Claro/Oscuro con recuadros IA,
/// envío real de nota de voz `.m4a`, canalización inteligente y cola offline.
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _noteController = TextEditingController();

  SanitizedImage? _sanitizedPhoto;
  BarrierAnalysisResult? _analysis;
  bool _analyzing = false;
  bool _submitting = false;
  bool _recording = false;
  String? _voicePath;
  String? _feedbackMessage;
  bool _feedbackIsError = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (picked == null) return;

      setState(() {
        _analyzing = true;
        _feedbackMessage = null;
      });

      final repo = ref.read(reportRepoProvider);
      final clean = await repo.sanitizeFile(File(picked.path));
      if (!mounted) return;

      setState(() {
        _sanitizedPhoto = clean;
        _analysis = null;
      });

      final profile =
          ref.read(profileControllerProvider).valueOrNull?.profile.keyName ??
              'wheelchair';

      try {
        final result = await repo.analyzeSanitizedImage(
          cleanImage: clean,
          profile: profile,
        );
        if (!mounted) return;
        setState(() {
          _analysis = result;
          if (_noteController.text.isEmpty && result.description.isNotEmpty) {
            _noteController.text = result.description;
          }
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _feedbackMessage =
              'Foto lista sin metadatos EXIF. Escribe una nota breve o envíala para clasificar en el servidor.';
          _feedbackIsError = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _feedbackMessage = 'No se pudo abrir la cámara: $e';
        _feedbackIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _analyzing = false);
      }
    }
  }

  Future<void> _toggleVoiceRecording() async {
    final audio = ref.read(audioServiceProvider);
    if (_recording) {
      final path = await audio.stopVoiceRecording();
      if (!mounted) return;
      setState(() {
        _recording = false;
        _voicePath = path;
        _feedbackMessage = path != null
            ? 'Nota de voz lista. Al enviar, Gemini la transcribirá y clasificará automáticamente.'
            : null;
        _feedbackIsError = false;
      });
      return;
    }

    final startedPath = await audio.startVoiceRecording();
    if (!mounted) return;
    if (startedPath == null) {
      setState(() {
        _feedbackMessage =
            'Activa el permiso de micrófono para grabar una nota de voz.';
        _feedbackIsError = true;
      });
      return;
    }

    setState(() {
      _recording = true;
      _feedbackMessage = null;
    });
  }

  Future<void> _submitReport() async {
    if (_sanitizedPhoto == null &&
        _voicePath == null &&
        _noteController.text.trim().isEmpty) {
      setState(() {
        _feedbackMessage =
            'Toma una foto, graba una nota de voz o escribe una descripción antes de enviar.';
        _feedbackIsError = true;
      });
      return;
    }

    setState(() {
      _submitting = true;
      _feedbackMessage = null;
    });

    var lat = 19.4326;
    var lng = -99.1332;
    double? accuracy;

    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );
        lat = pos.latitude;
        lng = pos.longitude;
        accuracy = pos.accuracy;
      }
    } catch (_) {}

    final inputMode = _sanitizedPhoto != null
        ? 'photo'
        : (_voicePath != null ? 'voice' : 'text');

    final outcome = await ref.read(reportRepoProvider).submitReport(
          lat: lat,
          lng: lng,
          accuracyMeters: accuracy,
          inputMode: inputMode,
          textNote: _noteController.text.trim(),
          sanitizedPhoto: _sanitizedPhoto,
          analysis: _analysis,
          voiceFile: _voicePath != null ? File(_voicePath!) : null,
        );

    if (_voicePath != null && !outcome.savedOffline) {
      await ref.read(audioServiceProvider).discardTempFile(_voicePath);
    }

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _feedbackMessage = outcome.message;
      _feedbackIsError = false;
      _sanitizedPhoto = null;
      _analysis = null;
      _voicePath = null;
      _noteController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = ViaLibreTheme.paletteOf(context);
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          const ScreenHeader(
            eyebrow: 'Participación ciudadana',
            title: 'Reportar obstáculo',
            subtitle:
                'Ayuda a mantener las rutas libres capturando rampas bloqueadas, banquetas rotas o elevadores sin servicio.',
          ),
          const SizedBox(height: 18),
          const PendingQueueBanner(),
          Row(
            children: [
              Expanded(
                child: _CaptureMethodCard(
                  icon: Icons.camera_alt_rounded,
                  title: 'Tomar foto',
                  subtitle: 'Visión IA + EXIF cero',
                  accentBg: p.lavender,
                  accentFg: p.lavenderInk,
                  onTap: _analyzing ? null : _capturePhoto,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CaptureMethodCard(
                  icon: _recording ? Icons.stop_rounded : Icons.mic_rounded,
                  title: _recording ? 'Detener voz' : 'Nota de voz',
                  subtitle: _recording
                      ? 'Grabando audio...'
                      : (_voicePath != null ? 'Audio listo' : 'Dictado guiado'),
                  accentBg: _recording ? p.alertRedSoft : p.coralSoft,
                  accentFg: _recording ? p.alertRed : p.coral,
                  onTap: _toggleVoiceRecording,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_analyzing)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Eliminando metadatos EXIF y analizando accesibilidad con Gemini...',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_sanitizedPhoto != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 220,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(_sanitizedPhoto!.filePath),
                      fit: BoxFit.cover,
                    ),
                    if (_analysis != null)
                      BoundingBoxOverlay(boxes: _analysis!.boundingBoxes),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_analysis != null) ...[
            if (!_analysis!.isImageClear)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: p.amberSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: p.amberInk,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Imagen poco clara: ${_analysis!.ambiguityReason ?? "Verifica la información antes de publicar."}',
                        style: TextStyle(
                          color: p.amberInk,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: p.lavender,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'IA · ${(_analysis!.confidenceScore * 100).round()}% certeza',
                            style: TextStyle(
                              color: p.lavenderInk,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Severidad ${_analysis!.severity}/5',
                          style: TextStyle(
                            color: p.alertRed,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _analysis!.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _analysis!.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: p.sand,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_outlined,
                            size: 18,
                            color: p.ink,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Canalización sugerida: ${_analysis!.suggestedAgency}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_analysis!.profileFlags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _analysis!.profileFlags.entries
                            .where((e) => e.value == true)
                            .map(
                              (e) => Chip(
                                label: Text('Afecta: ${e.key}'),
                                backgroundColor: p.coralSoft,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.sand,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: p.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: p.mintInk,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Privacidad protegida: los metadatos EXIF se eliminan en tu teléfono antes del envío.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            maxLines: 3,
            textInputAction: TextInputAction.done,
            style: const TextStyle(fontSize: 16),
            decoration: const InputDecoration(
              labelText: 'Detalles del obstáculo (opcional)',
              hintText:
                  'Ej. Rampa obstruida en esquina Av. Hidalgo con Reforma.',
            ),
          ),
          if (_feedbackMessage != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _feedbackIsError ? p.alertRedSoft : p.mintSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _feedbackMessage!,
                style: TextStyle(
                  color: _feedbackIsError ? p.alertRed : p.mintInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          AccessibleButton(
            label: 'Confirmar y publicar al mapa',
            icon: Icons.send_rounded,
            isLoading: _submitting,
            semanticHint:
                'Publicar obstáculo en tiempo real o guardarlo sin conexión',
            onPressed: _submitReport,
          ),
        ],
      ),
    );
  }
}

class _CaptureMethodCard extends StatelessWidget {
  const _CaptureMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentBg,
    required this.accentFg,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentBg;
  final Color accentFg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = ViaLibreTheme.paletteOf(context);
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: TactilePress(
        borderRadius: 22,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: p.border),
          ),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accentBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentFg, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
