class Barrier {
  final String id;
  final String title;
  final String category;
  final String categoryCode;
  final String severity;
  final double latitude;
  final double longitude;
  final int confirmations;
  final Map<String, dynamic> profileFlags;
  final String? description;

  Barrier({
    required this.id,
    required this.title,
    required this.category,
    required this.categoryCode,
    required this.severity,
    required this.latitude,
    required this.longitude,
    required this.confirmations,
    required this.profileFlags,
    this.description,
  });

  factory Barrier.fromJson(Map<String, dynamic> json) {
    return Barrier(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Obstáculo reportado',
      category: json['category'] ?? 'Obstáculo peatonal',
      categoryCode: json['category_code'] ?? 'open311_street_hazard',
      severity: json['severity'] ?? 'medium',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 19.4326,
      longitude: (json['longitude'] as num?)?.toDouble() ?? -99.1332,
      confirmations: json['confirmations'] ?? 1,
      profileFlags: json['profile_flags'] ?? {},
      description: json['description'],
    );
  }
}

enum AccessibilityProfile {
  wheelchair,
  lowVision,
  clearReading,
}
