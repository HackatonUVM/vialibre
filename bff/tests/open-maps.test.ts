import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import {
  computeRouteAccessibilityScore,
  getElevationProfileAlongPoints,
  computeWalkOrTransitRoutes,
  searchPlacesWithAccessibility,
} from '@/lib/apis/open-maps';
import { encodePolyline } from '@/lib/geo/polyline';

describe('Open Maps Adapter Suite', () => {
  const originalFetch = global.fetch;

  beforeEach(() => {
    vi.restoreAllMocks();
  });

  afterEach(() => {
    global.fetch = originalFetch;
  });

  describe('computeRouteAccessibilityScore', () => {
    it('calculates score 100 for perfectly flat terrain without barriers', () => {
      const score = computeRouteAccessibilityScore({
        maxSlopePercent: 2.0,
        steepSegmentsCount: 0,
        barriersCount: 0,
        profile: 'wheelchair',
      });
      expect(score).toBe(100);
    });

    it('penalizes steep slopes and barriers appropriately', () => {
      const score = computeRouteAccessibilityScore({
        maxSlopePercent: 12.0, // > 8%
        steepSegmentsCount: 2,
        barriersCount: 2,
        profile: 'wheelchair',
      });
      // 100 - (12-8)*4 [16] - 2*6 [12] - 2*10 [20] = 52
      expect(score).toBeLessThan(70);
      expect(score).toBeGreaterThanOrEqual(15);
    });
  });

  describe('getElevationProfileAlongPoints', () => {
    it('calls Open-Meteo Elevation API and calculates real slope', async () => {
      const mockPoints = [
        { latitude: 19.4326, longitude: -99.1332 },
        { latitude: 19.4336, longitude: -99.1332 },
        { latitude: 19.4346, longitude: -99.1332 },
      ];

      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          elevation: [2240, 2242, 2245],
        }),
      });

      const elev = await getElevationProfileAlongPoints(mockPoints, 5.0);

      expect(elev.sampleCount).toBe(3);
      expect(elev.elevationGainMeters).toBe(5);
      expect(elev.maxSlopePercent).toBeGreaterThan(0);
      expect(global.fetch).toHaveBeenCalledWith(
        expect.stringContaining('api.open-meteo.com/v1/elevation'),
        expect.objectContaining({
          headers: expect.objectContaining({
            'User-Agent': expect.stringContaining('ViaLibreHackaton'),
          }),
        })
      );
    });
  });

  describe('computeWalkOrTransitRoutes', () => {
    it('uses Valhalla, decodes precision 6 and normalizes to precision 5', async () => {
      const p1 = { latitude: 19.432612, longitude: -99.133245 };
      const p2 = { latitude: 19.435055, longitude: -99.131012 };
      const valhallaShapeP6 = encodePolyline([p1, p2], 6);

      global.fetch = vi.fn().mockImplementation((url: string) => {
        if (url.includes('valhalla')) {
          return Promise.resolve({
            ok: true,
            json: async () => ({
              trip: {
                legs: [
                  {
                    shape: valhallaShapeP6,
                    summary: { length: 0.45, time: 360 },
                    maneuvers: [
                      {
                        instruction: 'Avanzar por banqueta accesible hacia el norte.',
                        length: 0.45,
                        time: 360,
                      },
                    ],
                  },
                ],
              },
            }),
          });
        }
        if (url.includes('elevation')) {
          return Promise.resolve({
            ok: true,
            json: async () => ({ elevation: [2240, 2241] }),
          });
        }
        return Promise.reject(new Error('Unknown url'));
      });

      const res = await computeWalkOrTransitRoutes({
        origin: p1,
        destination: p2,
        profile: 'wheelchair',
        avoidSlopes: true,
      });

      expect(res.provider).toBe('valhalla');
      expect(res.routes.length).toBe(1);

      const route = res.routes[0];
      expect(route.distanceMeters).toBe(450);
      expect(route.durationSeconds).toBe(360);
      expect(route.coordinates.length).toBe(2);
      expect(route.encodedPolyline.length).toBeGreaterThan(0);
      expect(route.steps[0].instruction).toBe('Avanzar por banqueta accesible hacia el norte.');
    });

    it('falls back to OSRM automatically when Valhalla fails', async () => {
      const p1 = { latitude: 19.4326, longitude: -99.1332 };
      const p2 = { latitude: 19.435, longitude: -99.131 };
      const osrmPolylineP5 = encodePolyline([p1, p2], 5);

      global.fetch = vi.fn().mockImplementation((url: string) => {
        if (url.includes('valhalla')) {
          return Promise.resolve({ ok: false, status: 503 });
        }
        if (url.includes('router.project-osrm.org')) {
          return Promise.resolve({
            ok: true,
            json: async () => ({
              code: 'Ok',
              routes: [
                {
                  geometry: osrmPolylineP5,
                  distance: 380,
                  duration: 310,
                  legs: [
                    {
                      steps: [
                        {
                          name: 'Calle Moneda',
                          distance: 380,
                          duration: 310,
                          maneuver: { type: 'depart' },
                        },
                      ],
                    },
                  ],
                },
              ],
            }),
          });
        }
        if (url.includes('elevation')) {
          return Promise.resolve({
            ok: true,
            json: async () => ({ elevation: [2240, 2240.8] }),
          });
        }
        return Promise.reject(new Error('Unknown url'));
      });

      const res = await computeWalkOrTransitRoutes({
        origin: p1,
        destination: p2,
        profile: 'general',
      });

      expect(res.provider).toBe('osrm');
      expect(res.routes[0].distanceMeters).toBe(380);
    });
  });

  describe('searchPlacesWithAccessibility', () => {
    it('queries Photon with mandatory User-Agent header', async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          type: 'FeatureCollection',
          features: [
            {
              geometry: { coordinates: [-99.1332, 19.4326] },
              properties: {
                osm_id: 998877,
                osm_type: 'N',
                name: 'Estación Zócalo / Tenochtitlan',
                street: 'Plaza de la Constitución',
                city: 'Ciudad de México',
                osm_key: 'railway',
                osm_value: 'subway_entrance',
              },
            },
          ],
        }),
      });

      const places = await searchPlacesWithAccessibility({
        lat: 19.4326,
        lng: -99.1332,
        query: 'Zócalo',
      });

      expect(places.length).toBe(1);
      expect(places[0].name).toBe('Estación Zócalo / Tenochtitlan');
      expect(places[0].wheelchairAccessibleEntrance).toBe(true);
      expect(places[0].source).toBe('photon');

      expect(global.fetch).toHaveBeenCalledWith(
        expect.stringContaining('photon.komoot.io/api'),
        expect.objectContaining({
          headers: expect.objectContaining({
            'User-Agent': expect.stringContaining('ViaLibreHackaton'),
          }),
        })
      );
    });
  });
});
