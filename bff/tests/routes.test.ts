import { describe, it, expect } from 'vitest';
import { NextRequest } from 'next/server';
import { POST as handleAccessibleRoutes } from '@/app/api/routes/accessible/route';
import { POST as handleNearbyPlaces } from '@/app/api/places/nearby/route';

describe('BFF API Routes Contracts', () => {
  it('POST /api/routes/accessible returns accessible route candidate with valid coordinates and provider', async () => {
    const req = new NextRequest('http://localhost:3000/api/routes/accessible', {
      method: 'POST',
      body: JSON.stringify({
        origin: { lat: 19.4326, lng: -99.1332 },
        destination: { lat: 19.4352, lng: -99.1412 },
        profile: 'wheelchair',
        avoidSlopes: true,
        maxSlopePercent: 8.0,
      }),
      headers: {
        'Content-Type': 'application/json',
      },
    });

    const res = await handleAccessibleRoutes(req);
    expect(res.status).toBe(200);

    const data = await res.json();
    expect(data.success).toBe(true);
    expect(Array.isArray(data.routes)).toBe(true);
    expect(data.routes.length).toBeGreaterThan(0);

    const primary = data.routes[0];
    expect(typeof primary.encodedPolyline).toBe('string');
    expect(Array.isArray(primary.coordinates)).toBe(true);
    expect(primary.coordinates.length).toBeGreaterThan(0);
    expect(typeof primary.distanceMeters).toBe('number');
    expect(typeof primary.durationSeconds).toBe('number');
    expect(primary.elevation).toBeDefined();
    expect(typeof primary.elevation.maxSlopePercent).toBe('number');
    expect(['openrouteservice', 'valhalla', 'osrm', 'fallback']).toContain(data.routeProvider);
  });

  it('POST /api/places/nearby returns places and barrier placeholders without error', async () => {
    const req = new NextRequest('http://localhost:3000/api/places/nearby', {
      method: 'POST',
      body: JSON.stringify({
        lat: 19.4326,
        lng: -99.1332,
        query: 'clinica',
        radiusMeters: 800,
      }),
      headers: {
        'Content-Type': 'application/json',
      },
    });

    const res = await handleNearbyPlaces(req);
    expect(res.status).toBe(200);

    const data = await res.json();
    expect(data.success).toBe(true);
    expect(Array.isArray(data.places)).toBe(true);
    expect(data.places.length).toBeGreaterThan(0);
    expect(data.places[0].accessibilityOptions).toBeDefined();
    expect(data.places[0].wheelchairAccessibleEntrance).toBeDefined();
  });
});
