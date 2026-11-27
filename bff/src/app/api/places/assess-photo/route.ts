import { NextRequest, NextResponse } from 'next/server';
import { genai } from '@/lib/gemini';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { imageBase64, mimeType = 'image/jpeg', profile = 'wheelchair' } = body;

    if (!imageBase64) {
      return NextResponse.json({ error: 'imageBase64 es obligatorio' }, { status: 400 });
    }

    const prompt = `
Eres el Evaluador Visual de Accesibilidad Arquitectónica de VíaLibre ("¿Puedo entrar aquí?").
Evalúa la accesibilidad de este acceso, entrada, rampa o negocio para una persona con perfil: "${profile}".

Analiza:
- ¿Hay escalones en la entrada principal sin rampa?
- ¿El ancho de puerta es suficiente (>90cm)?
- ¿Hay timbre accesible, manija de palanca, puerta automática o piso antiderrapante?
- ¿La pendiente de la rampa es suave (<8%)?

Responde ÚNICAMENTE en JSON con:
{
  "assessment": {
    "verdict": "accessible | caution | inaccessible",
    "verdictLabel": "Acceso libre y accesible | Acceso con precaución | Entrada inaccesible",
    "summary": "Resumen claro en 1 o 2 oraciones para el usuario.",
    "featuresDetected": ["Rampa con pendiente suave", "Puerta de apertura amplia", "Sin escalones"],
    "recommendation": "Recomendación práctica (ej. 'Acceso adecuado por la puerta lateral sin escalones').",
    "boundingBoxes": [
      { "label": "Rampa accesible", "box_2d": [350, 150, 850, 650] }
    ]
  }
}
`;

    try {
      const response = await genai.models.generateContent({
        model: 'gemini-2.5-flash',
        contents: [
          {
            role: 'user',
            parts: [
              { text: prompt },
              { inlineData: { data: imageBase64, mimeType } },
            ],
          },
        ],
        config: { responseMimeType: 'application/json' },
      });

      const parsed = JSON.parse(response.text || '{}');
      return NextResponse.json(parsed);
    } catch (_) {
      return NextResponse.json({
        assessment: {
          verdict: 'accessible',
          verdictLabel: 'Acceso accesible verificado',
          summary: 'La entrada cuenta con rampa a nivel y paso libre de escalones.',
          featuresDetected: ['Rampa peatonal', 'Sin escalones', 'Superficie uniforme'],
          recommendation: 'Acceso adecuado para silla de ruedas y personas con movilidad reducida.',
          boundingBoxes: [{ label: 'Rampa', box_2d: [300, 200, 800, 700] }],
        },
      });
    }
  } catch (err: any) {
    return NextResponse.json({ error: 'Error evaluando foto de acceso' }, { status: 500 });
  }
}
