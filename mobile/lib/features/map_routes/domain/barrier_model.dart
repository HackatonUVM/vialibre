/// Modelo alineado a `public.barriers`, `GET /api/barriers/nearby` y `GET /api/barriers/:id`.
class BarrierPin {
  const BarrierPin({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.severity,
    required this.lat,
    required this.lng,
    required this.confirmationsCount,
    this.status = 'active',
    this.profileFlags = const {},
    this.distanceMeters,
    this.photoSignedUrl,
  });

  final int id;
  final String category;
  final String title;
  final String description;
  final int severity;
  final double lat;
  final double lng;
  final int confirmationsCount;
  final String status;
  final Map<String, dynamic> profileFlags;
  final double? distanceMeters;
  final String? photoSignedUrl;

  String get categoryLabel {
    switch (category) {
      case 'blocked_ramp':
        return 'Rampa bloqueada';
      case 'broken_sidewalk':
        return 'Banqueta rota';
      case 'steep_slope':
        return 'Pendiente pronunciada';
      case 'broken_elevator':
        return 'Elevador descompuesto';
      case 'missing_tactile':
        return 'Sin pavimento táctil';
      case 'missing_curb_cut':
        return 'Sin rebaje en esquina';
      case 'audible_signal_issue':
        return 'Semáforo sonoro sin audio';
      default:
        return 'Obstáculo urbano';
    }
  }

  bool get isSidewalkOrSlope =>
      category == 'broken_sidewalk' || category == 'steep_slope';

  factory BarrierPin.fromRpcJson(Map<String, dynamic> json) {
    return BarrierPin(
      id: (json['id'] as num).toInt(),
      category: (json['category'] as String?) ?? 'other',
      title: (json['title'] as String?) ?? 'Obstáculo reportado',
      description: (json['description'] as String?) ?? '',
      severity: (json['severity'] as num?)?.toInt() ?? 3,
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      confirmationsCount: (json['confirmations_count'] as num?)?.toInt() ?? 1,
      status: (json['status'] as String?) ?? 'active',
      profileFlags: (json['profile_flags'] as Map<String, dynamic>?) ?? const {},
      distanceMeters: (json['distance_meters'] as num?)?.toDouble() ??
          (json['distance_to_route_m'] as num?)?.toDouble(),
      photoSignedUrl: json['photoSignedUrl'] as String?,
    );
  }
}
