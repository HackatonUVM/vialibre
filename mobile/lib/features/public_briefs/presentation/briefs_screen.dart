import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:vialibre/app/theme/vialibre_theme.dart';
import 'package:vialibre/core/widgets/accessible_button.dart';
import 'package:vialibre/core/widgets/audio_player_bar.dart';
import 'package:vialibre/core/widgets/screen_header.dart';
import '../data/briefs_repo.dart';

/// Traductor ciudadano de avisos públicos adaptable a Modo Claro/Oscuro.
class BriefsScreen extends ConsumerStatefulWidget {
  const BriefsScreen({super.key});

  @override
  ConsumerState<BriefsScreen> createState() => _BriefsScreenState();
}

class _BriefsScreenState extends ConsumerState<BriefsScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _textController = TextEditingController();

  bool _loading = false;
  bool _largeText = false;
  String? _error;

  SimplifiedBrief _activeBrief = const SimplifiedBrief(
    issuer: 'Movilidad Urbana · Muestra',
    title: 'Movilidad Urbana · Ruta 4 desviada por obras',
    whatHappened:
        'Cerraron la calle Benito Juárez entre Morelos y Zaragoza por reparación de tubería y banquetas. Los camiones no pueden pasar por ahí hoy.',
    whoIsAffected:
        'Personas que toman la Ruta 4, usan silla de ruedas en esa banqueta o bajan hacia el centro.',
    actionToday:
        'Toma la parada provisional sobre Av. Hidalgo (100 m antes) o usa Metrobús L3 con elevador activo.',
    estimatedDuration: 'Hoy hasta las 20:00 h',
  );

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    final path = result?.files.single.path;
    if (path == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final simplified = await ref.read(briefsRepoProvider).simplifyPdf(
            pdfFile: File(path),
            title: result!.files.single.name,
          );
      if (!mounted) return;
      setState(() => _activeBrief = simplified);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo procesar el PDF: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickPhoto() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.camera);
    if (picked == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final simplified = await ref.read(briefsRepoProvider).simplifyPhoto(
            photoFile: File(picked.path),
            title: 'Aviso ciudadano capturado',
          );
      if (!mounted) return;
      setState(() => _activeBrief = simplified);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo leer el aviso por foto: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _simplifyPastedText() async {
    final text = _textController.text.trim();
    if (text.length < 10) {
      setState(
        () => _error = 'Pega un aviso oficial con al menos 10 caracteres.',
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final simplified = await ref.read(briefsRepoProvider).simplifyText(
            title: 'Comunicado público',
            textContent: text,
          );
      if (!mounted) return;
      setState(() {
        _activeBrief = simplified;
        _textController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo simplificar el texto: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ViaLibreTheme.paletteOf(context);
    final textScale = _largeText ? 1.2 : 1.0;
    final durationTag = _activeBrief.audioDurationSeconds != null
        ? ' (${_activeBrief.audioDurationSeconds}s)'
        : '';

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          const ScreenHeader(
            eyebrow: 'Lectura Fácil · ISO 24495-1',
            title: 'Avisos claros',
            subtitle:
                'Comunicados oficiales explicados paso a paso sin términos difíciles.',
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilterChip(
              selected: _largeText,
              selectedColor: p.ctaBg,
              checkmarkColor: p.ctaFg,
              labelStyle: TextStyle(
                color: _largeText ? p.ctaFg : p.ink,
                fontWeight: FontWeight.w700,
              ),
              label:
                  Text(_largeText ? 'Texto Grande: Activo' : 'Texto Grande'),
              onSelected: (v) => setState(() => _largeText = v),
            ),
          ),
          const SizedBox(height: 14),
          AudioPlayerBar(
            title: 'Escuchar resumen del aviso$durationTag',
            audioUrl: _activeBrief.audioSignedUrl,
            base64Wav: _activeBrief.audioBase64,
            fallbackText:
                '${_activeBrief.title}. Qué pasó: ${_activeBrief.whatHappened}. A quién afecta: ${_activeBrief.whoIsAffected}. Qué hacer hoy: ${_activeBrief.actionToday}',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Subir circular, PDF o foto del aviso',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AccessibleButton(
                          label: 'Subir PDF',
                          icon: Icons.picture_as_pdf_outlined,
                          isLoading: _loading,
                          onPressed: _pickPdf,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loading ? null : _pickPhoto,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(48, 54),
                          ),
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('Foto aviso'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _textController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: 'O pega aquí un comunicado municipal...',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed: _loading ? null : _simplifyPastedText,
                      child: const Text('Simplificar texto'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: p.alertRed),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            _activeBrief.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Emisor: ${_activeBrief.issuer}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _PlainCard(
            stepLabel: 'PASO 01 · CAUSA',
            title: 'Qué pasó',
            body: _activeBrief.whatHappened,
            accentColor: p.coral,
            softColor: p.coralSoft,
            icon: Icons.construction_rounded,
            textScale: textScale,
            footer: _activeBrief.estimatedDuration != null
                ? 'Vigencia estimada: ${_activeBrief.estimatedDuration}'
                : null,
          ),
          _PlainCard(
            stepLabel: 'PASO 02 · AFECTADOS',
            title: 'A quién afecta',
            body: _activeBrief.whoIsAffected,
            accentColor: p.lavenderInk,
            softColor: p.lavender,
            icon: Icons.groups_rounded,
            textScale: textScale,
          ),
          _PlainCard(
            stepLabel: 'PASO 03 · ACCIÓN HOY',
            title: 'Qué hacer hoy',
            body: _activeBrief.actionToday,
            accentColor: p.mintInk,
            softColor: p.mintSoft,
            icon: Icons.directions_rounded,
            textScale: textScale,
          ),
        ],
      ),
    );
  }
}

class _PlainCard extends StatelessWidget {
  const _PlainCard({
    required this.stepLabel,
    required this.title,
    required this.body,
    required this.accentColor,
    required this.softColor,
    required this.icon,
    required this.textScale,
    this.footer,
  });

  final String stepLabel;
  final String title;
  final String body;
  final Color accentColor;
  final Color softColor;
  final IconData icon;
  final double textScale;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final p = ViaLibreTheme.paletteOf(context);
    return Semantics(
      container: true,
      label: '$stepLabel. $title. $body',
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: softColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: accentColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stepLabel,
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SelectableText(
                body,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 16 * textScale,
                    ),
              ),
              if (footer != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.sand,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    footer!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
