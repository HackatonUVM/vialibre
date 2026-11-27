import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:vialibre/app/theme/vialibre_theme.dart';
import 'package:vialibre/core/config/env.dart';
import 'package:vialibre/core/widgets/accessible_button.dart';
import 'package:vialibre/core/widgets/tactile_press.dart';
import 'package:vialibre/features/explore/presentation/explore_screen.dart';
import 'package:vialibre/features/profile/data/profile_prefs_repo.dart';
import '../data/barriers_realtime_repo.dart';
import '../data/routes_repo.dart';
import '../domain/accessible_place_model.dart';
import '../domain/barrier_model.dart';
import '../domain/transit_route_model.dart';
import 'widgets/accessible_places_sheet.dart';
import 'widgets/barrier_detail_sheet.dart';
import 'widgets/first_timer_guide_sheet.dart';
import 'widgets/transit_routes_sheet.dart';

/// Mapa multimodal edge-to-edge con marcadores accesibles, clustering,
/// `betaWarning`, barreras en vivo y soporte Claro/Oscuro.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  static const LatLng _defaultCenter = LatLng(19.4326, -99.1332);
  static const MethodChannel _configChannel = MethodChannel('mx.vialibre/config');

  static const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1d1d1f"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#b8b8c4"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#141416"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#2c2c34"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3a3a46"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#121622"}]}
]
''';

  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  final TextEditingController _searchController = TextEditingController();
  final ClusterManager _clusterManager = ClusterManager(
    clusterManagerId: const ClusterManagerId('barriers_cluster'),
  );

  LatLng _currentCenter = _defaultCenter;
  bool? _hasMapsApiKey;
  bool _hasLocationPermission = false;
  bool _isSearching = false;
  String? _statusMessage;
  String? _betaWarning;
  String _activeCategoryChip = 'all';

  BitmapDescriptor? _rampMarkerIcon;
  BitmapDescriptor? _sidewalkMarkerIcon;
  BitmapDescriptor? _placeMarkerIcon;

  List<BarrierPin> _barriers = const [];
  List<AccessiblePlace> _places = const [];
  List<TransitRouteOption> _routes = const [];
  TransitRouteOption? _selectedRoute;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkerIcons();
    _checkMapsKeyAndInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pending = ref.read(pendingMapIntentProvider);
      if (pending != null) {
        _consumeIntent(pending);
      }
    });
  }

  Future<void> _loadCustomMarkerIcons() async {
    try {
      const config = ImageConfiguration(size: Size(40, 40));
      final results = await Future.wait([
        BitmapDescriptor.asset(config, 'assets/markers/barrier_ramp.png'),
        BitmapDescriptor.asset(config, 'assets/markers/barrier_sidewalk.png'),
        BitmapDescriptor.asset(config, 'assets/markers/accessible_place.png'),
      ]);
      if (!mounted) return;
      setState(() {
        _rampMarkerIcon = results[0];
        _sidewalkMarkerIcon = results[1];
        _placeMarkerIcon = results[2];
      });
    } catch (_) {}
  }

  Future<void> _checkMapsKeyAndInit() async {
    var hasKey = false;
    try {
      final res = await _configChannel.invokeMethod<bool>('hasMapsApiKey');
      hasKey = res ?? false;
    } catch (_) {
      hasKey = false;
    }
    if (!mounted) return;
    setState(() => _hasMapsApiKey = hasKey);
    await _initLocationAndRealtime();
  }

  void _consumeIntent(ExploreMapIntent intent) {
    ref.read(pendingMapIntentProvider.notifier).state = null;
    if (intent.destinationQuery != null &&
        intent.destinationQuery!.isNotEmpty) {
      _searchController.text = intent.destinationQuery!;
      _searchRoutes(intent.destinationQuery);
    } else if (intent.categoryKey != null && intent.placesQuery != null) {
      _searchCategoryPlaces(
        intent.categoryKey!,
        intent.placesQuery!,
        onlyWheelchair: intent.onlyWheelchair,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocationAndRealtime() async {
    ref.read(barriersRealtimeRepoProvider).subscribeToLiveUpdates(() {
      _refreshNearbyBarriers();
    });

    await _resolveUserLocation();
    await _refreshNearbyBarriers();
  }

  Future<void> _resolveUserLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      final granted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      if (!mounted) return;
      setState(() => _hasLocationPermission = granted);

      if (!granted) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 6),
        ),
      );
      if (!mounted) return;

      final target = LatLng(position.latitude, position.longitude);
      setState(() => _currentCenter = target);

      if (_mapController.isCompleted) {
        final ctrl = await _mapController.future;
        await ctrl.animateCamera(CameraUpdate.newLatLngZoom(target, 15.5));
      }
    } catch (_) {}
  }

  Future<void> _refreshNearbyBarriers() async {
    try {
      final items = await ref.read(barriersRealtimeRepoProvider).fetchNearby(
            lat: _currentCenter.latitude,
            lng: _currentCenter.longitude,
          );
      if (!mounted) return;
      setState(() => _barriers = items);
    } catch (_) {}
  }

  Future<void> _locateMe() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      final target = LatLng(pos.latitude, pos.longitude);
      final ctrl = await _mapController.future;
      await ctrl.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
      setState(() {
        _currentCenter = target;
        _hasLocationPermission = true;
        _statusMessage = 'Ubicación centrada';
      });
      await _refreshNearbyBarriers();
    } catch (_) {
      setState(() {
        _statusMessage = 'Activa los permisos de ubicación para centrar el mapa.';
      });
    }
  }

  Future<void> _searchRoutes([String? overrideQuery]) async {
    final query = (overrideQuery ?? _searchController.text).trim();
    if (query.isEmpty) {
      setState(() {
        _statusMessage = 'Escribe un destino o estación para buscar rutas.';
      });
      return;
    }

    final prefs = ref.read(profileControllerProvider).valueOrNull;
    final profile = prefs?.profile.keyName ?? 'wheelchair';
    final firstTimer = prefs?.firstTimerMode ?? true;
    final avoidSlopes = prefs?.avoidSlopes ?? true;
    final maxSlope = prefs?.maxSlopePercent ?? 8.0;

    setState(() {
      _isSearching = true;
      _statusMessage = null;
      _betaWarning = null;
    });

    try {
      final res = await ref.read(routesRepoProvider).fetchAccessibleRoutes(
            originLat: _currentCenter.latitude,
            originLng: _currentCenter.longitude,
            destinationQuery: query,
            profile: profile,
            avoidSlopes: avoidSlopes,
            maxSlopePercent: maxSlope,
            includeFirstTimerGuide: firstTimer,
          );
      if (!mounted) return;

      setState(() {
        _routes = res.routes;
        _betaWarning = res.betaWarning;
        _selectedRoute = res.routes.isNotEmpty ? res.routes.first : null;
        if (res.resolvedDestination != null) {
          _places = [res.resolvedDestination!];
        }
        _statusMessage = res.routes.isEmpty
            ? 'No encontramos rutas disponibles para "$query".'
            : null;
      });

      if (res.routes.isNotEmpty) {
        await _fitRouteOnMap(res.routes.first, res.resolvedDestination);
        if (!mounted) return;
        _openRoutesSheet(res.resolvedDestination?.name ?? query);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage =
            'Conecta el servidor backend para calcular rutas en vivo ($e).';
      });
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _searchCategoryPlaces(
    String key,
    String query, {
    bool onlyWheelchair = false,
  }) async {
    setState(() {
      _activeCategoryChip = key;
      _isSearching = true;
      _statusMessage = null;
    });

    try {
      final res = await ref.read(routesRepoProvider).fetchNearbyAccessiblePlaces(
            lat: _currentCenter.latitude,
            lng: _currentCenter.longitude,
            query: query,
            onlyWheelchairAccessible: onlyWheelchair,
          );
      if (!mounted) return;

      setState(() {
        _places = res.places;
        if (res.barriers.isNotEmpty) {
          _barriers = res.barriers;
        }
      });

      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => AccessiblePlacesSheet(
          places: res.places,
          onSelectPlace: (place) {
            _searchController.text = place.name;
            _searchRoutes(place.name);
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Conecta el backend para consultar paradas cercanas: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _fitRouteOnMap(
    TransitRouteOption route,
    AccessiblePlace? dest,
  ) async {
    if (!_mapController.isCompleted) return;
    final points = _decodePolyline(route.encodedPolyline);
    if (points.length < 2) {
      if (dest != null) {
        final ctrl = await _mapController.future;
        await ctrl.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(dest.lat, dest.lng), 15),
        );
      }
      return;
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final pt in points) {
      if (pt.latitude < minLat) minLat = pt.latitude;
      if (pt.latitude > maxLat) maxLat = pt.latitude;
      if (pt.longitude < minLng) minLng = pt.longitude;
      if (pt.longitude > maxLng) maxLng = pt.longitude;
    }

    final ctrl = await _mapController.future;
    await ctrl.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        64,
      ),
    );
  }

  void _openRoutesSheet(String destinationName) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TransitRoutesSheet(
        destinationName: destinationName,
        routes: _routes,
        selectedRouteId: _selectedRoute?.id,
        onSelectRoute: (route) {
          setState(() => _selectedRoute = route);
          Navigator.of(context).pop();
          _fitRouteOnMap(route, null);
        },
        onOpenFirstTimerGuide: (route) {
          Navigator.of(context).pop();
          _openFirstTimerGuide(route);
        },
      ),
    );
  }

  void _openFirstTimerGuide(TransitRouteOption route) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FirstTimerGuideSheet(route: route),
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    for (final barrier in _barriers) {
      final icon = barrier.isSidewalkOrSlope
          ? (_sidewalkMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange))
          : (_rampMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                barrier.severity >= 4
                    ? BitmapDescriptor.hueRed
                    : BitmapDescriptor.hueOrange,
              ));

      markers.add(
        Marker(
          markerId: MarkerId('barrier_${barrier.id}'),
          position: LatLng(barrier.lat, barrier.lng),
          clusterManagerId: _clusterManager.clusterManagerId,
          icon: icon,
          infoWindow: InfoWindow(
            title: barrier.title,
            snippet: '${barrier.categoryLabel} · Toca para detalles',
          ),
          onTap: () {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => BarrierDetailSheet(
                barrier: barrier,
                onResolved: _refreshNearbyBarriers,
              ),
            );
          },
        ),
      );
    }

    for (final place in _places) {
      markers.add(
        Marker(
          markerId: MarkerId('place_${place.placeId}'),
          position: LatLng(place.lat, place.lng),
          icon: _placeMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                place.wheelchairAccessibleEntrance == true
                    ? BitmapDescriptor.hueGreen
                    : BitmapDescriptor.hueAzure,
              ),
          infoWindow: InfoWindow(
            title: place.name,
            snippet: place.wheelchairAccessibleEntrance == true
                ? 'Entrada accesible'
                : place.address,
          ),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines(ViaLibrePalette p) {
    final selected = _selectedRoute;
    if (selected == null) return const {};
    final points = _decodePolyline(selected.encodedPolyline);
    if (points.isEmpty) return const {};

    return {
      Polyline(
        polylineId: PolylineId('route_${selected.id}'),
        points: points,
        color: p.coral,
        width: 7,
      ),
    };
  }

  List<LatLng> _decodePolyline(String? encoded) {
    if (encoded == null || encoded.isEmpty) return const [];
    final poly = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      var shift = 0;
      var result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < encoded.length);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < encoded.length);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ExploreMapIntent?>(pendingMapIntentProvider, (_, next) {
      if (next != null) {
        _consumeIntent(next);
      }
    });

    final p = ViaLibreTheme.paletteOf(context);
    final prefs = ref.watch(profileControllerProvider).valueOrNull;
    final activeProfileLabel = prefs?.profile.label ?? 'Silla de ruedas';
    final hasMapId = Env.googleMapsMapId.isNotEmpty;

    return Scaffold(
      body: Stack(
        children: [
          if (_hasMapsApiKey == true)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentCenter,
                zoom: 15,
              ),
              cloudMapId: hasMapId ? Env.googleMapsMapId : null,
              style: (!hasMapId && p.isDark) ? _darkMapStyle : null,

              padding: const EdgeInsets.only(top: 132, bottom: 96),
              myLocationEnabled: _hasLocationPermission,
              myLocationButtonEnabled: _hasLocationPermission,
              compassEnabled: true,
              zoomControlsEnabled: false,
              clusterManagers: {_clusterManager},
              markers: _buildMarkers(),
              polylines: _buildPolylines(p),
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                ),
              },
              onMapCreated: (GoogleMapController controller) {
                if (!_mapController.isCompleted) {
                  _mapController.complete(controller);
                }
              },
            )
          else
            _MapsKeyPreviewPlaceholder(
              isLoading: _hasMapsApiKey == null,
              barriersCount: _barriers.length,
            ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
                          decoration: BoxDecoration(
                            color: p.card,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: p.border),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x18000000),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search_rounded, color: p.muted),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  textInputAction: TextInputAction.search,
                                  style: const TextStyle(fontSize: 16),
                                  decoration: const InputDecoration(
                                    hintText: '¿A dónde vas? Ej. Metro Hidalgo',
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                  onSubmitted: (_) => _searchRoutes(),
                                ),
                              ),
                              Semantics(
                                button: true,
                                label: 'Buscar rutas accesibles',
                                child: TactilePress(
                                  borderRadius: 24,
                                  onTap: _isSearching ? null : _searchRoutes,
                                  child: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: p.ctaBg,
                                      shape: BoxShape.circle,
                                    ),
                                    child: _isSearching
                                        ? Center(
                                            child: SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: p.ctaFg,
                                              ),
                                            ),
                                          )
                                        : Icon(
                                            Icons.directions_rounded,
                                            color: p.ctaFg,
                                            size: 20,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Semantics(
                        button: true,
                        label: 'Abrir perfil y preferencias de accesibilidad',
                        child: TactilePress(
                          borderRadius: 24,
                          onTap: () => context.push('/profile'),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: p.card,
                              shape: BoxShape.circle,
                              border: Border.all(color: p.border),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x18000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.person_outline_rounded,
                              color: p.ink,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterPill(
                          label: activeProfileLabel,
                          selected: _activeCategoryChip == 'all',
                          onTap: () => context.push('/profile'),
                        ),
                        const SizedBox(width: 8),
                        _FilterPill(
                          label: 'Metro',
                          selected: _activeCategoryChip == 'metro',
                          onTap: () => _searchCategoryPlaces(
                            'metro',
                            'estación metro accesible',
                          ),
                        ),
                        const SizedBox(width: 8),
                        _FilterPill(
                          label: 'Metrobús',
                          selected: _activeCategoryChip == 'metrobus',
                          onTap: () => _searchCategoryPlaces(
                            'metrobus',
                            'estación metrobús',
                          ),
                        ),
                        const SizedBox(width: 8),
                        _FilterPill(
                          label: 'Camión',
                          selected: _activeCategoryChip == 'camion',
                          onTap: () => _searchCategoryPlaces(
                            'camion',
                            'parada camión autobús',
                          ),
                        ),
                        const SizedBox(width: 8),
                        _FilterPill(
                          label: 'Rampas',
                          selected: _activeCategoryChip == 'rampas',
                          onTap: () => _searchCategoryPlaces(
                            'rampas',
                            'entrada accesible rampa clínica',
                            onlyWheelchair: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: p.card.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: p.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: p.coral,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Herramienta asistiva; no sustituye bastón blanco, perro guía ni señalización vial.',
                            style: TextStyle(
                              color: p.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_betaWarning != null) ...[
                    const SizedBox(height: 10),
                    Semantics(
                      liveRegion: true,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: p.amberSoft,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: p.border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: p.amberInk,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _betaWarning!,
                                style: TextStyle(
                                  color: p.amberInk,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  setState(() => _betaWarning = null),
                              icon: Icon(
                                Icons.close_rounded,
                                color: p.amberInk,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: p.ctaBg,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _statusMessage!,
                              style: TextStyle(color: p.ctaFg),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                setState(() => _statusMessage = null),
                            icon: Icon(
                              Icons.close_rounded,
                              color: p.ctaFg,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: _selectedRoute != null ? 240 : 110,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  button: true,
                  label: 'Actualizar barreras reportadas cerca',
                  child: FloatingActionButton.small(
                    heroTag: 'fab_refresh_barriers',
                    backgroundColor: p.card,
                    foregroundColor: p.ink,
                    onPressed: () async {
                      setState(() => _statusMessage = 'Actualizando barreras...');
                      await _refreshNearbyBarriers();
                      if (mounted) {
                        setState(() => _statusMessage = '${_barriers.length} barreras reportadas cerca');
                      }
                    },
                    child: const Icon(Icons.refresh_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                Semantics(
                  button: true,
                  label: 'Mi ubicación actual',
                  child: FloatingActionButton.small(
                    heroTag: 'fab_my_location',
                    backgroundColor: p.card,
                    foregroundColor: p.coral,
                    onPressed: _locateMe,
                    child: const Icon(Icons.my_location_rounded),
                  ),
                ),
              ],
            ),
          ),
          if (_selectedRoute != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 98,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_selectedRoute!.summaryLabel} · ${_selectedRoute!.durationMinutes} min',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _openRoutesSheet(
                              _searchController.text.isEmpty
                                  ? 'Destino'
                                  : _searchController.text,
                            ),
                            child: Text(
                              'Ver otras',
                              style: TextStyle(
                                color: p.coral,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AccessibleButton(
                        label: 'Abrir guía Modo Primera Vez',
                        icon: Icons.record_voice_over_rounded,
                        onPressed: () =>
                            _openFirstTimerGuide(_selectedRoute!),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = ViaLibreTheme.paletteOf(context);
    return TactilePress(
      borderRadius: 24,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? p.ctaBg : p.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? p.ctaBg : p.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? p.ctaFg : p.ink,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _MapsKeyPreviewPlaceholder extends StatelessWidget {
  const _MapsKeyPreviewPlaceholder({
    required this.isLoading,
    required this.barriersCount,
  });

  final bool isLoading;
  final int barriersCount;

  @override
  Widget build(BuildContext context) {
    final p = ViaLibreTheme.paletteOf(context);
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.sand, p.canvas],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 140, 24, 110),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: p.lavender,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.map_rounded,
                      size: 30,
                      color: p.lavenderInk,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Mapa listo para conectar Google Maps',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Agrega MAPS_API_KEY en android/local.properties o GOOGLE_MAPS_ANDROID_KEY para ver el mapa ($barriersCount obstáculos en zona).',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
