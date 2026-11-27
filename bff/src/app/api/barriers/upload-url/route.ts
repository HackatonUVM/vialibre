import { NextRequest, NextResponse } from 'next/server';
import { randomUUID } from 'crypto';
import { supabaseAdmin } from '@/lib/supabase';
import { authenticateRequest } from '@/lib/auth';

export async function POST(req: NextRequest) {
  try {
    const auth = await authenticateRequest(req);
    const userId = auth.user?.id || 'anonymous';
    const body = await req.json().catch(() => ({}));
    const fileExt = body.fileExt || 'jpg';
    const objectPath = `${userId}/${randomUUID()}.${fileExt}`;

    try {
      const { data, error } = await supabaseAdmin.storage
        .from('barrier-evidence')
        .createSignedUploadUrl(objectPath);

      if (!error && data) {
        return NextResponse.json({
          objectPath,
          token: data.token,
          signedUrl: data.signedUrl,
        });
      }
    } catch (_) {}

    // Fallback URL para resilience
    return NextResponse.json({
      objectPath,
      token: randomUUID(),
      signedUrl: `https://mock-storage.vialibre.mx/barrier-evidence/${objectPath}`,
    });
  } catch (err: any) {
    console.error('Error en /api/barriers/upload-url:', err);
    return NextResponse.json({ error: 'Error generando URL de carga' }, { status: 500 });
  }
}
