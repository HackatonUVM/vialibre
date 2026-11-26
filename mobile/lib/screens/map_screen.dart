import 'package:flutter/material.dart';
import '../models/barrier.dart';
import '../services/api_service.dart';

class MapScreen extends StatefulWidget {
  final AccessibilityProfile profile;

  const MapScreen({super.key, required this.profile});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _destController =
      TextEditingController(text: 'Clínica 24 (Acceso a nivel)');

  List<Barrier> _barriers = [];
  Map<String, dynamic>? _routeData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBarriers();
  }

  Future<void> _loadBarriers() async {
    final list = await _api.getNearbyBarriers(lat: 19.4326, lng: -99.1332);
    if (mounted) setState(() => _barriers = list);
  }

  Future<void> _searchRoute() async {
    setState(() => _isLoading = true);
    final route = await _api.calculateAccessibleRoute(
      originLat: 19.4326,
      originLng: -99.1332,
      destLat: 19.4350,
      destLng: -99.1360,
      profile: widget.profile.name,
    );
    if (mounted) {
      setState(() {
        _routeData = route;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Ruta Peatonal Accesible',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFB300)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _destController,
          decoration: InputDecoration(
            labelText: 'Destino',
            prefixIcon: const Icon(Icons.search, color: Color(0xFFFFB300)),
            suffixIcon: IconButton(
              icon: const Icon(Icons.directions, color: Color(0xFFFFB300)),
              onPressed: _searchRoute,
            ),
            filled: true,
            fillColor: const Color(0xFF0F2444),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _searchRoute,
          icon: const Icon(Icons.navigation, color: Color(0xFF0A192F)),
          label: Text(
            _isLoading ? 'Calculando ruta con Google Maps...' : 'Calcular Ruta Accesible',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A192F)),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFB300),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFF071224),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1E3A8A)),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.map, size: 48, color: Color(0xFF38BDF8)),
                const SizedBox(height: 8),
                Text(
                  '${_barriers.length} obstáculos activos en tu radio',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Google Maps SDK con Marcadores Avanzados',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ),
        if (_routeData != null) ...[
          const SizedBox(height: 16),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.between,
                  children: [
                    Text(
                      'Distancia: ${_routeData!['distanceMeters']} m',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                    ),
                    const Icon(Icons.check_circle, color: Color(0xFF10B981)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('Pasos verificados:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                ...((_routeData!['steps'] as List? ?? []).map((step) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• ${step['instruction']}', style: const TextStyle(fontSize: 13)),
                    ))),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
