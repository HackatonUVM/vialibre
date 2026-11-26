import { NextResponse } from 'next/server';
import { getEnv } from '@/lib/env';

export async function GET() {
  const env = getEnv();

  return NextResponse.json({
    status: 'ok',
    service: 'VíaLibre BFF (Backend for Frontend)',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'production',
    integrations: {
      supabase: Boolean(process.env.SUPABASE_URL),
      gemini: Boolean(process.env.GOOGLE_API_KEY),
      googleMaps: Boolean(process.env.GOOGLE_MAPS_SERVER_KEY || process.env.GOOGLE_API_KEY),
    },
    version: '1.0.0',
  });
}
