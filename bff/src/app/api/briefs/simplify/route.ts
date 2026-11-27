import { NextRequest, NextResponse } from 'next/server';
import { createHash } from 'crypto';
import { genai } from '@/lib/gemini';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { storagePath, imageBase64, textContent, mimeType = 'text/plain' } = body;

    const prompt = `
Eres el traductor a Lenguaje Claro (ISO 24495-1) de avisos y comunicados de transporte de VíaLibre.
Traduce este aviso a 3 bloques fundamentales sin tecnicismos ni burocracia:
1. "whatHappened": Qué obra, desvío o cierre ocurrió (máximo 2 frases simples).
2. "whoIsAffected": Qué líneas, rutas o colonias afecta.
3. "whatToDoToday": Acción concreta y directa para el usuario hoy.
4. "issuer": Dependencia o sistema emisor (ej. Metrobús CDMX / Obras Públicas).
5. "estimatedDuration": Horario o duración prevista.

Responde ÚNICAMENTE en JSON:
{
  "whatHappened": "...",
  "whoIsAffected": "...",
  "whatToDoToday": "...",
  "issuer": "...",
  "estimatedDuration": "..."
}
Documento / Texto a analizar:
${textContent || storagePath || 'Aviso de obras en vía pública y adecuación de paradas accesibles'}
`;

    let summary = {
      whatHappened: 'Mantenimiento preventivo en elevadores y rampas de la estación central.',
      whoIsAffected: 'Usuarios de la Línea 1 y peatones con movilidad reducida.',
      whatToDoToday: 'Utilice el acceso oriente que cuenta con rampa provisional a nivel.',
      issuer: 'Sistema de Transporte Integrado',
      estimatedDuration: 'Hoy hasta las 20:00 horas',
    };

    try {
      const parts: any[] = [{ text: prompt }];
      if (imageBase64) {
        parts.push({ inlineData: { data: imageBase64, mimeType } });
      }
      const response = await genai.models.generateContent({
        model: 'gemini-2.5-flash',
        contents: [{ role: 'user', parts }],
        config: { responseMimeType: 'application/json' },
      });
      summary = JSON.parse(response.text || '{}');
    } catch (_) {}

    const sha = createHash('sha256').update(JSON.stringify(summary)).digest('hex').substring(0, 16);

    return NextResponse.json({
      docSha256: sha,
      plainSummary: summary,
      whatHappened: summary.whatHappened,
      whoIsAffected: summary.whoIsAffected,
      whatToDoToday: summary.whatToDoToday,
      issuer: summary.issuer,
      estimatedDuration: summary.estimatedDuration,
      audioSignedUrl: null,
      audioBase64: null,
    });
  } catch (err: any) {
    return NextResponse.json({ error: 'Error simplificando aviso' }, { status: 500 });
  }
}
