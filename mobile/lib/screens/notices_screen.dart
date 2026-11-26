import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _textController = TextEditingController(
    text:
        'Aviso de la Dirección de Obras: Debido a la reposición de colector sanitario sobre Calzada Juárez, se cancela el cruce peatonal sur del 28 de noviembre al 4 de diciembre.',
  );

  bool _isTranslating = false;
  Map<String, dynamic>? _noticeSummary;

  Future<void> _translate() async {
    setState(() => _isTranslating = true);
    final res = await _api.simplifyNotice(text: _textController.text);
    if (mounted) {
      setState(() {
        _noticeSummary = res;
        _isTranslating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Avisos en Lenguaje Claro',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFB300)),
        ),
        const SizedBox(height: 6),
        const Text(
          'Norma ISO 24495-1: Convierte avisos burocráticos y técnicos en 3 bloques accionables fáciles de entender.',
          style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _textController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Texto del comunicado oficial',
            filled: true,
            fillColor: const Color(0xFF0F2444),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: _isTranslating ? null : _translate,
          icon: const Icon(Icons.auto_awesome, color: Color(0xFF0A192F)),
          label: Text(
            _isTranslating ? 'Gemini traduciendo...' : 'Traducir a Lenguaje Claro',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A192F)),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFB300),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        if (_noticeSummary != null) ...[
          const SizedBox(height: 20),
          _buildBlock(
            title: '1. ¿QUÉ PASÓ?',
            content: _noticeSummary!['quePaso'] ?? '',
            color: const Color(0xFF38BDF8),
          ),
          const SizedBox(height: 10),
          _buildBlock(
            title: '2. ¿A QUIÉN AFECTA?',
            content: _noticeSummary!['aQuienAfecta'] ?? '',
            color: const Color(0xFFFBBF24),
          ),
          const SizedBox(height: 10),
          _buildBlock(
            title: '3. ¿QUÉ HACER HOY?',
            content: _noticeSummary!['queHacerHoy'] ?? '',
            color: const Color(0xFF34D399),
          ),
        ],
      ],
    );
  }

  Widget _buildBlock({required String title, required String content, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2444),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 6),
          Text(content, style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.3)),
        ],
      ),
    );
  }
}
