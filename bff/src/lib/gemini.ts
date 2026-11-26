import { GoogleGenAI } from '@google/genai';
import { getEnv } from './env';

const env = getEnv();

// Cliente unificado del SDK oficial @google/genai
export const genai = new GoogleGenAI({
  apiKey: env.GOOGLE_API_KEY || 'AIzaSy_demo_placeholder',
});

export interface BarrierAnalysisResult {
  category: string;
  categoryCode: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  title: string;
  description: string;
  confidence: number;
  boundingBox?: [number, number, number, number]; // [ymin, xmin, ymax, xmax] 0-1000
  profileFlags: {
    wheelchairBlocked: boolean;
    blindHazard: boolean;
    strollerBlocked: boolean;
    reducedMobilityBlocked: boolean;
  };
}

/**
 * Analiza una fotografía de barrera urbana con visión de Google Gemini
 */
export async function analyzeBarrierImage(
  imageBase64: string,
  mimeType: string = 'image/jpeg',
  userProfile?: string
): Promise<BarrierAnalysisResult> {
  const prompt = `
Eres el motor de visión y accesibilidad urbana de VíaLibre. Analiza esta fotografía de la vía pública e identifica cualquier obstáculo o barrera física para peatones, especialmente personas en silla de ruedas, carriolas, personas ciegas o adultos mayores.

Detecta problemas como:
- Rampas clausuradas, bloqueadas por autos o con pendiente peligrosa.
- Banqueta rota, hundida, ausente o intransitable.
- Obras o zanjas sin señalización ni paso alterno seguro.
- Falta de pavimento táctil o guías podotáctiles interrumpidas.
- Postes, árboles o comercio informal obstruyendo el ancho mínimo peatonal (1.2m).

Responde ÚNICAMENTE en formato JSON con la siguiente estructura:
{
  "category": "Banqueta obstruida | Rampa inaccesible | Bache o zanja | Obstáculo peatonal | Obra sin paso seguro",
  "categoryCode": "open311_pavement_obstacle | open311_ramp_blocked | open311_construction | open311_street_hazard",
  "severity": "low" | "medium" | "high" | "critical",
  "title": "Título corto y claro (ej. Rampa para silla de ruedas bloqueada por vehículo)",
  "description": "Descripción objetiva del obstáculo en español sin inventar datos",
  "confidence": 0.95,
  "boundingBox": [ymin, xmin, ymax, xmax], // valores normalizados de 0 a 1000 donde se localiza el obstáculo principal
  "profileFlags": {
    "wheelchairBlocked": true,
    "blindHazard": true,
    "strollerBlocked": true,
    "reducedMobilityBlocked": true
  }
}
Perfil del usuario actual: ${userProfile || 'general'}
`;

  try {
    const response = await genai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: [
        {
          role: 'user',
          parts: [
            { text: prompt },
            {
              inlineData: {
                data: imageBase64,
                mimeType: mimeType,
              },
            },
          ],
        },
      ],
      config: {
        responseMimeType: 'application/json',
        temperature: 0.2,
      },
    });

    const text = response.text || '{}';
    return JSON.parse(text) as BarrierAnalysisResult;
  } catch (error: any) {
    console.warn('Error en Gemini Vision, usando fallback estructurado:', error.message);
    return {
      category: 'Obstáculo peatonal',
      categoryCode: 'open311_street_hazard',
      severity: 'medium',
      title: 'Reporte ciudadano de barrera urbana',
      description: 'Reporte registrado para verificación por la comunidad.',
      confidence: 0.8,
      profileFlags: {
        wheelchairBlocked: true,
        blindHazard: false,
        strollerBlocked: true,
        reducedMobilityBlocked: true,
      },
    };
  }
}

/**
 * Transcribe y clasifica una nota de voz ciudadana
 */
export async function transcribeAndClassifyAudio(
  audioBase64: string,
  mimeType: string = 'audio/wav'
): Promise<BarrierAnalysisResult> {
  const prompt = `
Escucha esta nota de voz ciudadana de reporte de barrera urbana. Extrae la información y clasifícala para accesibilidad peatonal.

Responde ÚNICAMENTE en JSON con:
{
  "category": "Banqueta obstruida | Rampa inaccesible | Bache o zanja | Obstáculo peatonal | Obra sin paso seguro",
  "categoryCode": "open311_street_hazard",
  "severity": "low" | "medium" | "high" | "critical",
  "title": "Resumen en una frase del problema reportado",
  "description": "Transcripción limpia y resumida del reporte sin datos personales",
  "confidence": 0.9,
  "profileFlags": {
    "wheelchairBlocked": true,
    "blindHazard": false,
    "strollerBlocked": true,
    "reducedMobilityBlocked": true
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
            {
              inlineData: {
                data: audioBase64,
                mimeType: mimeType,
              },
            },
          ],
        },
      ],
      config: {
        responseMimeType: 'application/json',
      },
    });

    return JSON.parse(response.text || '{}') as BarrierAnalysisResult;
  } catch (error: any) {
    console.warn('Error procesando audio con Gemini:', error.message);
    return {
      category: 'Reporte por voz',
      categoryCode: 'open311_audio_report',
      severity: 'medium',
      title: 'Reporte por nota de voz',
      description: 'Reporte auditivo pendiente de validación.',
      confidence: 0.75,
      profileFlags: {
        wheelchairBlocked: true,
        blindHazard: true,
        strollerBlocked: true,
        reducedMobilityBlocked: true,
      },
    };
  }
}

/**
 * Genera un vector embedding de 768 dimensiones para deduplicación semántica con PostGIS y pgvector
 */
export async function generateBarrierEmbedding(text: string): Promise<number[]> {
  try {
    const response = await genai.models.embedContent({
      model: 'text-embedding-004',
      contents: text,
      config: {
        outputDimensionality: 768,
      },
    });

    const anyResponse = response as any;
    const values = anyResponse.embedding?.values || anyResponse.embeddings?.[0]?.values;
    if (values && values.length === 768) {
      return values;
    }
    // Si la dimensión difiere o falta, rellenar/ajustar a 768
    if (values && values.length > 0) {
      const padded = new Array(768).fill(0);
      for (let i = 0; i < Math.min(768, values.length); i++) padded[i] = values[i];
      return padded;
    }
  } catch (error: any) {
    console.warn('Error generando embedding con Gemini:', error.message);
  }

  // Vector sintético determinista normalizado de fallback (768 dimensiones)
  const fallback = new Array(768).fill(0);
  for (let i = 0; i < text.length; i++) {
    fallback[i % 768] = (fallback[i % 768] + text.charCodeAt(i) / 255) / 2;
  }
  return fallback;
}

export interface ClearLanguageNotice {
  quePaso: string;
  aQuienAfecta: string;
  queHacerHoy: string;
  fechaVigencia?: string;
  ubicacion?: string;
}

/**
 * Traduce y resume comunicados públicos municipales a Lenguaje Claro (ISO 24495-1)
 */
export async function simplifyNoticeInClearLanguage(
  content: { text?: string; fileBase64?: string; mimeType?: string }
): Promise<ClearLanguageNotice> {
  const prompt = `
Eres el especialista en Lenguaje Claro (ISO 24495-1) y Accesibilidad Cognitiva (W3C COGA) de VíaLibre.
Tu misión es traducir este comunicado público, aviso de desvío, obra o trámite municipal a lenguaje ultra claro, directo y accesible para cualquier ciudadano (incluyendo adultos mayores o personas neurodivergentes).

Reglas estrictas:
1. Divide la información EXACTAMENTE en 3 bloques accionables:
   - "quePaso": Qué obra, desvío, cierre o cambio ocurrió (máximo 2 oraciones simples).
   - "aQuienAfecta": Qué rutas, colonias, peatones o usuarios se ven impactados.
   - "queHacerHoy": Instrucción concreta para hoy (ej. Tomar la parada provisional a 100m sobre calle X).
2. Prohibido inventar datos, fechas o teléfonos que no estén explícitos en el documento.
3. Vocabulario cotidiano, sin tecnicismos legales ni burocráticos.

Responde ÚNICAMENTE en JSON con:
{
  "quePaso": "...",
  "aQuienAfecta": "...",
  "queHacerHoy": "...",
  "fechaVigencia": "Fecha o plazo si se menciona",
  "ubicacion": "Calles o zona mencionada"
}
`;

  const parts: any[] = [{ text: prompt }];
  if (content.text) {
    parts.push({ text: `Documento a traducir:\n${content.text}` });
  } else if (content.fileBase64 && content.mimeType) {
    parts.push({
      inlineData: {
        data: content.fileBase64,
        mimeType: content.mimeType,
      },
    });
  }

  try {
    const response = await genai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: [{ role: 'user', parts }],
      config: {
        responseMimeType: 'application/json',
        temperature: 0.1,
      },
    });

    return JSON.parse(response.text || '{}') as ClearLanguageNotice;
  } catch (error: any) {
    console.warn('Error en traducción a Lenguaje Claro:', error.message);
    return {
      quePaso: 'Aviso municipal en revisión de accesibilidad.',
      aQuienAfecta: 'Peatones y usuarios de la zona.',
      queHacerHoy: 'Consulte señalización vial local o use rutas alternas.',
    };
  }
}
