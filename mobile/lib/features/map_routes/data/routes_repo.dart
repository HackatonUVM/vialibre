import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/bff_client.dart';
import '../domain/accessible_place_model.dart';
import '../domain/barrier_model.dart';
import '../domain/transit_route_model.dart';

class AccessibleSearchResult {
  const AccessibleSearchResult({
    required this.routes,
    this.resolvedDestination,
    this.betaWarning,
  });

  final List<TransitRouteOption> routes;
  final AccessiblePlace? resolvedDestination;
  final String? betaWarning;
}

class NearbyPlacesResult {
  const NearbyPlacesResult({
    required this.places,
    required this.barriers,
  });

  final List<AccessiblePlace> places;
  final List<BarrierPin> barriers;
}

/// Repositorio de rutas multimodales (`POST /api/routes/accessible`) y lugares (`POST /api/places/nearby`).
class RoutesRepo {
  RoutesRepo(this._bff);

  final BffClient _bff;

  Future<AccessibleSearchResult> fetchAccessibleRoutes({
    required double originLat,
    required double originLng,
    required String destinationQuery,
    required String profile,
    bool avoidSlopes = true,
    double maxSlopePercent = 8.0,
    bool includeFirstTimerGuide = true,
  }) async {
    final json = await _bff.postJson('/api/routes/accessible', {
      'origin': {'lat': originLat, 'lng': originLng},
      'destinationQuery': destinationQuery,
      'profile': profile,
      'avoidSlopes': avoidSlopes,
      'maxSlopePercent': maxSlopePercent,
      'modes': ['WALK', 'TRANSIT'],
      'includeFirstTimerGuide': includeFirstTimerGuide,
    });

    final destJson = json['resolvedDestination'] as Map<String, dynamic>?;
    final routesRaw = (json['routes'] as List?) ?? const [];
    final rootGuideJson = json['firstTimerGuide'] as Map<String, dynamic>?;
    final rootGuide =
        rootGuideJson != null ? FirstTimerGuide.fromJson(rootGuideJson) : null;

    final parsedRoutes = <TransitRouteOption>[];
    for (var i = 0; i < routesRaw.length; i++) {
      final raw = routesRaw[i];
      if (raw is! Map<String, dynamic>) continue;
      final option = TransitRouteOption.fromJson(raw, index: i);
      parsedRoutes.add(
        option.firstTimerGuide == null && rootGuide != null
            ? option.copyWith(firstTimerGuide: rootGuide)
            : option,
      );
    }

    return AccessibleSearchResult(
      resolvedDestination:
          destJson != null ? AccessiblePlace.fromJson(destJson) : null,
      betaWarning: json['betaWarning'] as String?,
      routes: parsedRoutes,
    );
  }

  Future<NearbyPlacesResult> fetchNearbyAccessiblePlaces({
    required double lat,
    required double lng,
    String query = 'rampa accesible clínica metro',
    double radiusMeters = 800,
    bool onlyWheelchairAccessible = false,
  }) async {
    final json = await _bff.postJson('/api/places/nearby', {
      'lat': lat,
      'lng': lng,
      'query': query,
      'radiusMeters': radiusMeters,
    });

    final placesRaw = (json['places'] as List?) ?? const [];
    final barriersRaw = (json['barriers'] as List?) ?? const [];

    var places = placesRaw
        .whereType<Map<String, dynamic>>()
        .map(AccessiblePlace.fromJson)
        .toList();

    if (onlyWheelchairAccessible) {
      final filtered = places
          .where((p) => p.wheelchairAccessibleEntrance == true)
          .toList();
      if (filtered.isNotEmpty) {
        places = filtered;
      }
    }

    return NearbyPlacesResult(
      places: places,
      barriers: barriersRaw
          .whereType<Map<String, dynamic>>()
          .map(BarrierPin.fromRpcJson)
          .toList(),
    );
  }
}

final routesRepoProvider = Provider<RoutesRepo>(
  (ref) => RoutesRepo(ref.read(bffClientProvider)),
);
