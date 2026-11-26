import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/barrier.dart';

class ApiService {
  // Conexión predeterminada al BFF desplegado en Vercel
  static const String defaultBaseUrl = 'https://bff-steel.vercel.app';

  final String baseUrl;

  ApiService({this.baseUrl = defaultBaseUrl});

  /// Obtiene barreras activas cercanas a una ubicación dada
  Future<List<Barrier>> getNearbyBarriers({
    required double lat,
    required double lng,
    double radiusMeters = 1500,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/barriers/nearby?lat=$lat&lng=$lng&radius=$radiusMeters');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['barriers'] ?? [];
        return list.map((item) => Barrier.fromJson(item)).toList();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error consultando barreras cercanas: $e');
    }
    return [];
  }

  /// Calcula la ruta peatonal accesible adaptada al perfil
  Future<Map<String, dynamic>?> calculateAccessibleRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required String profile,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/routes/accessible');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'origin': {'latitude': originLat, 'longitude': originLng},
          'destination': {'latitude': destLat, 'longitude': destLng},
          'profile': profile,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['route'];
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error calculando ruta: $e');
    }
    return null;
  }

  /// Envía un reporte de obstáculo a Gemini para visión y deduplicación atómica
  Future<Map<String, dynamic>?> submitReport({
    required double lat,
    required double lng,
    required String type, // 'photo' o 'audio'
    required String mediaBase64,
    required String mimeType,
    String? userProfile,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/barriers/report');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude': lat,
          'longitude': lng,
          'type': type,
          'mediaBase64': mediaBase64,
          'mimeType': mimeType,
          'userProfile': userProfile,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error enviando reporte a Gemini: $e');
    }
    return null;
  }

  /// Traduce comunicados públicos a Lenguaje Claro (ISO 24495-1)
  Future<Map<String, dynamic>?> simplifyNotice({required String text}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/notices/simplify');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['summary'];
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error simplificando aviso: $e');
    }
    return null;
  }
}
