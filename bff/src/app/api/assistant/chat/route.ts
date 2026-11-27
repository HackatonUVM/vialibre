import { NextRequest, NextResponse } from 'next/server';
import { genai } from '@/lib/gemini';

function buildSmartFallback(message: string, profile: string) {
  const query = message.toLowerCase();

  if (
    query.includes('ruta') ||
    query.includes('llegar') ||
    query.includes('cómo llego') ||
    query.includes('destino') ||
    query.includes('ir a') ||
    query.includes('camino') ||
    query.includes('zócalo') ||
    query.includes('tacubaya') ||
    query.includes('insurgentes')
  ) {
    return {
      replyText:
        'Para moverte de forma segura y sin escalones, te sugiero calcular tu trayecto en el Mapa Accesible. Considera estaciones con elevadores activos y banquetas libres de pendientes pronunciadas.',
      suggestedAction: {
        type: 'open_map_route',
        label: 'Ver ruta accesible en el mapa',
        query: message.replace(/cómo llego a|como llego a|ruta a|ir a|para ir a/gi, '').trim() || null,
      },
      quickFollowUps: [
        '¿Dónde hay rampas y elevadores en mi ruta?',
        '¿Cómo viajo en Metro por primera vez?',
      ],
    };
  }

  if (
    query.includes('primera vez') ||
    query.includes('primerizo') ||
    query.includes('cómo uso') ||
    query.includes('cómo abordo') ||
    query.includes('silla de ruedas') ||
    query.includes('bastón') ||
    query.includes('cieg') ||
    query.includes('baja visión')
  ) {
    return {
      replyText:
        '¡Bienvenido a VíaLibre! En Metrobús y Metro de CDMX, ubica las puertas con el pictograma azul de accesibilidad. Cuentan con rampa retráctil o abordaje a nivel de andén. Puedes solicitar asistencia al jefe de estación o presionar el botón de auxilio.',
      suggestedAction: {
        type: 'open_first_timer_guide',
        label: 'Abrir guía paso a paso',
        query: null,
      },
      quickFollowUps: [
        '¿Cómo solicitar la rampa en Metrobús?',
        'Ver mapa con rutas sin escalones',
      ],
    };
  }

  if (
    query.includes('report') ||
    query.includes('bache') ||
    query.includes('rampa') ||
    query.includes('bloquea') ||
    query.includes('elevador') ||
    query.includes('descompuesto') ||
    query.includes('obstáculo') ||
    query.includes('banqueta')
  ) {
    return {
      replyText:
        'Puedes reportar este obstáculo directamente con foto o nota de voz. VíaLibre analizará el nivel de severidad y alertará a otros usuarios en tiempo real sobre la ruta.',
      suggestedAction: {
        type: 'open_report',
        label: 'Reportar obstáculo ahora',
        query: null,
      },
      quickFollowUps: [
        'Ver obstáculos reportados cerca',
        '¿Cómo consultar mis reportes?',
      ],
    };
  }

  if (
    query.includes('aviso') ||
    query.includes('desvío') ||
    query.includes('obra') ||
    query.includes('retraso') ||
    query.includes('mantenimiento')
  ) {
    return {
      replyText:
        'Tenemos avisos operativos simplificados para que conozcas afectaciones y desvíos en el transporte público en lenguaje claro y accesible.',
      suggestedAction: {
        type: 'open_briefs',
        label: 'Consultar avisos y desvíos',
        query: null,
      },
      quickFollowUps: [
        '¿Hay retrasos en Metro hoy?',
        'Ver rutas alternas accesibles',
      ],
    };
  }

  return {
    replyText:
      'Hola, soy el copiloto de VíaLibre. Te ayudo a planear rutas sin escalones, resolver dudas sobre el abordaje accesible en Metro y Metrobús o reportar barreras urbanas.',
    suggestedAction: {
      type: 'open_map_route',
      label: 'Explorar rutas accesibles',
      query: null,
    },
    quickFollowUps: [
      '¿Cómo llegar al Zócalo sin escalones?',
      '¿Cómo abordo el Metrobús en silla de ruedas?',
      'Reportar una rampa bloqueada',
    ],
  };
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json().catch(() => ({}));
    const {
      message = '',
      profile = 'wheelchair',
      location,
      audioBase64,
      audioMimeType = 'audio/mp4',
    } = body;

    const userMessage = (message || '').trim() || (audioBase64 ? 'Pregunta por nota de voz' : 'Hola');

    const prompt = `
Eres el Copiloto Accesible de VíaLibre (Reto 2: Movilidad Urbana Inclusiva y Accesible).
Ayudas con calidez, claridad y empatía a personas con discapacidad (motriz, visual, cognitiva) o adultos mayores a navegar el transporte público y calles de la ciudad sin escalones ni barreras.

Perfil del usuario: ${profile}
Ubicación actual: ${JSON.stringify(location || { lat: 19.4326, lng: -99.1332 })}
Pregunta o mensaje del usuario: "${userMessage}"
${audioBase64 ? 'Nota: El usuario adjuntó una nota de voz. Escúchala con atención y responde directamente a lo que pide o necesita.' : ''}

Reglas:
- Si pregunta por rutas o cómo llegar a un sitio, sugiere actionType: "open_map_route".
- Si pregunta cómo abordar por primera vez en silla de ruedas, con perro guía o bastón, sugiere actionType: "open_first_timer_guide".
- Si reporta un bache, rampa rota o elevador descompuesto, sugiere actionType: "open_report".
- Si pregunta por avisos, obras o desvíos, sugiere actionType: "open_briefs".
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
      const parts: any[] = [{ text: prompt }];

      if (audioBase64 && typeof audioBase64 === 'string' && audioBase64.length > 50) {
        parts.push({
          inlineData: {
            data: audioBase64,
            mimeType: audioMimeType || 'audio/mp4',
          },
        });
      }

      const response = await genai.models.generateContent({
        model: 'gemini-2.5-flash',
        contents: [{ role: 'user', parts }],
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
      const fallback = buildSmartFallback(userMessage, profile);
      return NextResponse.json({
        replyText: fallback.replyText,
        suggestedAction: fallback.suggestedAction,
        quickFollowUps: fallback.quickFollowUps,
        audioSignedUrl: null,
        audioBase64: null,
      });
    }
  } catch (err: any) {
    const fallback = buildSmartFallback('Hola', 'wheelchair');
    return NextResponse.json({
      replyText: fallback.replyText,
      suggestedAction: fallback.suggestedAction,
      quickFollowUps: fallback.quickFollowUps,
      audioSignedUrl: null,
      audioBase64: null,
    });
  }
}
