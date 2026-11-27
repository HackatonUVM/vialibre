import { describe, it, expect } from 'vitest';
import {
  decodeEncodedPolyline,
  encodePolyline,
  haversineDistanceMeters,
  subsamplePoints,
  toLineStringWKT,
} from '@/lib/geo/polyline';

describe('Geospatial and Polyline Utilities', () => {
  it('encodes and decodes standard polyline (precision 5)', () => {
    const points = [
      { latitude: 19.4326, longitude: -99.1332 },
      { latitude: 19.435, longitude: -99.131 },
      { latitude: 19.438, longitude: -99.128 },
    ];

    const encoded = encodePolyline(points, 5);
    expect(typeof encoded).toBe('string');
    expect(encoded.length).toBeGreaterThan(0);

    const decoded = decodeEncodedPolyline(encoded, 5);
    expect(decoded.length).toBe(3);
    expect(decoded[0].latitude).toBeCloseTo(19.4326, 4);
    expect(decoded[0].longitude).toBeCloseTo(-99.1332, 4);
    expect(decoded[2].latitude).toBeCloseTo(19.438, 4);
    expect(decoded[2].longitude).toBeCloseTo(-99.128, 4);
  });

  it('correctly decodes Valhalla precision 6 polyline and re-encodes to precision 5', () => {
    const valhallaPoints = [
      { latitude: 19.432612, longitude: -99.133245 },
      { latitude: 19.435055, longitude: -99.131012 },
    ];

    const valhallaEncoded = encodePolyline(valhallaPoints, 6);
    const decodedP6 = decodeEncodedPolyline(valhallaEncoded, 6);

    expect(decodedP6.length).toBe(2);
    expect(decodedP6[0].latitude).toBeCloseTo(19.432612, 5);
    expect(decodedP6[0].longitude).toBeCloseTo(-99.133245, 5);

    // Normalización a precisión estándar 1e5
    const normalizedEncodedP5 = encodePolyline(decodedP6, 5);
    const decodedP5 = decodeEncodedPolyline(normalizedEncodedP5, 5);

    expect(decodedP5.length).toBe(2);
    expect(decodedP5[0].latitude).toBeCloseTo(19.43261, 4);
    expect(decodedP5[0].longitude).toBeCloseTo(-99.13325, 4);
  });

  it('calculates Haversine distance correctly in meters', () => {
    const p1 = { latitude: 19.4326, longitude: -99.1332 };
    const p2 = { latitude: 19.4326, longitude: -99.1332 };
    expect(haversineDistanceMeters(p1, p2)).toBe(0);

    // Distancia Zócalo a Bellas Artes (~1.1 km)
    const bellasArtes = { latitude: 19.4352, longitude: -99.1412 };
    const dist = haversineDistanceMeters(p1, bellasArtes);
    expect(dist).toBeGreaterThan(800);
    expect(dist).toBeLessThan(1400);
  });

  it('subsamples points correctly without losing bounds', () => {
    const points = Array.from({ length: 100 }, (_, i) => ({
      latitude: 19.4 + i * 0.001,
      longitude: -99.1 - i * 0.001,
    }));

    const sampled = subsamplePoints(points, 40);
    expect(sampled.length).toBe(40);
    expect(sampled[0].latitude).toBeCloseTo(points[0].latitude, 5);
    expect(sampled[39].latitude).toBeCloseTo(points[99].latitude, 5);
  });

  it('formats PostGIS LINESTRING WKT correctly', () => {
    const points = [
      { latitude: 19.4326, longitude: -99.1332 },
      { latitude: 19.435, longitude: -99.131 },
    ];
    const wkt = toLineStringWKT(points);
    expect(wkt).toBe('LINESTRING(-99.1332 19.4326, -99.131 19.435)');
  });
});
