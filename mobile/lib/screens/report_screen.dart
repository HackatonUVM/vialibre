import 'package:flutter/material.dart';
import '../models/barrier.dart';
import '../services/api_service.dart';

class ReportScreen extends StatefulWidget {
  final AccessibilityProfile profile;

  const ReportScreen({super.key, required this.profile});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ApiService _api = ApiService();
  String _mediaType = 'photo';
  bool _isSubmitting = false;
  Map<String, dynamic>? _lastReport;

  Future<void> _submitReport() async {
    setState(() => _isSubmitting = true);
    // Base64 demo para activar el endpoint de visión
    const demoBase64 =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

    final res = await _api.submitReport(
      lat: 19.4326,
      lng: -99.1332,
      type: _mediaType,
      mediaBase64: demoBase64,
      mimeType: 'image/png',
      userProfile: widget.profile.name,
    );

    if (mounted) {
      setState(() {
        _lastReport = res?['data'];
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Reporte Ciudadano en un Toque',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFB300)),
        ),
        const SizedBox(height: 6),
        const Text(
          'Gemini detectará y clasificará el obstáculo automáticamente. Tus metadatos privados EXIF se eliminan antes de subir la imagen.',
          style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _mediaType = 'photo'),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Fotografía'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _mediaType == 'photo' ? const Color(0xFF2563EB) : const Color(0xFF0F2444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _mediaType = 'audio'),
                icon: const Icon(Icons.mic),
                label: const Text('Nota de voz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _mediaType == 'audio' ? const Color(0xFF2563EB) : const Color(0xFF0F2444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xFF071224),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1E3A8A), style: BorderStyle.solid),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _mediaType == 'photo' ? Icons.add_photo_alternate_outlined : Icons.record_voice_over_outlined,
                  size: 54,
                  color: const Color(0xFFFFB300),
                ),
                const SizedBox(height: 10),
                Text(
                  _mediaType == 'photo'
                      ? 'Toca para capturar imagen de la rampa o banqueta'
                      : 'Presiona para grabar descripción del obstáculo',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            _isSubmitting ? 'Procesando con Gemini...' : 'Publicar Reporte con IA',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0A192F)),
          ),
        ),
        if (_lastReport != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2444),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✓ Reporte Analizado por Gemini',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF34D399)),
                ),
                const SizedBox(height: 8),
                Text('Título: ${_lastReport!['title']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Categoría: ${_lastReport!['category']}'),
                const SizedBox(height: 4),
                Text(
                  _lastReport!['isDuplicate'] == true
                      ? '⚠️ Coincidencia en 25m: Sumada confirmación'
                      : '📍 Nuevo obstáculo publicado en el mapa',
                  style: const TextStyle(color: Color(0xFFFBBF24)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
