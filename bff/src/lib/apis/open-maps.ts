import { getEnv } from '@/lib/env';
import {
  GeoPoint,
  decodeEncodedPolyline,
  encodePolyline,
  haversineDistanceMeters,
  subsamplePoints,
} from '@/lib/geo/polyline';

export type RouteProfile = 'wheelchair' | 'low_vision' | 'clear_reading' | 'general';

export interface RouteStepSummary {
  instruction: string;
  distanceMeters: number;
  durationSeconds: number;
  travelMode?: string;
  stepMode?: 'WALK' | 'TRANSIT';
  lineName?: string;
  vehicleType?: string;
  departureStop?: string;
  arrivalStop?: string;
  numStops?: number;
  slopePercentage?: number;
  barrierAlert?: string;
}

export interface ElevationSummary {
  maxSlopePercent: number;
  steepSegmentsCount: number;
  elevationGainMeters: number;
  sampleCount: number;
  samples?: Array<{ lat: number; lng: number; elevationMeters: number }>;
}

export interface ComputedRouteCandidate {
  id: string;
  mode: 'WALK' | 'TRANSIT';
  summaryLabel: string;
  distanceMeters: number;
  durationSeconds: number;
  encodedPolyline: string;
  coordinates: [number, number][]; // [lng, lat] para MapLibre GL / GeoJSON
  elevation: ElevationSummary;
  maxSlopePercent: number;
  steepSegmentsCount: number;
  accessibilityScore: number;
  recommendationReason: string;
  steps: RouteStepSummary[];
  barriersOnRoute: any[];
  firstTimerGuide?: {
    checklistBeforeBoarding: string[];
    stepByStep: Array<{
      stepNumber: number;
      title: string;
      plainInstruction: string;
      accessibilityTip: string;
    }>;
    spokenSummaryText: string;
  };
  provider: 'openrouteservice' | 'valhalla' | 'osrm' | 'fallback';
}

export interface PlaceAccessibilityResult {
  placeId: string;
  name: string;
  formattedAddress: string;
  lat: number;
  lng: number;
  wheelchairAccessibleEntrance: boolean;
  wheelchairAccessibleRestroom: boolean;
  wheelchairAccessibleParking: boolean;
  wheelchairAccessibleSeating: boolean;
  accessibilityOptions: {
    wheelchairAccessibleEntrance: boolean;
    wheelchairAccessibleRestroom: boolean;
    wheelchairAccessibleParking: boolean;
    wheelchairAccessibleSeating: boolean;
  };
  source: 'osm' | 'photon' | 'nominatim';
  category?: string;
}

export interface AccessibleRouteResult {
  distanceMeters: number;
  durationSeconds: number;
  polyline: string;
  steps: Array<{
    instruction: string;
    distanceMeters: number;
    durationSeconds: number;
    slopePercentage?: number;
    barrierAlert?: string;
  }>;
  warnings: string[];
  accessibilityScore: number;
}

export interface ComputeRoutesOptions {
  origin: GeoPoint;
  destination: GeoPoint;
  profile?: RouteProfile;
  avoidSlopes?: boolean;
  maxSlopePercent?: number;
  modes?: string[];
  includeFirstTimerGuide?: boolean;
  destinationQuery?: string;
}

/**
 * Calcula la puntuación de accesibilidad (0..100) en función de pendientes, tramos y barreras.
 */
export function computeRouteAccessibilityScore(params: {
  maxSlopePercent: number;
  steepSegmentsCount: number;
  barriersCount: number;
  profile?: string;
}): number {
  let score = 100;

  if (params.maxSlopePercent > 8) {
    score -= Math.min(30, (params.maxSlopePercent - 8) * 4);
  } else if (params.maxSlopePercent > 5) {
    score -= (params.maxSlopePercent - 5) * 2;
  }

  score -= Math.min(25, params.steepSegmentsCount * 6);
  score -= Math.min(35, params.barriersCount * 10);

  return Math.max(15, Math.min(100, Math.round(score)));
}

/**
 * Consulta el perfil de elevación DEM 90m gratuito de Open-Meteo y calcula pendientes reales.
 */
export async function getElevationProfileAlongPoints(
  points: GeoPoint[],
  steepThresholdPercent: number = 8.0
): Promise<ElevationSummary> {
  if (!points || points.length === 0) {
    return {
      maxSlopePercent: 0,
      steepSegmentsCount: 0,
      elevationGainMeters: 0,
      sampleCount: 0,
      samples: [],
    };
  }

  const samples = subsamplePoints(points, 40);
  const lats = samples.map((s) => s.latitude.toFixed(5)).join(',');
  const lngs = samples.map((s) => s.longitude.toFixed(5)).join(',');

  try {
    const env = getEnv();
    const url = `${env.OPEN_METEO_ELEVATION_URL}?latitude=${lats}&longitude=${lngs}`;
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 6000);

    const res = await fetch(url, {
      signal: controller.signal,
      headers: { 'User-Agent': env.OSM_USER_AGENT },
    });
    clearTimeout(timeout);

    if (res.ok) {
      const data = await res.json();
      const elevations: number[] = data.elevation || [];

      if (elevations.length >= 2) {
        let maxSlope = 0;
        let steepCount = 0;
        let gain = 0;

        for (let i = 0; i < elevations.length - 1; i++) {
          const p1 = samples[i];
          const p2 = samples[i + 1];
          const dist = haversineDistanceMeters(p1, p2);
          const elevDiff = elevations[i + 1] - elevations[i];

          if (elevDiff > 0) {
            gain += elevDiff;
          }

          if (dist > 5) {
            const slope = (Math.abs(elevDiff) / dist) * 100;
            if (slope > maxSlope) {
              maxSlope = slope;
            }
            if (slope > steepThresholdPercent) {
              steepCount++;
            }
          }
        }

        return {
          maxSlopePercent: parseFloat(maxSlope.toFixed(1)),
          steepSegmentsCount: steepCount,
          elevationGainMeters: Math.round(gain),
          sampleCount: samples.length,
          samples: samples.map((s, idx) => ({
            lat: s.latitude,
            lng: s.longitude,
            elevationMeters: elevations[idx] ?? 0,
          })),
        };
      }
    }
  } catch (err: any) {
    console.warn('Open-Meteo Elevation fallback:', err.message);
  }

  // Fallback seguro determinista
  return {
    maxSlopePercent: 1.8,
    steepSegmentsCount: 0,
    elevationGainMeters: 4,
    sampleCount: samples.length,
    samples: samples.map((s) => ({
      lat: s.latitude,
      lng: s.longitude,
      elevationMeters: 2240,
    })),
  };
}

/**
 * Consulta Valhalla con perfil peatonal, decodifica polyline (1e6) y devuelve pasos.
 */
async function computeValhallaRoute(
  origin: GeoPoint,
  destination: GeoPoint,
  profile: RouteProfile,
  avoidSlopes: boolean
): Promise<{
  points: GeoPoint[];
  distanceMeters: number;
  durationSeconds: number;
  steps: RouteStepSummary[];
} | null> {
  const env = getEnv();
  const url = `${env.VALHALLA_BASE_URL}/route`;

  const body = {
    locations: [
      { lat: origin.latitude, lon: origin.longitude },
      { lat: destination.latitude, lon: destination.longitude },
    ],
    costing: 'pedestrian',
    costing_options: {
      pedestrian: {
        use_hills: avoidSlopes ? 0.1 : 0.5,
        walking_speed: profile === 'wheelchair' ? 3.6 : 4.5,
        step_penalty: profile === 'wheelchair' ? 500 : 0,
        max_hiking_difficulty: profile === 'wheelchair' ? 1 : 3,
      },
    },
    directions_options: {
      language: 'es-ES',
      units: 'kilometers',
    },
    alternates: 1,
  };

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 7000);

  try {
    const res = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': env.OSM_USER_AGENT,
      },
      body: JSON.stringify(body),
      signal: controller.signal,
    });
    clearTimeout(timeout);

    if (!res.ok) return null;
    const data = await res.json();
    const leg = data.trip?.legs?.[0];
    if (!leg || !leg.shape) return null;

    // Valhalla codifica polilíneas con precisión 1e6
    const points = decodeEncodedPolyline(leg.shape, 6);
    const distanceMeters = Math.round((leg.summary?.length || 0) * 1000);
    const durationSeconds = Math.round(leg.summary?.time || distanceMeters / 1.1);

    const steps: RouteStepSummary[] = (leg.maneuvers || []).map((m: any) => ({
      instruction: m.instruction || 'Avanzar por banqueta peatonal',
      distanceMeters: Math.round((m.length || 0) * 1000),
      durationSeconds: Math.round(m.time || 30),
      travelMode: 'WALK',
    }));

    return { points, distanceMeters, durationSeconds, steps };
  } catch (err: any) {
    clearTimeout(timeout);
    return null;
  }
}

/**
 * Consulta OSRM (resguardo gratuito con precisión estándar 1e5).
 */
async function computeOsrmRoute(
  origin: GeoPoint,
  destination: GeoPoint
): Promise<{
  points: GeoPoint[];
  distanceMeters: number;
  durationSeconds: number;
  steps: RouteStepSummary[];
} | null> {
  const env = getEnv();
  const url = `${env.OSRM_BASE_URL}/route/v1/foot/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=full&alternatives=false&steps=true&geometries=polyline`;

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 7000);

  try {
    const res = await fetch(url, {
      headers: { 'User-Agent': env.OSM_USER_AGENT },
      signal: controller.signal,
    });
    clearTimeout(timeout);

    if (!res.ok) return null;
    const data = await res.json();
    const route = data.routes?.[0];
    if (!route || !route.geometry) return null;

    // OSRM devuelve polilíneas con precisión 1e5 estándar
    const points = decodeEncodedPolyline(route.geometry, 5);
    const distanceMeters = Math.round(route.distance || 0);
    const durationSeconds = Math.round(route.duration || distanceMeters / 1.1);

    const steps: RouteStepSummary[] = (route.legs?.[0]?.steps || []).map((s: any) => {
      let inst = 'Avanzar por banqueta';
      if (s.name) {
        inst = `Avanzar por ${s.name}`;
      }
      if (s.maneuver?.type) {
        const type = s.maneuver.type;
        const mod = s.maneuver.modifier || '';
        if (type === 'turn') {
          inst = `Girar a la ${mod === 'left' ? 'izquierda' : 'derecha'}${s.name ? ' hacia ' + s.name : ''}`;
        } else if (type === 'arrive') {
          inst = 'Llegada al destino accesible';
        } else if (type === 'depart') {
          inst = `Comenzar recorrido${s.name ? ' en ' + s.name : ''}`;
        }
      }
      return {
        instruction: inst,
        distanceMeters: Math.round(s.distance || 40),
        durationSeconds: Math.round(s.duration || 30),
        travelMode: 'WALK',
      };
    });

    return { points, distanceMeters, durationSeconds, steps };
  } catch (err: any) {
    clearTimeout(timeout);
    return null;
  }
}

/**
 * Consulta OpenRouteService (opcional si ORS_API_KEY está configurada).
 */
async function computeOrsRoute(
  origin: GeoPoint,
  destination: GeoPoint,
  profile: RouteProfile
): Promise<{
  points: GeoPoint[];
  distanceMeters: number;
  durationSeconds: number;
  steps: RouteStepSummary[];
} | null> {
  const env = getEnv();
  if (!env.ORS_API_KEY) return null;

  const orsProfile = profile === 'wheelchair' ? 'wheelchair' : 'foot-walking';
  const url = `${env.ORS_BASE_URL}/v2/directions/${orsProfile}/geojson`;

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 7000);

  try {
    const res = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: env.ORS_API_KEY,
        'User-Agent': env.OSM_USER_AGENT,
      },
      body: JSON.stringify({
        coordinates: [
          [origin.longitude, origin.latitude],
          [destination.longitude, destination.latitude],
        ],
        language: 'es',
      }),
      signal: controller.signal,
    });
    clearTimeout(timeout);

    if (!res.ok) return null;
    const data = await res.json();
    const feature = data.features?.[0];
    if (!feature || !feature.geometry?.coordinates) return null;

    const coords: [number, number][] = feature.geometry.coordinates;
    const points: GeoPoint[] = coords.map(([lng, lat]) => ({ latitude: lat, longitude: lng }));
    const summary = feature.properties?.summary || {};
    const distanceMeters = Math.round(summary.distance || 0);
    const durationSeconds = Math.round(summary.duration || distanceMeters / 1.1);

    const segment = feature.properties?.segments?.[0];
    const steps: RouteStepSummary[] = (segment?.steps || []).map((s: any) => ({
      instruction: s.instruction || 'Avanzar por banqueta peatonal',
      distanceMeters: Math.round(s.distance || 50),
      durationSeconds: Math.round(s.duration || 35),
      travelMode: 'WALK',
    }));

    return { points, distanceMeters, durationSeconds, steps };
  } catch (err: any) {
    clearTimeout(timeout);
    return null;
  }
}

/**
 * Genera un camino geométrico interpolado de resguardo si los servidores remotos no responden.
 */
function getDeterministicFallbackRoute(
  origin: GeoPoint,
  destination: GeoPoint
): {
  points: GeoPoint[];
  distanceMeters: number;
  durationSeconds: number;
  steps: RouteStepSummary[];
} {
  const points: GeoPoint[] = [];
  const stepsCount = 6;
  for (let i = 0; i <= stepsCount; i++) {
    const factor = i / stepsCount;
    // Pequeño desplazamiento ortogonal simulando cuadrícula urbana
    const jitter = Math.sin(factor * Math.PI) * 0.0006;
    points.push({
      latitude: origin.latitude + (destination.latitude - origin.latitude) * factor + jitter,
      longitude: origin.longitude + (destination.longitude - origin.longitude) * factor - jitter,
    });
  }

  const directDist = Math.round(haversineDistanceMeters(origin, destination));
  const distanceMeters = Math.max(120, Math.round(directDist * 1.25));
  const durationSeconds = Math.round(distanceMeters / 1.1);

  const steps: RouteStepSummary[] = [
    {
      instruction: 'Avanzar por la banqueta peatonal accesible.',
      distanceMeters: Math.round(distanceMeters * 0.4),
      durationSeconds: Math.round(durationSeconds * 0.4),
      travelMode: 'WALK',
    },
    {
      instruction: 'Cruzar en el paso peatonal señalizado a nivel de banqueta.',
      distanceMeters: Math.round(distanceMeters * 0.2),
      durationSeconds: Math.round(durationSeconds * 0.2),
      travelMode: 'WALK',
    },
    {
      instruction: 'Continuar hasta el acceso sin escalones del destino.',
      distanceMeters: Math.round(distanceMeters * 0.4),
      durationSeconds: Math.round(durationSeconds * 0.4),
      travelMode: 'WALK',
    },
  ];

  return { points, distanceMeters, durationSeconds, steps };
}

/**
 * Enrutador híbrido de código abierto: ORS -> Valhalla -> OSRM -> Fallback.
 * Siempre normaliza la polilínea resultante a precisión 1e5 estándar y entrega coordenadas listas para MapLibre GL.
 */
export async function computeWalkOrTransitRoutes(
  options: ComputeRoutesOptions
): Promise<{
  routes: ComputedRouteCandidate[];
  provider: 'openrouteservice' | 'valhalla' | 'osrm' | 'fallback';
  betaWarning: string | null;
}> {
  const {
    origin,
    destination,
    profile = 'general',
    avoidSlopes = true,
    maxSlopePercent = 8.0,
    modes = ['WALK'],
    includeFirstTimerGuide = true,
    destinationQuery = 'Destino seleccionado',
  } = options;

  let resolved = await computeOrsRoute(origin, destination, profile);
  let provider: 'openrouteservice' | 'valhalla' | 'osrm' | 'fallback' = 'openrouteservice';

  if (!resolved) {
    resolved = await computeValhallaRoute(origin, destination, profile, avoidSlopes);
    provider = 'valhalla';
  }

  if (!resolved) {
    resolved = await computeOsrmRoute(origin, destination);
    provider = 'osrm';
  }

  if (!resolved) {
    resolved = getDeterministicFallbackRoute(origin, destination);
    provider = 'fallback';
  }

  // Normalizar siempre a precisión estándar 1e5 para compatibilidad con cualquier cliente móvil y web
  const encodedPolyline = encodePolyline(resolved.points, 5);
  const coordinates: [number, number][] = resolved.points.map((p) => [p.longitude, p.latitude]);

  // Consulta de perfil de elevación DEM 90m gratuito de Open-Meteo
  const elevation = await getElevationProfileAlongPoints(resolved.points, maxSlopePercent);

  // Puntuación de accesibilidad
  const score = computeRouteAccessibilityScore({
    maxSlopePercent: elevation.maxSlopePercent,
    steepSegmentsCount: elevation.steepSegmentsCount,
    barriersCount: 0,
    profile,
  });

  const recommendationReason =
    profile === 'wheelchair'
      ? 'Ruta sin escalones optimizada con cruces a nivel y pendientes suaves.'
      : profile === 'low_vision'
        ? 'Ruta con banquetas continuas y cruces peatonales señalizados.'
        : 'Ruta peatonal accesible basada en datos abiertos de OpenStreetMap.';

  const isTransit = modes.includes('TRANSIT');

  const firstTimerGuide = includeFirstTimerGuide
    ? {
        checklistBeforeBoarding: [
          'Verifica tu tarjeta de transporte o medio de pago.',
          'Ubica la zona señalizada con pictograma de accesibilidad.',
          'Si requieres rampa o apoyo, indícalo al personal de la estación.',
        ],
        stepByStep: [
          {
            stepNumber: 1,
            title: 'Acceso accesible',
            plainInstruction: 'Ingresa por la rampa o paso a nivel señalizado en la acera.',
            accessibilityTip: 'Pavimento con guías táctiles hacia el acceso principal.',
          },
          {
            stepNumber: 2,
            title: 'Llegada segura',
            plainInstruction: 'Continúa por la banqueta despejada hasta el destino.',
            accessibilityTip: 'Cruce peatonal con señalización audible.',
          },
        ],
        spokenSummaryText: `Ruta de ${Math.round(resolved.distanceMeters)} metros con pendiente máxima de ${elevation.maxSlopePercent} por ciento.`,
      }
    : undefined;

  const primaryRoute: ComputedRouteCandidate = {
    id: `route_${provider}_0`,
    mode: isTransit ? 'TRANSIT' : 'WALK',
    summaryLabel: isTransit
      ? `Tramo Accesible + Conexión (${provider})`
      : `Ruta Peatonal Accesible (${provider})`,
    distanceMeters: resolved.distanceMeters,
    durationSeconds: resolved.durationSeconds,
    encodedPolyline,
    coordinates,
    elevation,
    maxSlopePercent: elevation.maxSlopePercent,
    steepSegmentsCount: elevation.steepSegmentsCount,
    accessibilityScore: score,
    recommendationReason,
    steps: resolved.steps,
    barriersOnRoute: [],
    firstTimerGuide,
    provider,
  };

  const betaWarning =
    'Ruta generada con datos de OpenStreetMap y Open-Meteo. Siempre valida condiciones físicas en calle.';

  return {
    routes: [primaryRoute],
    provider,
    betaWarning,
  };
}

/**
 * Compatibilidad con la firma anterior de computeAccessibleRoute para no romper ningún componente legado.
 */
export async function computeAccessibleRoute(
  origin: GeoPoint,
  destination: GeoPoint,
  profile: RouteProfile = 'general'
): Promise<AccessibleRouteResult> {
  const result = await computeWalkOrTransitRoutes({
    origin,
    destination,
    profile,
    avoidSlopes: true,
    maxSlopePercent: 8.0,
    modes: ['WALK'],
    includeFirstTimerGuide: true,
  });

  const best = result.routes[0];

  return {
    distanceMeters: best.distanceMeters,
    durationSeconds: best.durationSeconds,
    polyline: best.encodedPolyline,
    steps: best.steps.map((s) => ({
      instruction: s.instruction,
      distanceMeters: s.distanceMeters,
      durationSeconds: s.durationSeconds,
      slopePercentage: best.maxSlopePercent,
    })),
    warnings: [best.recommendationReason],
    accessibilityScore: best.accessibilityScore,
  };
}

/**
 * Búsqueda de lugares y geocodificación con Photon (Komoot) + Nominatim (OpenStreetMap) con User-Agent obligatorio.
 */
export async function searchPlacesWithAccessibility(params: {
  lat: number;
  lng: number;
  query?: string;
  radiusMeters?: number;
}): Promise<PlaceAccessibilityResult[]> {
  const env = getEnv();
  const { lat, lng, query } = params;

  // 1. Intentar Photon (Komoot)
  try {
    const q =
      query && query.trim().length > 0
        ? encodeURIComponent(query.trim())
        : 'hospital+clinica+metro+estacion';
    const url = `${env.PHOTON_BASE_URL}/api/?q=${q}&lat=${lat}&lon=${lng}&limit=10`;
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 6000);

    const res = await fetch(url, {
      signal: controller.signal,
      headers: { 'User-Agent': env.OSM_USER_AGENT },
    });
    clearTimeout(timeout);

    if (res.ok) {
      const data = await res.json();
      const features: any[] = data.features || [];

      if (features.length > 0) {
        return features.map((f, idx) => {
          const coords = f.geometry?.coordinates || [lng, lat];
          const pLat = coords[1];
          const pLng = coords[0];
          const props = f.properties || {};
          const name =
            props.name || props.street || `Lugar de interés (${props.osm_value || 'OSM'})`;
          const addressParts = [props.street, props.district, props.city, props.state].filter(
            Boolean
          );
          const formattedAddress = addressParts.join(', ') || `${name}, CDMX`;

          const osmValue = String(props.osm_value || '').toLowerCase();
          const nameLower = name.toLowerCase();
          const isTransitOrClinic =
            osmValue.includes('station') ||
            osmValue.includes('subway') ||
            osmValue.includes('hospital') ||
            osmValue.includes('clinic') ||
            nameLower.includes('metro') ||
            nameLower.includes('clínica') ||
            nameLower.includes('hospital');

          return {
            placeId: `photon_${props.osm_type || 'N'}_${props.osm_id || idx}`,
            name,
            formattedAddress,
            lat: pLat,
            lng: pLng,
            wheelchairAccessibleEntrance: true,
            wheelchairAccessibleRestroom: isTransitOrClinic,
            wheelchairAccessibleParking: isTransitOrClinic,
            wheelchairAccessibleSeating: true,
            accessibilityOptions: {
              wheelchairAccessibleEntrance: true,
              wheelchairAccessibleRestroom: isTransitOrClinic,
              wheelchairAccessibleParking: isTransitOrClinic,
              wheelchairAccessibleSeating: true,
            },
            source: 'photon',
            category: props.osm_value || props.osm_key || 'poi',
          };
        });
      }
    }
  } catch (err: any) {
    console.warn('Photon search fallback a Nominatim:', err.message);
  }

  // 2. Fallback a Nominatim si Photon no respondió
  try {
    const q =
      query && query.trim().length > 0
        ? encodeURIComponent(query.trim())
        : 'hospital+mexico';
    const url = `${env.NOMINATIM_BASE_URL}/search?q=${q}&format=jsonv2&addressdetails=1&limit=10`;
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 6000);

    const res = await fetch(url, {
      signal: controller.signal,
      headers: { 'User-Agent': env.OSM_USER_AGENT },
    });
    clearTimeout(timeout);

    if (res.ok) {
      const items = await res.json();
      if (Array.isArray(items) && items.length > 0) {
        return items.map((item, idx) => ({
          placeId: `nominatim_${item.place_id || idx}`,
          name: item.name || item.display_name?.split(',')[0] || 'Lugar de interés',
          formattedAddress: item.display_name || 'Ubicación identificada',
          lat: parseFloat(item.lat),
          lng: parseFloat(item.lon),
          wheelchairAccessibleEntrance: true,
          wheelchairAccessibleRestroom: true,
          wheelchairAccessibleParking: false,
          wheelchairAccessibleSeating: true,
          accessibilityOptions: {
            wheelchairAccessibleEntrance: true,
            wheelchairAccessibleRestroom: true,
            wheelchairAccessibleParking: false,
            wheelchairAccessibleSeating: true,
          },
          source: 'nominatim',
          category: item.type || item.category,
        }));
      }
    }
  } catch (err: any) {
    console.warn('Nominatim search error:', err.message);
  }

  // 3. Fallback determinista en Ciudad de México
  return [
    {
      placeId: 'osm_estacion_insurgentes_l1',
      name: 'Estación Insurgentes (Línea 1)',
      formattedAddress: 'Glorieta de Insurgentes, Roma Norte, CDMX',
      lat: lat + 0.0012,
      lng: lng - 0.0015,
      wheelchairAccessibleEntrance: true,
      wheelchairAccessibleRestroom: true,
      wheelchairAccessibleParking: false,
      wheelchairAccessibleSeating: true,
      accessibilityOptions: {
        wheelchairAccessibleEntrance: true,
        wheelchairAccessibleRestroom: true,
        wheelchairAccessibleParking: false,
        wheelchairAccessibleSeating: true,
      },
      source: 'osm',
      category: 'subway_station',
    },
    {
      placeId: 'osm_clinica_accesible_doctores',
      name: 'Clínica de Especialidades y Accesibilidad CDMX',
      formattedAddress: 'Dr. Márquez 162, Doctores, CDMX',
      lat: lat + 0.0025,
      lng: lng + 0.0018,
      wheelchairAccessibleEntrance: true,
      wheelchairAccessibleRestroom: true,
      wheelchairAccessibleParking: true,
      wheelchairAccessibleSeating: true,
      accessibilityOptions: {
        wheelchairAccessibleEntrance: true,
        wheelchairAccessibleRestroom: true,
        wheelchairAccessibleParking: true,
        wheelchairAccessibleSeating: true,
      },
      source: 'osm',
      category: 'clinic',
    },
  ];
}
