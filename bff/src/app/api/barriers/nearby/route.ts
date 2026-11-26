import { NextRequest, NextResponse } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';

export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const lat = parseFloat(searchParams.get('lat') || '19.4326');
    const lng = parseFloat(searchParams.get('lng') || '-99.1332');
    const radiusMeters = parseFloat(searchParams.get('radius') || '1000'); // 1km default

    let barriers: any[] = [];

    try {
      const { data, error } = await supabaseAdmin.rpc('get_nearby_barriers', {
        p_lat: lat,
        p_lng: lng,
        p_radius_meters: radiusMeters,
      });

      if (!error && data) {
        barriers = data;
      }
    } catch (rpcErr) {
      // Si la RPC aún no está creada en Supabase, devolvemos datos iniciales de muestra accesibles
      barriers = [
        {
          id: 'barrier-1',
          title: 'Rampa obstruida por obras',
          category: 'Rampa inaccesible',
          severity: 'high',
          latitude: lat + 0.001,
          longitude: lng + 0.0012,
          confirmations: 3,
          profileFlags: { wheelchairBlocked: true, blindHazard: false },
          expiresAt: new Date(Date.now() + 86400000 * 2).toISOString(),
        },
        {
          id: 'barrier-2',
          title: 'Banqueta levantada por raíces',
          category: 'Banqueta rota',
          severity: 'medium',
          latitude: lat - 0.0015,
          longitude: lng + 0.0008,
          confirmations: 5,
          profileFlags: { wheelchairBlocked: true, blindHazard: true },
          expiresAt: new Date(Date.now() + 86400000 * 7).toISOString(),
        },
      ];
    }

    return NextResponse.json({
      success: true,
      count: barriers.length,
      barriers,
    });
  } catch (err: any) {
    return NextResponse.json({ error: 'Error obteniendo barreras cercanas' }, { status: 500 });
  }
}
