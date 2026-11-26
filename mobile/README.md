# Cliente Móvil Flutter (`mobile/`)

Aplicación móvil nativa para **Android (`minSdk 24+`)** desarrollada con Flutter y Dart.

## Paquetes principales planeados

- `google_maps_flutter` (`2.19.0`) — `GoogleMap` con `mapId`, `AdvancedMarker` y `AssetMapBitmap`
- `supabase_flutter` (`2.x`) — `signInAnonymously()`, Bearer JWT y `uploadToSignedUrl`
- `flutter_image_compress` — limpieza EXIF (`keepExif: false`) y compresión `< 1.5 MB`
- `record` & `audioplayers` — captura de notas de voz y reproducción WAV en memoria
- `geolocator` & `permission_handler` — permisos en tiempo de ejecución
- `sqflite` & `connectivity_plus` — cola offline de reportes

## Variables requeridas en tiempo de compilación (`--dart-define`)

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://tu-proyecto.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=tu_anon_key \
  --dart-define=BFF_BASE_URL=https://tu-bff.vercel.app \
  --dart-define=GOOGLE_MAPS_MAP_ID=tu_map_id
```

> Además, configurar `com.google.android.geo.API_KEY` (restringida por `package name` + huella SHA-1) en `android/app/src/main/AndroidManifest.xml`.
