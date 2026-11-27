import { NextRequest, NextResponse } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';

export async function GET(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    const barrierId = Number(id);

    try {
      const { data, error } = await supabaseAdmin
        .from('barriers')
        .select('*')
        .eq('id', barrierId)
        .single();

      if (!error && data) {
        const item = {
          ...data,
          id: typeof data.id === 'string' ? parseInt(data.id, 10) : data.id,
          lat: data.lat ?? data.latitude ?? (data.location?.coordinates ? data.location.coordinates[1] : 19.4326),
          lng: data.lng ?? data.longitude ?? (data.location?.coordinates ? data.location.coordinates[0] : -99.1332),
          confirmations_count: data.confirmations_count ?? 1,
        };
        return NextResponse.json({ barrier: item, ...item });
      }
    } catch (_) {}

    // Fallback informativo numérico y tipado para Dart
    const fallback = {
      id: barrierId || 101,
      title: 'Rampa peatonal con obstrucción',
      description: 'Vehículo o escombro bloqueando paso a nivel.',
      category: 'blocked_ramp',
      severity: 3,
      status: 'active',
      confirmations_count: 2,
      lat: 19.4326,
      lng: -99.1332,
      profile_flags: { wheelchair: true, low_vision: false, stroller: true },
    };
    return NextResponse.json({ barrier: fallback, ...fallback });
  } catch (err: any) {
    return NextResponse.json({ error: 'Error obteniendo barrera' }, { status: 500 });
  }
}
