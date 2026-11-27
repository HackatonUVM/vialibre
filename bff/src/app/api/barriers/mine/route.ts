import { NextRequest, NextResponse } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';
import { authenticateRequest } from '@/lib/auth';

export async function GET(req: NextRequest) {
  try {
    const auth = await authenticateRequest(req);
    const userId = auth.user?.id;

    if (userId) {
      try {
        const { data, error } = await supabaseAdmin
          .from('barriers')
          .select('*')
          .eq('reporter_id', userId)
          .order('created_at', { ascending: false })
          .limit(20);

        if (!error && data) {
          return NextResponse.json({ barriers: data });
        }
      } catch (_) {}
    }

    return NextResponse.json({ barriers: [] });
  } catch (err: any) {
    return NextResponse.json({ error: 'Error obteniendo reportes' }, { status: 500 });
  }
}
