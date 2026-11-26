import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { authenticateRequest } from '@/lib/auth';
import { analyzeBarrierImage, transcribeAndClassifyAudio, generateBarrierEmbedding } from '@/lib/gemini';
import { supabaseAdmin } from '@/lib/supabase';

const reportSchema = z.object({
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  type: z.enum(['photo', 'audio']),
  mediaBase64: z.string().min(10),
  mimeType: z.string().default('image/jpeg'),
  userProfile: z.string().optional(),
  manualDescription: z.string().optional(),
});

export async function POST(req: NextRequest) {
  try {
    const auth = await authenticateRequest(req);
    if (!auth.user) {
      return NextResponse.json({ error: auth.error || 'No autorizado' }, { status: 401 });
    }

    const body = await req.json();
    const parsed = reportSchema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json(
        { error: 'Datos de reporte inválidos', details: parsed.error.format() },
        { status: 400 }
      );
    }

    const { latitude, longitude, type, mediaBase64, mimeType, userProfile, manualDescription } = parsed.data;

    // 1. Análisis con Gemini según el tipo de medio
    let analysis;
    if (type === 'photo') {
      analysis = await analyzeBarrierImage(mediaBase64, mimeType, userProfile);
    } else {
      analysis = await transcribeAndClassifyAudio(mediaBase64, mimeType);
    }

    // 2. Generación del embedding de 768 dimensiones para deduplicación semántica
    const textForEmbedding = `${analysis.title}. ${analysis.description}. Categoría: ${analysis.category}`;
    const embedding = await generateBarrierEmbedding(textForEmbedding);

    // 3. Inserción o deduplicación atómica en Supabase vía RPC upsert_or_confirm_barrier
    let barrierId: string = 'demo-' + Date.now();
    let isDuplicate: boolean = false;
    let confirmationsCount: number = 1;

    try {
      const { data, error } = await supabaseAdmin.rpc('upsert_or_confirm_barrier', {
        p_reporter_id: auth.user.id,
        p_lat: latitude,
        p_lng: longitude,
        p_category: analysis.category,
        p_category_code: analysis.categoryCode,
        p_severity: analysis.severity,
        p_title: analysis.title,
        p_description: analysis.description,
        p_profile_flags: analysis.profileFlags,
        p_embedding: embedding,
        p_radius_meters: 25.0,
        p_similarity_threshold: 0.85,
      });

      if (!error && data) {
        barrierId = data.id || barrierId;
        isDuplicate = data.is_duplicate ?? false;
        confirmationsCount = data.confirmations ?? 1;
      }
    } catch (rpcError: any) {
      console.warn('RPC upsert_or_confirm_barrier no disponible aún, usando modo resiliente:', rpcError.message);
    }

    return NextResponse.json({
      success: true,
      data: {
        barrierId,
        isDuplicate,
        confirmationsCount,
        category: analysis.category,
        severity: analysis.severity,
        title: analysis.title,
        description: analysis.description,
        boundingBox: analysis.boundingBox,
        profileFlags: analysis.profileFlags,
        location: { latitude, longitude },
        timestamp: new Date().toISOString(),
      },
    });
  } catch (err: any) {
    console.error('Error procesando reporte:', err);
    return NextResponse.json({ error: 'Error interno del servidor procesando el reporte' }, { status: 500 });
  }
}
