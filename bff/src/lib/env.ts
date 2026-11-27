import { z } from 'zod';

const envSchema = z.object({
  SUPABASE_URL: z.string().url().optional(),
  SUPABASE_ANON_KEY: z.string().min(1).optional(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1).optional(),
  GOOGLE_API_KEY: z.string().min(1).optional(),
  GOOGLE_MAPS_SERVER_KEY: z.string().min(1).optional(),
  ORS_API_KEY: z.string().optional(),
  ORS_BASE_URL: z.string().url().default('https://api.openrouteservice.org'),
  VALHALLA_BASE_URL: z.string().url().default('https://valhalla1.openstreetmap.de'),
  OSRM_BASE_URL: z.string().url().default('https://router.project-osrm.org'),
  OPEN_METEO_ELEVATION_URL: z.string().url().default('https://api.open-meteo.com/v1/elevation'),
  PHOTON_BASE_URL: z.string().url().default('https://photon.komoot.io'),
  NOMINATIM_BASE_URL: z.string().url().default('https://nominatim.openstreetmap.org'),
  OSM_USER_AGENT: z.string().default('ViaLibreHackaton/1.0 (https://github.com/HackatonUVM/vialibre)'),
});

export function getEnv() {
  const parsed = envSchema.safeParse({
    SUPABASE_URL: process.env.SUPABASE_URL,
    SUPABASE_ANON_KEY: process.env.SUPABASE_ANON_KEY,
    SUPABASE_SERVICE_ROLE_KEY: process.env.SUPABASE_SERVICE_ROLE_KEY,
    GOOGLE_API_KEY: process.env.GOOGLE_API_KEY,
    GOOGLE_MAPS_SERVER_KEY: process.env.GOOGLE_MAPS_SERVER_KEY,
    ORS_API_KEY: process.env.ORS_API_KEY,
    ORS_BASE_URL: process.env.ORS_BASE_URL || 'https://api.openrouteservice.org',
    VALHALLA_BASE_URL: process.env.VALHALLA_BASE_URL || 'https://valhalla1.openstreetmap.de',
    OSRM_BASE_URL: process.env.OSRM_BASE_URL || 'https://router.project-osrm.org',
    OPEN_METEO_ELEVATION_URL: process.env.OPEN_METEO_ELEVATION_URL || 'https://api.open-meteo.com/v1/elevation',
    PHOTON_BASE_URL: process.env.PHOTON_BASE_URL || 'https://photon.komoot.io',
    NOMINATIM_BASE_URL: process.env.NOMINATIM_BASE_URL || 'https://nominatim.openstreetmap.org',
    OSM_USER_AGENT: process.env.OSM_USER_AGENT || 'ViaLibreHackaton/1.0 (https://github.com/HackatonUVM/vialibre)',
  });

  return {
    SUPABASE_URL: process.env.SUPABASE_URL || 'https://placeholder.supabase.co',
    SUPABASE_ANON_KEY: process.env.SUPABASE_ANON_KEY || 'placeholder',
    SUPABASE_SERVICE_ROLE_KEY: process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY || 'placeholder',
    GOOGLE_API_KEY: process.env.GOOGLE_API_KEY || '',
    GOOGLE_MAPS_SERVER_KEY: process.env.GOOGLE_MAPS_SERVER_KEY || '',
    ORS_API_KEY: process.env.ORS_API_KEY || '',
    ORS_BASE_URL: process.env.ORS_BASE_URL || 'https://api.openrouteservice.org',
    VALHALLA_BASE_URL: process.env.VALHALLA_BASE_URL || 'https://valhalla1.openstreetmap.de',
    OSRM_BASE_URL: process.env.OSRM_BASE_URL || 'https://router.project-osrm.org',
    OPEN_METEO_ELEVATION_URL: process.env.OPEN_METEO_ELEVATION_URL || 'https://api.open-meteo.com/v1/elevation',
    PHOTON_BASE_URL: process.env.PHOTON_BASE_URL || 'https://photon.komoot.io',
    NOMINATIM_BASE_URL: process.env.NOMINATIM_BASE_URL || 'https://nominatim.openstreetmap.org',
    OSM_USER_AGENT: process.env.OSM_USER_AGENT || 'ViaLibreHackaton/1.0 (https://github.com/HackatonUVM/vialibre)',
    isConfigured: parsed.success,
  };
}
