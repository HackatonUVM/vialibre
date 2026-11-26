import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { simplifyNoticeInClearLanguage } from '@/lib/gemini';
import { authenticateRequest } from '@/lib/auth';

const noticeSchema = z.object({
  text: z.string().optional(),
  fileBase64: z.string().optional(),
  mimeType: z.string().optional(),
});

export async function POST(req: NextRequest) {
  try {
    const auth = await authenticateRequest(req);
    if (!auth.user) {
      return NextResponse.json({ error: auth.error || 'No autorizado' }, { status: 401 });
    }

    const body = await req.json();
    const parsed = noticeSchema.safeParse(body);
    if (!parsed.success || (!parsed.data.text && !parsed.data.fileBase64)) {
      return NextResponse.json(
        { error: 'Debe proporcionar texto o archivo base64 del aviso público' },
        { status: 400 }
      );
    }

    const result = await simplifyNoticeInClearLanguage({
      text: parsed.data.text,
      fileBase64: parsed.data.fileBase64,
      mimeType: parsed.data.mimeType || 'application/pdf',
    });

    return NextResponse.json({
      success: true,
      standard: 'ISO 24495-1 (Lenguaje Claro) + W3C COGA',
      summary: result,
      timestamp: new Date().toISOString(),
    });
  } catch (err: any) {
    console.error('Error simplificando aviso público:', err);
    return NextResponse.json({ error: 'Error procesando el aviso en Lenguaje Claro' }, { status: 500 });
  }
}
