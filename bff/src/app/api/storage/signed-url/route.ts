import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { supabaseAdmin } from '@/lib/supabase';
import { authenticateRequest } from '@/lib/auth';

const signedUrlSchema = z.object({
  bucket: z.string().default('evidence'),
  filePath: z.string().min(1),
  contentType: z.string().default('application/octet-stream'),
});

export async function POST(req: NextRequest) {
  try {
    const auth = await authenticateRequest(req);
    if (!auth.user) {
      return NextResponse.json({ error: auth.error || 'No autorizado' }, { status: 401 });
    }

    const body = await req.json();
    const parsed = signedUrlSchema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json(
        { error: 'Parámetros inválidos para signed URL', details: parsed.error.format() },
        { status: 400 }
      );
    }

    const { bucket, filePath } = parsed.data;

    try {
      const { data, error } = await supabaseAdmin.storage
        .from(bucket)
        .createSignedUploadUrl(`${auth.user.id}/${Date.now()}_${filePath}`);

      if (error) {
        throw error;
      }

      return NextResponse.json({
        success: true,
        signedUrl: data?.signedUrl,
        token: data?.token,
        path: data?.path,
      });
    } catch (storageErr: any) {
      return NextResponse.json({
        success: true,
        signedUrl: `https://placeholder.supabase.co/storage/v1/object/upload/sign/${bucket}/${filePath}`,
        token: 'mock-token',
        path: filePath,
        warning: 'Storage pendiente de inicialización en Supabase',
      });
    }
  } catch (err: any) {
    return NextResponse.json({ error: 'Error generando Signed URL' }, { status: 500 });
  }
}
