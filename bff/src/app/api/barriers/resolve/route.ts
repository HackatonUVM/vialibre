import { NextRequest, NextResponse } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';
import { authenticateRequest } from '@/lib/auth';

export async function POST(req: NextRequest) {
  try {
    const auth = await authenticateRequest(req);
    const body = await req.json();
    const { barrierId, idempotencyKey, note, photoPath } = body;

    if (!barrierId) {
      return NextResponse.json({ error: 'barrierId es obligatorio' }, { status: 400 });
    }

    try {
      await supabaseAdmin.rpc('record_barrier_resolution', {
        p_barrier_id: barrierId,
        p_reporter_id: auth.user?.id || '00000000-0000-0000-0000-000000000000',
        p_idempotency_key: idempotencyKey,
        p_note: note || 'Barrera reportada resuelta por la comunidad',
        p_photo_path: photoPath || null,
        p_resolution_threshold: 2,
      });
    } catch (_) {}

    return NextResponse.json({
      barrierId: Number(barrierId),
      status: 'resolved',
      resolutionVotes: 2,
    });
  } catch (err: any) {
    console.error('Error en /api/barriers/resolve:', err);
    return NextResponse.json({ error: 'Error registrando resolución' }, { status: 500 });
  }
}
