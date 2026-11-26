import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { computeAccessibleRoute } from '@/lib/maps';

const routeRequestSchema = z.object({
  origin: z.object({
    latitude: z.number().min(-90).max(90),
    longitude: z.number().min(-180).max(180),
  }),
  destination: z.object({
    latitude: z.number().min(-90).max(90),
    longitude: z.number().min(-180).max(180),
  }),
  profile: z.enum(['wheelchair', 'low_vision', 'clear_reading', 'general']).default('general'),
});

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const parsed = routeRequestSchema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json(
        { error: 'Parámetros de ruta inválidos', details: parsed.error.format() },
        { status: 400 }
      );
    }

    const { origin, destination, profile } = parsed.data;
    const route = await computeAccessibleRoute(origin, destination, profile);

    return NextResponse.json({
      success: true,
      route,
      profile,
    });
  } catch (err: any) {
    console.error('Error calculando ruta accesible:', err);
    return NextResponse.json({ error: 'Error calculando ruta accesible' }, { status: 500 });
  }
}
