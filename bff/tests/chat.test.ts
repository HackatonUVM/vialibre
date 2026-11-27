import { describe, it, expect } from 'vitest';
import { NextRequest } from 'next/server';
import { POST as chatPOST } from '@/app/api/assistant/chat/route';
import { POST as routePOST } from '@/app/api/routes/accessible/route';

describe('POST /api/assistant/chat', () => {
  it('returns valid JSON with contextual smart fallback without GOOGLE_API_KEY', async () => {
    const req = new NextRequest('http://localhost:3000/api/assistant/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message: 'hola', profile: 'wheelchair' }),
    });

    const res = await chatPOST(req);
    const json = await res.json();
    expect(res.status).toBe(200);
    expect(json.replyText).toBeDefined();
    expect(json.suggestedAction).toBeDefined();
  });

  it('suggests open_map_route when asking for routes or destinations', async () => {
    const req = new NextRequest('http://localhost:3000/api/assistant/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message: 'cómo llego a Metro Tacubaya sin escalones', profile: 'wheelchair' }),
    });

    const res = await chatPOST(req);
    const json = await res.json();
    expect(res.status).toBe(200);
    expect(json.suggestedAction.type).toBe('open_map_route');
  });

  it('handles audioBase64 payload gracefully', async () => {
    const dummyAudioBase64 = Buffer.from('fake-audio-bytes-for-unit-test-verification').toString('base64');
    const req = new NextRequest('http://localhost:3000/api/assistant/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        message: 'Ayúdame con movilidad accesible según mi nota de voz.',
        audioBase64: dummyAudioBase64,
        audioMimeType: 'audio/mp4',
        profile: 'wheelchair',
      }),
    });

    const res = await chatPOST(req);
    const json = await res.json();
    expect(res.status).toBe(200);
    expect(json.replyText).toBeDefined();
  });
});

describe('POST /api/routes/accessible', () => {
  it('geocodes destinationQuery and computes route', async () => {
    const req = new NextRequest('http://localhost:3000/api/routes/accessible', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        origin: { lat: 19.4326, lng: -99.1332 },
        destinationQuery: 'Metro Tacubaya',
        profile: 'wheelchair',
      }),
    });

    const res = await routePOST(req);
    const json = await res.json();
    expect(res.status).toBe(200);
    expect(json.success).toBe(true);
    expect(json.routes).toBeInstanceOf(Array);
    expect(json.routes.length).toBeGreaterThan(0);
    expect(json.resolvedDestination).toBeDefined();
  });
});
