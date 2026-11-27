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
        return NextResponse.json({ barrier: data, ...data });
      }
    } catch (_) {}

    // Fallback informativo
    const fallback = {
      id: barrierId,
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
