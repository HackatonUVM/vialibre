import { NextRequest, NextResponse } from 'next/server';
import { genai } from '@/lib/gemini';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { message = '', profile = 'wheelchair', location } = body;

    const prompt = `
Eres el Copiloto Accesible de VíaLibre (Reto 2: Movilidad Urbana Inclusiva y Accesible).
Ayudas con calidez, claridad y empatía a personas con discapacidad (motriz, visual, cognitiva) o adultos mayores a navegar el transporte público y calles de la ciudad sin escalones ni barreras.

Perfil del usuario: ${profile}
Ubicación actual: ${JSON.stringify(location || { lat: 19.4326, lng: -99.1332 })}
Pregunta del usuario: "${message}"

Reglas:
- Si pregunta por rutas, sugiere actionType: "open_map_route".
- Si pregunta cómo abordar por primera vez en silla de ruedas o con baja visión, sugiere actionType: "open_first_timer_guide".
- Si reporta un bache, rampa rota o elevador descompuesto, sugiere actionType: "open_report".
- Si pregunta por avisos o desvíos, sugiere actionType: "open_briefs".
- Si es charla general, sugiere actionType: "none".

Responde ÚNICAMENTE en JSON con:
{
  "replyText": "Respuesta clara, empática y concreta en español (máximo 3 párrafos cortos).",
  "suggestedAction": {
    "type": "open_map_route | open_first_timer_guide | open_report | open_briefs | none",
    "label": "Texto del botón de acción (ej. 'Ver ruta sin escalones')",
    "query": "consulta sugerida o null"
  },
  "quickFollowUps": [
    "Pregunta de seguimiento 1",
    "Pregunta de seguimiento 2"
  ]
}
`;

    try {
      const response = await genai.models.generateContent({
        model: 'gemini-2.5-flash',
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        config: { responseMimeType: 'application/json' },
      });

      const parsed = JSON.parse(response.text || '{}');
      return NextResponse.json({
        replyText: parsed.replyText || 'Estoy aquí para ayudarte a moverte con libertad y accesibilidad.',
        suggestedAction: parsed.suggestedAction || { type: 'none', label: null, query: null },
        quickFollowUps: parsed.quickFollowUps || ['¿Dónde hay una rampa cercana?', '¿Cómo tomo el Metrobús?'],
        audioSignedUrl: null,
        audioBase64: null,
      });
    } catch (_) {
      return NextResponse.json({
        replyText: 'Para viajar en silla de ruedas en Metrobús, aborda en las puertas señalizadas con el icono azul. Cuentan con rampa automática o abordaje a nivel de banqueta.',
        suggestedAction: {
          type: 'open_first_timer_guide',
          label: 'Abrir guía paso a paso',
          query: null,
        },
        quickFollowUps: ['¿Cómo pido auxilio en estación?', 'Ver mapa con rutas sin escalones'],
        audioSignedUrl: null,
        audioBase64: null,
      });
    }
  } catch (err: any) {
    return NextResponse.json({ error: 'Error en asistente conversacional' }, { status: 500 });
  }
}
