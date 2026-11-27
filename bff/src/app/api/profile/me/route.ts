import { NextRequest, NextResponse } from 'next/server';

let cachedProfile: any = {
  accessibilityProfile: 'wheelchair',
  profileType: 'wheelchair',
  avoidSlopes: true,
  avoidStairs: true,
  maxSlopePercent: 8.0,
  ttsSpeed: 1.0,
  largeText: false,
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
    accessibilityProfile: 'wheelchair',
    profileType: 'general',
    avoidSlopes: true,
    avoidStairs: false,
    maxSlopePercent: 12.0,
    ttsSpeed: 1.0,
    largeText: false,
    highContrast: false,
    textToSpeech: false,
    simplifiedMode: false,
  };
  return NextResponse.json({ success: true, deleted: true });
}
