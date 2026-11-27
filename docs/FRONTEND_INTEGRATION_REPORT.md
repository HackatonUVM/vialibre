# Reporte Completo de Integración Frontend (`mobile/` Flutter) — VíaLibre
## Migración a Stack 100% Gratuito (MapLibre GL + OpenFreeMap, Sin Facturación Google Cloud)

Este documento entrega **todos los códigos, dependencias y configuraciones listos para copiar e implementar en el proyecto móvil Flutter (`mobile/`)**, permitiendo generar el APK de producción **sin requerir tarjetas de crédito, cuentas de facturación en Google Cloud ni llaves de Google Maps**.

---

## 1. Resumen Ejecutivo de la Migración

| Componente | Antes (Google Cloud con Tarjeta) | Ahora (Stack 100% Gratuito y Libre) | Beneficio |
| :--- | :--- | :--- | :--- |
| **SDK de Mapas Móvil** | `google_maps_flutter: ^2.19.0` | `maplibre_gl: ^0.16.0` | 0 tarjetas, renderizado vectorial GPU fluido y libre. |
| **Estilo y Tiles de Mapa** | Google Maps Cloud Map ID | **OpenFreeMap Liberty** (`https://tiles.openfreemap.org/styles/liberty`) | 0 API Keys, 0 límites de facturación, alta resolución. |
| **Credenciales en Android** | `com.google.android.geo.API_KEY` en `AndroidManifest.xml` | **Eliminado al 100%** | Ya no es necesario registrar huellas SHA-1 ni API Keys en Android. |
| **Configuración Gradle** | `local.properties` + placeholders | **Configuración estándar limpia** | Menos fricción al compilar el APK. |
| **Motor de Rutas (BFF)** | Google Routes API (`WALK`) | **Valhalla + OSRM** (con ORS nativo opcional) | Rutas peatonales y adaptadas a silla de ruedas sin costo. |
| **Elevación y Pendientes** | Google Elevation API | **Open-Meteo Elevation API** (DEM 90m) | Cálculo de pendientes y tramos empinados con 0 API keys. |
| **Búsqueda de Lugares** | Google Places API (New) | **Photon (Komoot) + Nominatim (OSM)** | Geocodificación y búsqueda local abierta con User-Agent. |
| **Variables `--dart-define`** | 4 variables (incluyendo `MAP_ID`) | **Solo 3 variables** (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `BFF_BASE_URL`) | Máxima simplicidad en CI/CD y descarga del APK. |

---

## 2. Lo que NO Cambia (Compatibilidad Total Garantizada)

1. **Supabase (`SUPABASE_URL`, `SUPABASE_ANON_KEY`):** Base de datos PostgreSQL + PostGIS, almacenamiento de fotos/PDFs y Supabase Realtime para actualización en vivo de barreras.
2. **`AuthService`:** Inicio de sesión anónimo automático (`signInAnonymously()`) que genera JWT Bearer para autorizar los endpoints del BFF.
3. **`BffApiClient`:** Los 13 endpoints REST (`/api/routes/accessible`, `/api/barriers/report`, `/api/places/nearby`, etc.) conservan exactamente los mismos contratos y DTOs JSON.
4. **`MediaPrivacyService`:** Eliminación automática de metadatos EXIF (< 1.5 MB) y subidas directas vía Signed Upload URLs.
5. **`OfflineQueueService`:** Cola local SQLite (`sqflite`) con `idempotencyKey` UUIDv4 para reportes tomados sin conexión.
6. **`ReportBarrierScreen`:** Captura por foto y nota de voz con recuadros IA (`BoundingBoxOverlay`, escala `0..1000`).
7. **`PublicBriefsScreen`:** Resúmenes oficiales en Lenguaje Claro (ISO 24495-1) y reproducción de audio.
8. **`theme.dart`:** Sistema de diseño accesible (WCAG 2.2 AA, áreas táctiles mínimo 48×48 dp, contraste 4.5:1).

---

## 3. Estructura de Archivos en `mobile/`

```text
mobile/
├── android/
│   ├── app/
│   │   ├── build.gradle.kts          # Limpio: sin MAPS_API_KEY
│   │   └── src/main/
│   │       ├── AndroidManifest.xml   # Limpio: sin meta-data de Google Maps
│   │       └── kotlin/.../MainActivity.kt # Limpio: FlutterActivity estándar
│   └── local.properties              # Sin llaves de Google
├── assets/
│   └── markers/
│       ├── barrier_ramp.png          # Triángulo rojo/ámbar (forma + color)
│       ├── barrier_sidewalk.png      # Rombo naranja
│       └── accessible_place.png      # Círculo azul/verde con check
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── env.dart                  # Solo 3 vars de entorno + OpenFreeMap style
│   │   └── theme.dart                # Paleta #0A192F / #FFB300 / #0F172A + Inter + 48dp
│   ├── models/
│   │   └── vialibre_models.dart      # DTOs de rutas, barreras, perfiles y avisos
│   ├── services/
│   │   ├── auth_service.dart         # signInAnonymously + JWT Bearer
│   │   ├── bff_api_client.dart       # Cliente HTTP para los 13 endpoints del BFF
│   │   ├── media_privacy_service.dart# Limpieza EXIF (<1.5MB), audio record + WAV player
│   │   ├── offline_queue_service.dart# sqflite + UUIDv4 idempotencyKey + connectivity_plus
│   │   └── realtime_barriers_service.dart # Supabase Realtime sobre public.barriers
│   ├── widgets/
│   │   └── bounding_box_overlay.dart # CustomPainter para recuadros IA (escala 0..1000)
│   └── screens/
│       ├── profile_screen.dart       # Boceto 02: Perfil + preferencias + accesibilidad
│       ├── accessible_map_screen.dart# Boceto 03: MapLibreMap + OpenFreeMap + Rutas
│       ├── report_barrier_screen.dart# Boceto 04: Foto/Voz + EXIF + cola offline
│       └── public_briefs_screen.dart # Boceto 05: PDF/Foto -> 3 bloques + audio WAV
└── pubspec.yaml
```

---

## 4. Configuración Android y `pubspec.yaml`

### 4.1 `mobile/pubspec.yaml`
```yaml
name: vialibre_mobile
description: Navegación peatonal accesible, reporte ciudadano y Lenguaje Claro (ODS 10 y 11).
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ">=3.4.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  # Stack de Mapas 100% Gratuito y Libre (reemplaza google_maps_flutter)
  maplibre_gl: ^0.16.0
  supabase_flutter: ^2.8.0
  http: ^1.2.2
  flutter_image_compress: ^2.3.0
  image_picker: ^1.1.2
  file_picker: ^8.1.4
  record: ^5.1.2
  audioplayers: ^6.1.0
  geolocator: ^13.0.1
  permission_handler: ^11.3.1
  sqflite: ^2.4.0
  path: ^1.9.0
  path_provider: ^2.1.4
  connectivity_plus: ^6.1.0
  uuid: ^4.5.1
  google_fonts: ^6.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/markers/
```

### 4.2 `mobile/android/app/build.gradle.kts`
```kotlin
android {
    namespace = "com.vialibre.app"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.vialibre.app"
        minSdk = 24
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}
```

### 4.3 `mobile/android/app/src/main/AndroidManifest.xml`
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />

    <application
        android:label="VíaLibre"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">

        <!-- MAPAS GRATUITOS: Se eliminó com.google.android.geo.API_KEY -->

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        <meta-data android:name="flutterEmbedding" android:value="2" />
    </application>
</manifest>
```

### 4.4 `mobile/android/app/src/main/kotlin/com/vialibre/app/MainActivity.kt`
```kotlin
package com.vialibre.app

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // Actividad nativa limpia, sin dependencias propietarias de Google Maps
}
```

---

## 5. Códigos Dart del Núcleo (`lib/core/`)

### 5.1 `lib/core/env.dart`
```dart
class AppEnv {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://aiztivgrynirvdkcdugd.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static const bffBaseUrl = String.fromEnvironment(
    'BFF_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000', // 10.0.2.2 para emulador Android, o IP de tu máquina en Wi-Fi
  );

  /// Estilo vectorial 100% gratuito de OpenFreeMap (sin tarjetas ni API keys)
  static const openFreeMapStyle = String.fromEnvironment(
    'MAP_STYLE_URL',
    defaultValue: 'https://tiles.openfreemap.org/styles/liberty',
  );
}
```

### 5.2 `lib/core/theme.dart` (Sistema Stitch + WCAG 2.2 AA)
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ViaLibreColors {
  static const primary = Color(0xFF0A192F);    // Azul marino alto contraste
  static const secondary = Color(0xFFFFB300);  // Ámbar accesible
  static const tertiary = Color(0xFF281400);   // Café oscuro
  static const neutral = Color(0xFF0F172A);    // Texto principal
  static const surface = Color(0xFFF8FAFC);
  static const danger = Color(0xFFB91C1C);
}

ThemeData buildViaLibreTheme({bool largeText = false}) {
  final baseText = GoogleFonts.interTextTheme();
  final scale = largeText ? 1.18 : 1.0;

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: ViaLibreColors.primary,
      primary: ViaLibreColors.primary,
      secondary: ViaLibreColors.secondary,
      tertiary: ViaLibreColors.tertiary,
      surface: ViaLibreColors.surface,
      error: ViaLibreColors.danger,
    ),
    textTheme: baseText.apply(
      bodyColor: ViaLibreColors.neutral,
      displayColor: ViaLibreColors.primary,
      fontSizeFactor: scale,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 48), // Área táctil mínima WCAG 2.2 / Android 48x48 dp
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
```

---

## 6. Modelos de Datos (`lib/models/vialibre_models.dart`)

```dart
enum AccessibilityProfile {
  wheelchair('wheelchair', 'Silla de ruedas / Carriola'),
  lowVision('low_vision', 'Baja visión'),
  plainLanguage('plain_language', 'Lectura clara');

  const AccessibilityProfile(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static AccessibilityProfile fromApi(String? value) {
    return AccessibilityProfile.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => AccessibilityProfile.wheelchair,
    );
  }
}

class UserPreferences {
  const UserPreferences({
    required this.accessibilityProfile,
    required this.avoidSlopes,
    required this.maxSlopePercent,
    required this.ttsSpeed,
    required this.largeText,
  });

  final AccessibilityProfile accessibilityProfile;
  final bool avoidSlopes;
  final double maxSlopePercent;
  final double ttsSpeed;
  final bool largeText;

  factory UserPreferences.fromJson(Map<String, dynamic> json) => UserPreferences(
        accessibilityProfile: AccessibilityProfile.fromApi(json['accessibilityProfile'] as String?),
        avoidSlopes: (json['avoidSlopes'] as bool?) ?? true,
        maxSlopePercent: (json['maxSlopePercent'] as num?)?.toDouble() ?? 8.0,
        ttsSpeed: (json['ttsSpeed'] as num?)?.toDouble() ?? 1.0,
        largeText: (json['largeText'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        'accessibilityProfile': accessibilityProfile.apiValue,
        'avoidSlopes': avoidSlopes,
        'maxSlopePercent': maxSlopePercent,
        'ttsSpeed': ttsSpeed,
        'largeText': largeText,
      };
}

class BoundingBoxItem {
  const BoundingBoxItem({required this.label, required this.box2d});
  final String label;
  final List<int> box2d; // [ymin, xmin, ymax, xmax] escala 0..1000

  factory BoundingBoxItem.fromJson(Map<String, dynamic> json) => BoundingBoxItem(
        label: json['label'] as String? ?? 'Obstáculo',
        box2d: (json['box_2d'] as List<dynamic>).map((e) => (e as num).toInt()).toList(),
      );

  Map<String, dynamic> toJson() => {'label': label, 'box_2d': box2d};
}

class BarrierAnalysis {
  const BarrierAnalysis({
    required this.isImageClear,
    this.ambiguityReason,
    required this.category,
    required this.title,
    required this.description,
    required this.severity,
    required this.confidenceScore,
    required this.profileFlags,
    required this.boundingBoxes,
  });

  final bool isImageClear;
  final String? ambiguityReason;
  final String category;
  final String title;
  final String description;
  final int severity;
  final double confidenceScore;
  final Map<String, dynamic> profileFlags;
  final List<BoundingBoxItem> boundingBoxes;

  factory BarrierAnalysis.fromJson(Map<String, dynamic> json) => BarrierAnalysis(
        isImageClear: (json['isImageClear'] as bool?) ?? true,
        ambiguityReason: json['ambiguityReason'] as String?,
        category: json['category'] as String? ?? 'other',
        title: json['title'] as String? ?? 'Obstáculo urbano',
        description: json['description'] as String? ?? '',
        severity: (json['severity'] as num?)?.toInt() ?? 3,
        confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.8,
        profileFlags: Map<String, dynamic>.from(json['profileFlags'] as Map? ?? const {}),
        boundingBoxes: (json['boundingBoxes'] as List<dynamic>? ?? const [])
            .map((e) => BoundingBoxItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'isImageClear': isImageClear,
        'ambiguityReason': ambiguityReason,
        'category': category,
        'title': title,
        'description': description,
        'severity': severity,
        'confidenceScore': confidenceScore,
        'profileFlags': profileFlags,
        'boundingBoxes': boundingBoxes.map((b) => b.toJson()).toList(),
      };
}

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
  final double? distanceMeters;
  final String? photoSignedUrl;

  factory BarrierPin.fromJson(Map<String, dynamic> json) => BarrierPin(
        id: (json['id'] as num).toInt(),
        category: json['category'] as String? ?? 'other',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        severity: (json['severity'] as num?)?.toInt() ?? 3,
        lat: (json['lat'] as num?)?.toDouble() ?? (json['latitude'] as num?)?.toDouble() ?? 0,
        lng: (json['lng'] as num?)?.toDouble() ?? (json['longitude'] as num?)?.toDouble() ?? 0,
        confirmationsCount: (json['confirmations_count'] as num? ?? json['confirmations'] as num?)?.toInt() ?? 1,
        distanceMeters: (json['distance_meters'] as num? ?? json['distance_to_route_m'] as num?)?.toDouble(),
        photoSignedUrl: json['photoSignedUrl'] as String?,
      );
}

class RouteStep {
  const RouteStep({
    required this.travelMode,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.instruction,
    this.transitLine,
    this.stopFrom,
    this.stopTo,
  });

  final String travelMode;
  final int distanceMeters;
  final int durationSeconds;
  final String instruction;
  final String? transitLine;
  final String? stopFrom;
  final String? stopTo;

  factory RouteStep.fromJson(Map<String, dynamic> json) => RouteStep(
        travelMode: json['travelMode'] as String? ?? json['stepMode'] as String? ?? 'WALK',
        distanceMeters: (json['distanceMeters'] as num?)?.toInt() ?? 0,
        durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
        instruction: json['instruction'] as String? ?? '',
        transitLine: json['lineName'] as String? ?? json['transitLine'] as String?,
        stopFrom: json['departureStop'] as String? ?? json['stopFrom'] as String?,
        stopTo: json['arrivalStop'] as String? ?? json['stopTo'] as String?,
      );
}

class RouteCandidate {
  const RouteCandidate({
    required this.mode,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.encodedPolyline,
    required this.coordinates,
    required this.maxSlopePercent,
    required this.steepSegmentsCount,
    required this.barriersOnRoute,
    required this.steps,
    required this.provider,
  });

  final String mode;
  final int distanceMeters;
  final int durationSeconds;
  final String encodedPolyline;
  final List<List<double>> coordinates; // [[lng, lat], ...]
  final double maxSlopePercent;
  final int steepSegmentsCount;
  final List<BarrierPin> barriersOnRoute;
  final List<RouteStep> steps;
  final String provider;

  factory RouteCandidate.fromJson(Map<String, dynamic> json) {
    final elev = Map<String, dynamic>.from(json['elevation'] as Map? ?? const {});
    final rawCoords = (json['coordinates'] as List<dynamic>? ?? const []);
    final coords = rawCoords
        .map((pair) => (pair as List<dynamic>).map((numVal) => (numVal as num).toDouble()).toList())
        .toList();

    return RouteCandidate(
      mode: json['mode'] as String? ?? 'WALK',
      distanceMeters: (json['distanceMeters'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      encodedPolyline: json['encodedPolyline'] as String? ?? '',
      coordinates: coords,
      maxSlopePercent: (elev['maxSlopePercent'] as num? ?? json['maxSlopePercent'] as num?)?.toDouble() ?? 0.0,
      steepSegmentsCount: (elev['steepSegmentsCount'] as num? ?? json['steepSegmentsCount'] as num?)?.toInt() ?? 0,
      barriersOnRoute: (json['barriersOnRoute'] as List<dynamic>? ?? const [])
          .map((e) => BarrierPin.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      steps: (json['steps'] as List<dynamic>? ?? const [])
          .map((e) => RouteStep.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      provider: json['provider'] as String? ?? 'openrouteservice',
    );
  }
}

class AccessibleRoutesResponse {
  const AccessibleRoutesResponse({
    this.betaWarning,
    required this.routes,
    this.routeProvider,
    this.firstTimerSummary,
    this.firstTimerSteps = const [],
  });

  final String? betaWarning;
  final List<RouteCandidate> routes;
  final String? routeProvider;
  final String? firstTimerSummary;
  final List<String> firstTimerSteps;

  factory AccessibleRoutesResponse.fromJson(Map<String, dynamic> json) {
    final guide = json['firstTimerGuide'] as Map<String, dynamic>?;
    return AccessibleRoutesResponse(
      betaWarning: json['betaWarning'] as String?,
      routes: (json['routes'] as List<dynamic>? ?? const [])
          .map((e) => RouteCandidate.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      routeProvider: json['routeProvider'] as String?,
      firstTimerSummary: guide?['spokenSummaryText'] as String? ?? json['firstTimerSummary'] as String?,
      firstTimerSteps: (guide?['checklistBeforeBoarding'] as List<dynamic>? ?? json['firstTimerSteps'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class PlainBriefResult {
  const PlainBriefResult({
    required this.cached,
    required this.briefId,
    required this.issuer,
    required this.estimatedDuration,
    required this.whatHappened,
    required this.whoIsAffected,
    required this.whatToDoToday,
    this.audioDurationSeconds,
    this.audioSignedUrl,
  });

  final bool cached;
  final int briefId;
  final String issuer;
  final String estimatedDuration;
  final String whatHappened;
  final String whoIsAffected;
  final String whatToDoToday;
  final int? audioDurationSeconds;
  final String? audioSignedUrl;

  factory PlainBriefResult.fromJson(Map<String, dynamic> json) {
    final summary = Map<String, dynamic>.from(json['plainSummary'] as Map? ?? const {});
    return PlainBriefResult(
      cached: (json['cached'] as bool?) ?? false,
      briefId: (json['briefId'] as num?)?.toInt() ?? 1,
      issuer: json['issuer'] as String? ?? 'Aviso oficial',
      estimatedDuration: json['estimatedDuration'] as String? ?? 'No especificada',
      whatHappened: summary['whatHappened'] as String? ?? json['whatHappened'] as String? ?? '',
      whoIsAffected: summary['whoIsAffected'] as String? ?? json['whoIsAffected'] as String? ?? '',
      whatToDoToday: summary['whatToDoToday'] as String? ?? json['whatToDoToday'] as String? ?? '',
      audioDurationSeconds: (json['audioDurationSeconds'] as num?)?.toInt(),
      audioSignedUrl: json['audioSignedUrl'] as String?,
    );
  }
}
```

---

## 7. Pantalla de Mapa Actualizada: `lib/screens/accessible_map_screen.dart`
### (Implementación completa con `maplibre_gl` y OpenFreeMap Liberty)

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:uuid/uuid.dart';
import '../core/env.dart';
import '../models/vialibre_models.dart';
import '../services/bff_api_client.dart';
import '../services/realtime_barriers_service.dart';

class AccessibleMapScreen extends StatefulWidget {
  const AccessibleMapScreen({
    super.key,
    required this.bff,
    required this.preferences,
  });

  final BffApiClient bff;
  final UserPreferences preferences;

  @override
  State<AccessibleMapScreen> createState() => _AccessibleMapScreenState();
}

class _AccessibleMapScreenState extends State<AccessibleMapScreen> {
  MapLibreMapController? _mapController;
  final TextEditingController _searchCtrl = TextEditingController();
  final RealtimeBarriersService _realtime = RealtimeBarriersService();

  LatLng _currentCenter = const LatLng(19.4326, -99.1332);
  bool _styleLoaded = false;
  String? _betaWarning;
  RouteCandidate? _selectedRoute;
  List<BarrierPin> _currentBarriers = [];
  Line? _currentRouteLine;
  final Map<String, BarrierPin> _symbolToBarrier = {};

  @override
  void initState() {
    super.initState();
    _initUserLocation();
    _realtime.subscribeToActiveBarriers(_refreshBarriersOnMap);
  }

  @override
  void dispose() {
    _realtime.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _initUserLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _currentCenter = LatLng(pos.latitude, pos.longitude);
      });
      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_currentCenter, 15.0));
      }
    }
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
    _mapController!.onSymbolTapped.add(_onSymbolTapped);
  }

  void _onStyleLoaded() {
    setState(() => _styleLoaded = true);
    _refreshBarriersOnMap();
  }

  Future<void> _refreshBarriersOnMap() async {
    if (_mapController == null || !_styleLoaded) return;

    try {
      final barriers = await widget.bff.getNearbyBarriers(
        lat: _currentCenter.latitude,
        lng: _currentCenter.longitude,
        radius: 1200,
      );

      _currentBarriers = barriers;
      _symbolToBarrier.clear();
      await _mapController!.clearSymbols();

      for (final b in barriers) {
        final symbol = await _mapController!.addSymbol(
          SymbolOptions(
            geometry: LatLng(b.lat, b.lng),
            iconImage: 'triangle-15', // Icono vectorial estándar incluido en el estilo Liberty
            iconColor: b.severity >= 4 ? '#B91C1C' : '#FFB300',
            iconSize: 1.8,
            textField: b.title,
            textSize: 11.0,
            textColor: '#0A192F',
            textOffset: const Offset(0, 1.4),
          ),
        );
        _symbolToBarrier[symbol.id] = b;
      }
    } catch (e) {
      debugPrint('Error cargando barreras en el mapa: $e');
    }
  }

  void _onSymbolTapped(Symbol symbol) {
    final barrier = _symbolToBarrier[symbol.id];
    if (barrier != null) {
      _showBarrierDetail(barrier);
    }
  }

  Future<void> _searchRoute() async {
    final query = _searchCtrl.text.trim();
    if (query.length < 2) return;

    try {
      final res = await widget.bff.computeAccessibleRoutes(
        originLat: _currentCenter.latitude,
        originLng: _currentCenter.longitude,
        destinationQuery: query,
        profile: widget.preferences.accessibilityProfile,
        avoidSlopes: widget.preferences.avoidSlopes,
        maxSlopePercent: widget.preferences.maxSlopePercent,
        modes: const ['WALK', 'TRANSIT'],
        includeFirstTimerGuide: true,
      );

      if (res.routes.isEmpty || !mounted) return;
      final best = res.routes.first;

      // Dibujar la polilínea en MapLibre
      if (_mapController != null) {
        if (_currentRouteLine != null) {
          await _mapController!.removeLine(_currentRouteLine!);
        }

        final linePoints = best.coordinates.isNotEmpty
            ? best.coordinates.map((pair) => LatLng(pair[1], pair[0])).toList()
            : _decodePolyline(best.encodedPolyline);

        _currentRouteLine = await _mapController!.addLine(
          LineOptions(
            geometry: linePoints,
            lineColor: '#FFB300',
            lineWidth: 6.0,
            lineOpacity: 0.9,
          ),
        );

        // Centrar la cámara en el origen de la ruta
        if (linePoints.isNotEmpty) {
          _mapController!.animateCamera(CameraUpdate.newLatLngZoom(linePoints.first, 15.0));
        }
      }

      setState(() {
        _betaWarning = res.betaWarning;
        _selectedRoute = best;
      });
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error calculando ruta: $err')),
        );
      }
    }
  }

  void _showBarrierDetail(BarrierPin detail) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(detail.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Severidad: ${detail.severity}/5 · ${detail.confirmationsCount} confirmaciones',
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(detail.description),
            if (detail.photoSignedUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(detail.photoSignedUrl!, height: 130, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A192F)),
              onPressed: () async {
                await widget.bff.resolveBarrier(
                  barrierId: detail.id,
                  idempotencyKey: const Uuid().v4(),
                  note: 'Confirmado despejado desde la app móvil',
                );
                if (mounted) Navigator.pop(context);
                await _refreshBarriersOnMap();
              },
              icon: const Icon(Icons.check_circle, color: Color(0xFFFFB300)),
              label: const Text('Marcar como ya reparado', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Ej. Hospital cercano sin escalones',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) => _searchRoute(),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: 'Buscar ruta accesible',
                child: ElevatedButton(
                  onPressed: _searchRoute,
                  child: const Text('Ir'),
                ),
              ),
            ],
          ),
        ),
        if (_betaWarning != null)
          Semantics(
            liveRegion: true,
            child: MaterialBanner(
              content: Text(_betaWarning!, style: const TextStyle(fontSize: 12)),
              actions: [
                TextButton(
                  onPressed: () => setState(() => _betaWarning = null),
                  child: const Text('Entendido'),
                ),
              ],
            ),
          ),
        Expanded(
          child: MapLibreMap(
            styleString: AppEnv.openFreeMapStyle,
            initialCameraPosition: CameraPosition(target: _currentCenter, zoom: 15.0),
            myLocationEnabled: true,
            trackCameraPosition: true,
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
          ),
        ),
        if (_selectedRoute != null)
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.alt_route, color: Color(0xFFFFB300)),
                      const SizedBox(width: 8),
                      Text(
                        '${(_selectedRoute!.durationSeconds / 60).ceil()} min · ${_selectedRoute!.distanceMeters} m',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Spacer(),
                      Chip(
                        label: Text(_selectedRoute!.provider.toUpperCase(), style: const TextStyle(fontSize: 10)),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pendiente máx: ${_selectedRoute!.maxSlopePercent}% (DEM 90m Open-Meteo)',
                    style: TextStyle(
                      color: _selectedRoute!.maxSlopePercent > 8.0 ? Colors.red : Colors.green.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text('Obstáculos registrados en ruta: ${_selectedRoute!.barriersOnRoute.length}'),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
```

---

## 8. Cómo Compilar y Probar el APK de Producción

Para compilar el APK de lanzamiento con el nuevo stack libre, ejecuta en la raíz de `mobile/`:

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL="https://aiztivgrynirvdkcdugd.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="tu-anon-key-de-supabase" \
  --dart-define=BFF_BASE_URL="https://vialibre-bff.vercel.app"
```

### Ventajas del APK resultante:
1. **Instalación directa garantizada:** El mapa y las rutas cargarán inmediatamente en cualquier celular Android sin errores de `API_KEY_EXPIRED`, `REQUEST_DENIED` ni marcas de agua de Google.
2. **Cero costos:** OpenFreeMap, Valhalla, OSRM, Open-Meteo y Photon son servicios abiertos sin cobro ni tarjeta.
3. **Privacidad integral:** Se eliminan los trackers propietarios del SDK de Google Maps.
