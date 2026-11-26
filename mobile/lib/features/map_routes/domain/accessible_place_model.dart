class AccessiblePlace {
  const AccessiblePlace({
    required this.placeId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.wheelchairAccessibleEntrance,
    this.wheelchairAccessibleRestroom,
    this.wheelchairAccessibleParking,
    this.wheelchairAccessibleSeating,
  });

  final String placeId;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final bool? wheelchairAccessibleEntrance;
  final bool? wheelchairAccessibleRestroom;
  final bool? wheelchairAccessibleParking;
  final bool? wheelchairAccessibleSeating;

  factory AccessiblePlace.fromJson(Map<String, dynamic> json) {
    final opts =
        (json['accessibilityOptions'] as Map<String, dynamic>?) ?? const {};
    return AccessiblePlace(
      placeId: (json['placeId'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'Lugar',
      address: (json['formattedAddress'] as String?) ??
          (json['address'] as String?) ??
          '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      wheelchairAccessibleEntrance:
          opts['wheelchairAccessibleEntrance'] as bool?,
      wheelchairAccessibleRestroom:
          opts['wheelchairAccessibleRestroom'] as bool?,
      wheelchairAccessibleParking: opts['wheelchairAccessibleParking'] as bool?,
      wheelchairAccessibleSeating: opts['wheelchairAccessibleSeating'] as bool?,
    );
  }
}
