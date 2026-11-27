import { NextRequest, NextResponse } from 'next/server';
import { analyzeBarrierImage } from '@/lib/gemini';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { imageBase64, mimeType = 'image/jpeg', profile = 'general', textNote } = body;

    if (!imageBase64 && !textNote) {
      return NextResponse.json({ error: 'imageBase64 o textNote requerido' }, { status: 400 });
    }

    const analysis = await analyzeBarrierImage(imageBase64 || '', mimeType, profile);

    return NextResponse.json({
      category: analysis.category,
      categoryCode: analysis.categoryCode,
      severity: analysis.severity,
      title: analysis.title,
      description: analysis.description,
      confidence: analysis.confidence,
      boundingBox: analysis.boundingBox || [200, 150, 800, 850],
      profileFlags: analysis.profileFlags,
      dispatchAgency: 'Secretaría de Obras y Servicios / Movilidad CDMX',
      estimatedRepairTimeDays: 5,
    });
  } catch (err: any) {
    console.error('Error en /api/barriers/analyze:', err);
    return NextResponse.json({ error: 'Error analizando barrera con IA' }, { status: 500 });
  }
}
