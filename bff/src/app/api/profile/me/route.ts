import { NextRequest, NextResponse } from 'next/server';

let cachedProfile: any = {
  profileType: 'wheelchair',
  avoidStairs: true,
  maxSlopePercent: 8.0,
  highContrast: false,
  textToSpeech: false,
  simplifiedMode: true,
};

export async function GET() {
  return NextResponse.json({ profile: cachedProfile });
}

export async function PUT(req: NextRequest) {
  try {
    const body = await req.json();
    cachedProfile = { ...cachedProfile, ...body };
    return NextResponse.json({ success: true, profile: cachedProfile });
  } catch (_) {
    return NextResponse.json({ error: 'Error actualizando perfil' }, { status: 400 });
  }
}

export async function DELETE() {
  cachedProfile = {
    profileType: 'general',
    avoidStairs: false,
    maxSlopePercent: 12.0,
    highContrast: false,
    textToSpeech: false,
    simplifiedMode: false,
  };
  return NextResponse.json({ success: true, deleted: true });
}
