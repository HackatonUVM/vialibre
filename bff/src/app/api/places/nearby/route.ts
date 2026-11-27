import { NextRequest, NextResponse } from 'next/server';
import { searchPlacesWithAccessibility } from '@/lib/apis/open-maps';
import { supabaseAdmin } from '@/lib/supabase';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json().catch(() => ({}));
    const lat = body.lat ?? body.latitude ?? 19.4326;
    const lng = body.lng ?? body.longitude ?? -99.1332;
    const query = body.query || body.search || '';
    const radiusMeters = body.radiusMeters || body.radius || 1000;

    // Búsqueda de lugares y accesibilidad vía Photon (Komoot) + Nominatim
    const places = await searchPlacesWithAccessibility({
      lat,
      lng,
      query,
      radiusMeters,
    });

    // Barreras urbanas reportadas cercanas desde Supabase PostGIS
    let barriers: any[] = [];
    try {
      const { data, error } = await supabaseAdmin.rpc('get_nearby_barriers', {
        p_lat: lat,
        p_lng: lng,
        p_radius_meters: radiusMeters,
      });

      if (!error && Array.isArray(data)) {
        barriers = data;
      }
    } catch (_) {}

    return NextResponse.json({
      success: true,
      places,
      barriers,
      nearbyBarriers: barriers,
    });
  } catch (err: any) {
    console.error('Error buscando lugares accesibles:', err);
    return NextResponse.json({ error: 'Error buscando lugares accesibles' }, { status: 500 });
  }
}
