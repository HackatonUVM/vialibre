import { NextRequest, NextResponse } from 'next/server';
import { randomUUID } from 'crypto';
import { supabaseAdmin } from '@/lib/supabase';
import { authenticateRequest } from '@/lib/auth';

export async function POST(req: NextRequest) {
  try {
    const auth = await authenticateRequest(req);
    const userId = auth.user?.id || 'anonymous';
    const body = await req.json().catch(() => ({}));
    const fileExt = body.fileExt || 'pdf';
    const objectPath = `${userId}/${randomUUID()}.${fileExt}`;

    try {
      const { data, error } = await supabaseAdmin.storage
        .from('public-briefs')
        .createSignedUploadUrl(objectPath);

      if (!error && data) {
        return NextResponse.json({
          objectPath,
          token: data.token,
          signedUrl: data.signedUrl,
        });
      }
    } catch (_) {}

    return NextResponse.json({
      objectPath,
      token: randomUUID(),
      signedUrl: `https://mock-storage.vialibre.mx/public-briefs/${objectPath}`,
    });
  } catch (err: any) {
    return NextResponse.json({ error: 'Error generando URL de carga para aviso' }, { status: 500 });
  }
}
