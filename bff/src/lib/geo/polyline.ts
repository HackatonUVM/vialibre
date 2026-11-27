export interface GeoPoint {
  latitude: number;
  longitude: number;
}

/**
 * Decodifica una polilínea codificada según el algoritmo estándar de Google / OSRM / Valhalla.
 * @param encoded Cadena de polilínea codificada.
 * @param precision Factor de escala: 5 para 1e5 (Google / OSRM estándar), 6 para 1e6 (Valhalla).
 */
export function decodeEncodedPolyline(encoded: string, precision: number = 5): GeoPoint[] {
  if (!encoded || typeof encoded !== 'string') {
    return [];
  }

  const points: GeoPoint[] = [];
  let index = 0;
  let lat = 0;
  let lng = 0;
  const factor = Math.pow(10, precision);

  while (index < encoded.length) {
    let b: number;
    let shift = 0;
    let result = 0;
    do {
      b = encoded.charCodeAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20 && index <= encoded.length);
    const dlat = (result & 1) !== 0 ? ~(result >> 1) : result >> 1;
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.charCodeAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20 && index <= encoded.length);
    const dlng = (result & 1) !== 0 ? ~(result >> 1) : result >> 1;
    lng += dlng;

    points.push({
      latitude: lat / factor,
      longitude: lng / factor,
    });
  }

  return points;
}

/**
 * Codifica una lista de coordenadas GeoPoint en una cadena de polilínea estándar.
 * @param points Coordenadas geográficas a codificar.
 * @param precision Factor de escala (5 por defecto para 1e5 estándar).
 */
export function encodePolyline(points: GeoPoint[], precision: number = 5): string {
  if (!points || points.length === 0) {
    return '';
  }

  const factor = Math.pow(10, precision);
  let output = '';
  let prevLat = 0;
  let prevLng = 0;

  for (const point of points) {
    const lat = Math.round(point.latitude * factor);
    const lng = Math.round(point.longitude * factor);

    const dLat = lat - prevLat;
    const dLng = lng - prevLng;

    prevLat = lat;
    prevLng = lng;

    output += encodeSignedNumber(dLat);
    output += encodeSignedNumber(dLng);
  }

  return output;
}

function encodeSignedNumber(num: number): string {
  let sgn_num = num < 0 ? ~(num << 1) : num << 1;
  let encodeString = '';
  while (sgn_num >= 0x20) {
    encodeString += String.fromCharCode((0x20 | (sgn_num & 0x1f)) + 63);
    sgn_num >>= 5;
  }
  encodeString += String.fromCharCode(sgn_num + 63);
  return encodeString;
}

/**
 * Calcula la distancia ortodrómica en metros entre dos puntos geográficos (Haversine).
 */
export function haversineDistanceMeters(p1: GeoPoint, p2: GeoPoint): number {
  const R = 6371000; // Radio terrestre medio en metros
  const dLat = ((p2.latitude - p1.latitude) * Math.PI) / 180;
  const dLng = ((p2.longitude - p1.longitude) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((p1.latitude * Math.PI) / 180) *
      Math.cos((p2.latitude * Math.PI) / 180) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

/**
 * Submuestrea una lista de puntos para no exceder un límite de muestras distribuidas uniformemente.
 */
export function subsamplePoints(points: GeoPoint[], maxSamples: number = 40): GeoPoint[] {
  if (!points || points.length === 0) return [];
  if (points.length <= maxSamples) return [...points];
  if (maxSamples <= 1) return [points[0]];

  const step = (points.length - 1) / (maxSamples - 1);
  const result: GeoPoint[] = [];
  for (let i = 0; i < maxSamples; i++) {
    const idx = Math.min(points.length - 1, Math.round(i * step));
    result.push(points[idx]);
  }
  return result;
}

/**
 * Convierte un arreglo de puntos a formato WKT LINESTRING para consultas PostGIS.
 */
export function toLineStringWKT(points: GeoPoint[]): string {
  if (!points || points.length === 0) return 'LINESTRING EMPTY';
  const coords = points.map((p) => `${p.longitude} ${p.latitude}`).join(', ');
  return `LINESTRING(${coords})`;
}
