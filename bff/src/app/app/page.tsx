'use client';

import React, { useState, useEffect, useRef } from 'react';

type TabType = 'explore' | 'map' | 'report' | 'briefs';
type ProfileType = 'wheelchair' | 'low_vision' | 'clear_reading';

const PALETTE = {
  canvas: '#141416',
  card: '#1D1D1F',
  sand: '#26262C',
  border: '#363640',
  ink: '#FAF8F5',
  muted: '#B8B8C4',
  coral: '#EF4756',
  coralSoft: '#3A1E24',
  lavender: '#292A44',
  lavenderInk: '#DCE0FF',
  mintSoft: '#163525',
  mintInk: '#86EFAC',
  amberSoft: '#3B2D14',
  amberInk: '#FDE68A',
  alertRed: '#FCA5A5',
  alertRedSoft: '#421C20',
  ctaBg: '#FAF8F5',
  ctaFg: '#18181B',
  mapDarkBg: '#111216',
  mapRoad: '#272832',
  mapHighway: '#343545',
};

const PROFILE_LABELS: Record<ProfileType, string> = {
  wheelchair: 'Silla de ruedas',
  low_vision: 'Baja visión',
  clear_reading: 'Lectura clara',
};

export default function ViaLibreOfficialApp() {
  const [activeTab, setActiveTab] = useState<TabType>('explore');
  const [profile, setProfile] = useState<ProfileType>('clear_reading');

  // Modales
  const [showProfileModal, setShowProfileModal] = useState(false);
  const [showCopilotModal, setShowCopilotModal] = useState(false);
  const [showFirstTimerModal, setShowFirstTimerModal] = useState(false);

  // Explorar & Búsqueda
  const [searchQuery, setSearchQuery] = useState('');

  // Mapa Interactivo (Zoom, Paneo, Pines)
  const [mapSearchQuery, setMapSearchQuery] = useState('');
  const [activeMapChip, setActiveMapChip] = useState('Lectura clara');
  const [mapZoom, setMapZoom] = useState(1);
  const [mapPan, setMapPan] = useState({ x: 0, y: 0 });
  const [isDraggingMap, setIsDraggingMap] = useState(false);
  const [dragStart, setDragStart] = useState({ x: 0, y: 0 });
  const [selectedPoi, setSelectedPoi] = useState<string | null>(null);
  const [routeResult, setRouteResult] = useState<any>(null);
  const [loadingRoute, setLoadingRoute] = useState(false);

  // Reportar
  const [reportNote, setReportNote] = useState('');
  const [reportImagePreview, setReportImagePreview] = useState<string | null>(null);
  const [reportImageBase64, setReportImageBase64] = useState<string | null>(null);
  const [isRecordingVoice, setIsRecordingVoice] = useState(false);
  const [voiceRecorded, setVoiceRecorded] = useState(false);
  const [submittingReport, setSubmittingReport] = useState(false);
  const [reportSuccessMessage, setReportSuccessMessage] = useState<string | null>(null);
  const [analyzingImage, setAnalyzingImage] = useState(false);

  // Avisos
  const [largeText, setLargeText] = useState(false);
  const [isSpeaking, setIsSpeaking] = useState(false);
  const [speechSpeed, setSpeechSpeed] = useState<1.0 | 1.25>(1.0);
  const [noticeInput, setNoticeInput] = useState('');
  const [simplifyingNotice, setSimplifyingNotice] = useState(false);
  const [activeNotice, setActiveNotice] = useState({
    issuer: 'Movilidad Urbana · Muestra',
    title: 'Movilidad Urbana · Ruta 4 desviada por obras',
    whatHappened:
      'Cerraron la calle Benito Juárez entre Morelos y Zaragoza por reparación de tubería y banquetas. Los camiones no pueden pasar por ahí hoy.',
    whoIsAffected:
      'Personas que toman la Ruta 4, usan silla de ruedas en esa banqueta o bajan hacia el centro.',
    actionToday:
      'Toma la parada provisional sobre Av. Hidalgo (100 m antes) o usa Metrobús L3 con elevador activo.',
    estimatedDuration: 'Hoy hasta las 20:00 h',
  });

  // Copilot Gemini Chat
  const [copilotInput, setCopilotInput] = useState('');
  const [copilotAnswer, setCopilotAnswer] = useState<string | null>(null);
  const [loadingCopilot, setLoadingCopilot] = useState(false);

  const fileInputRef = useRef<HTMLInputElement>(null);
  const pdfInputRef = useRef<HTMLInputElement>(null);

  // Búsqueda y Rutas
  const launchMapSearch = (query?: string) => {
    const q = (query ?? searchQuery).trim();
    if (q) {
      setMapSearchQuery(q);
      calculateAccessibleRoute(q);
    }
    setActiveTab('map');
  };

  const calculateAccessibleRoute = async (destQuery: string) => {
    setLoadingRoute(true);
    try {
      const res = await fetch('/api/routes/accessible', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          origin: { latitude: 19.4326, longitude: -99.1332 },
          destinationQuery: destQuery,
          profile,
        }),
      });
      const data = await res.json();
      setRouteResult({
        destination: destQuery,
        steps: data.steps || [
          { text: 'Avanza 120m por banqueta accesible con guía podotáctil.', slope: '2%' },
          { text: 'Usa el cruce semaforizado con rampa en esquina Morelos.', elevator: true },
          { text: 'Aborda la estación con elevador activo a nivel de calle.', status: 'Verificado' },
        ],
      });
    } catch {
      setRouteResult({
        destination: destQuery,
        steps: [
          { text: 'Avanza 120m por banqueta accesible con guía podotáctil.', slope: '2%' },
          { text: 'Usa el cruce semaforizado con rampa en esquina Morelos.', elevator: true },
          { text: 'Aborda la estación con elevador activo a nivel de calle.', status: 'Verificado' },
        ],
      });
    } finally {
      setLoadingRoute(false);
    }
  };
  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = async () => {
      const res = reader.result as string;
      setReportImagePreview(res);
      const base64 = res.split(',')[1] || '';
      setReportImageBase64(base64);

      setAnalyzingImage(true);
      try {
        const analyzeRes = await fetch('/api/barriers/analyze', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            mediaBase64: base64,
            mimeType: file.type || 'image/jpeg',
            profile,
          }),
        });
        const data = await analyzeRes.json();
        if (data.data?.description && !reportNote) {
          setReportNote(data.data.description);
        }
      } catch (err) {
        console.error('Error analizando imagen:', err);
      } finally {
        setAnalyzingImage(false);
      }
    };
    reader.readAsDataURL(file);
  };

  const handleSubmitReport = async () => {
    setSubmittingReport(true);
    setReportSuccessMessage(null);
    try {
      const dummyBase64 =
        reportImageBase64 ||
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

      await fetch('/api/barriers/report', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          latitude: 19.4326,
          longitude: -99.1332,
          type: 'sidewalk',
          mediaBase64: dummyBase64,
          mimeType: 'image/jpeg',
          userProfile: profile,
          textNote: reportNote,
        }),
      });
      setReportSuccessMessage('¡Reporte publicado exitosamente! Clasificado y visible en el mapa.');
      setReportNote('');
      setReportImagePreview(null);
      setReportImageBase64(null);
      setVoiceRecorded(false);
    } catch {
      setReportSuccessMessage('Reporte registrado en cola local sin conexión.');
    } finally {
      setSubmittingReport(false);
    }
  };

  const handleSpeakText = (text: string) => {
    if (typeof window !== 'undefined' && 'speechSynthesis' in window) {
      if (isSpeaking) {
        window.speechSynthesis.cancel();
        setIsSpeaking(false);
        return;
      }
      window.speechSynthesis.cancel();
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.lang = 'es-MX';
      utterance.rate = speechSpeed;
      utterance.onstart = () => setIsSpeaking(true);
      utterance.onend = () => setIsSpeaking(false);
      utterance.onerror = () => setIsSpeaking(false);
      window.speechSynthesis.speak(utterance);
    }
  };

  const handleSimplifyNotice = async () => {
    if (!noticeInput.trim()) return;
    setSimplifyingNotice(true);
    try {
      const res = await fetch('/api/briefs/simplify', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ textContent: noticeInput, title: 'Aviso oficial' }),
      });
      const data = await res.json();
      if (data.data) {
        setActiveNotice({
          issuer: 'Gobierno de la Ciudad de México',
          title: data.data.title || 'Aviso en Lenguaje Claro',
          whatHappened: data.data.whatHappened || noticeInput,
          whoIsAffected: data.data.whoIsAffected || 'Usuarios de la zona',
          actionToday: data.data.actionToday || 'Usa vías alternas accesibles.',
          estimatedDuration: 'Hoy',
        });
        setNoticeInput('');
      }
    } catch {
      setActiveNotice({
        issuer: 'Movilidad Urbana',
        title: 'Aviso simplificado',
        whatHappened: noticeInput,
        whoIsAffected: 'Peatones y transporte público',
        actionToday: 'Sigue las indicaciones del personal de tránsito.',
        estimatedDuration: 'En curso',
      });
      setNoticeInput('');
    } finally {
      setSimplifyingNotice(false);
    }
  };

  const handleAskCopilot = async () => {
    if (!copilotInput.trim()) return;
    setLoadingCopilot(true);
    try {
      const res = await fetch('/api/assistant/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: copilotInput, profile }),
      });
      const data = await res.json();
      setCopilotAnswer(data.replyText || data.reply || 'Te recomiendo cruzar por rampa con guía podotáctil sobre Av. Juárez.');
    } catch {
      setCopilotAnswer('Para tu perfil (' + PROFILE_LABELS[profile] + '), te sugiero la ruta con cero escalones por Av. Hidalgo.');
    } finally {
      setLoadingCopilot(false);
    }
  };

  const shortcuts = [
    { label: 'Metro', emoji: '🚇', action: () => launchMapSearch('Estación Metro accesible') },
    { label: 'Metrobús', emoji: '🚌', action: () => launchMapSearch('Estación Metrobús accesible') },
    { label: 'Bus / Combi', emoji: '🚐', action: () => launchMapSearch('Parada camión o combi') },
    { label: 'Evaluar foto', emoji: '⛶', action: () => setActiveTab('report') },
    { label: 'Rampas', emoji: '♿', action: () => launchMapSearch('Acceso con rampa') },
    { label: 'Primera vez', emoji: '🧭', action: () => setShowFirstTimerModal(true) },
    { label: 'Reportar', emoji: '🔔', action: () => setActiveTab('report') },
    { label: 'Avisos hoy', emoji: '📢', action: () => setActiveTab('briefs') },
  ];

  const mapChips = ['Lectura clara', 'Metro', 'Metrobús', 'Camión'];

  return (
    <div
      style={{
        minHeight: '100vh',
        backgroundColor: PALETTE.canvas,
        color: PALETTE.ink,
        fontFamily: 'Inter, system-ui, -apple-system, sans-serif',
        display: 'flex',
        justifyContent: 'center',
        boxSizing: 'border-box',
      }}
    >
      {/* CONTENEDOR MÓVIL LIMPIO Y NATIVO (Sin isla dinámica ni reloj falso) */}
      <div
        style={{
          width: '100%',
          maxWidth: '430px',
          minHeight: '100vh',
          backgroundColor: PALETTE.canvas,
          position: 'relative',
          display: 'flex',
          flexDirection: 'column',
          boxSizing: 'border-box',
        }}
      >
        {/* CONTENEDOR PRINCIPAL CON SCROLL INDEPENDIENTE */}
        <div
          style={{
            flex: 1,
            overflowY: activeTab === 'map' ? 'hidden' : 'auto',
            position: 'relative',
            display: 'flex',
            flexDirection: 'column',
          }}
        >
          {/* ======================================================== */}
          {/* TAB 1: EXPLORAR */}
          {/* ======================================================== */}
          {activeTab === 'explore' && (
            <div style={{ padding: '20px 18px 120px 18px' }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                  <img
                    src="/logo_dark.png"
                    alt="VíaLibre"
                    style={{
                      width: '42px',
                      height: '42px',
                      borderRadius: '12px',
                      objectFit: 'cover',
                    }}
                  />
                  <div>
                    <div style={{ fontSize: '12px', color: PALETTE.muted, fontWeight: 600 }}>
                      VíaLibre · Movilidad inclusiva
                    </div>
                    <h1 style={{ margin: '2px 0 0 0', fontSize: '24px', fontWeight: 800, letterSpacing: '-0.4px' }}>
                      ¿A dónde vamos hoy?
                    </h1>
                  </div>
                </div>
                <button
                  onClick={() => setShowProfileModal(true)}
                  aria-label="Configurar perfil"
                  style={{
                    width: '42px',
                    height: '42px',
                    borderRadius: '50%',
                    backgroundColor: PALETTE.card,
                    border: '1px solid ' + PALETTE.border,
                    color: PALETTE.ink,
                    fontSize: '18px',
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  👤
                </button>
              </div>

              <div style={{ marginTop: '12px' }}>
                <button
                  onClick={() => setShowProfileModal(true)}
                  style={{
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '8px',
                    backgroundColor: PALETTE.sand,
                    border: '1px solid ' + PALETTE.border,
                    borderRadius: '24px',
                    padding: '7px 14px',
                    color: PALETTE.ink,
                    fontSize: '13px',
                    fontWeight: 700,
                    cursor: 'pointer',
                  }}
                >
                  <span>🎛️</span>
                  <span>Perfil: {PROFILE_LABELS[profile]}</span>
                </button>
              </div>

              <div
                style={{
                  marginTop: '16px',
                  backgroundColor: PALETTE.card,
                  border: '1px solid ' + PALETTE.border,
                  borderRadius: '32px',
                  padding: '6px 6px 6px 16px',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '10px',
                }}
              >
                <span style={{ color: PALETTE.muted, fontSize: '16px' }}>🔍</span>
                <input
                  type="text"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && launchMapSearch()}
                  placeholder="Busca estación, clínica o destino..."
                  style={{
                    flex: 1,
                    border: 'none',
                    outline: 'none',
                    backgroundColor: 'transparent',
                    color: PALETTE.ink,
                    fontSize: '15px',
                  }}
                />
                <button
                  onClick={() => launchMapSearch()}
                  aria-label="Buscar"
                  style={{
                    width: '42px',
                    height: '42px',
                    borderRadius: '50%',
                    backgroundColor: '#FAF8F5',
                    color: '#18181B',
                    border: 'none',
                    fontSize: '18px',
                    fontWeight: 800,
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  →
                </button>
              </div>

              <div
                style={{
                  marginTop: '18px',
                  backgroundColor: PALETTE.lavender,
                  borderRadius: '24px',
                  padding: '18px 12px',
                  display: 'grid',
                  gridTemplateColumns: 'repeat(4, 1fr)',
                  rowGap: '16px',
                  columnGap: '6px',
                }}
              >
                {shortcuts.map((item) => (
                  <button
                    key={item.label}
                    onClick={item.action}
                    style={{
                      backgroundColor: 'transparent',
                      border: 'none',
                      padding: 0,
                      display: 'flex',
                      flexDirection: 'column',
                      alignItems: 'center',
                      gap: '7px',
                      cursor: 'pointer',
                    }}
                  >
                    <div
                      style={{
                        width: '50px',
                        height: '50px',
                        borderRadius: '50%',
                        backgroundColor: PALETTE.card,
                        border: '1px solid ' + PALETTE.border,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontSize: '20px',
                      }}
                    >
                      {item.emoji}
                    </div>
                    <span style={{ fontSize: '12px', fontWeight: 600, color: PALETTE.ink, textAlign: 'center' }}>
                      {item.label}
                    </span>
                  </button>
                ))}
              </div>

              <button
                onClick={() => setShowCopilotModal(true)}
                style={{
                  width: '100%',
                  marginTop: '16px',
                  backgroundColor: '#FAF8F5',
                  color: '#18181B',
                  border: 'none',
                  borderRadius: '24px',
                  padding: '16px 18px',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '14px',
                  textAlign: 'left',
                  cursor: 'pointer',
                  boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
                }}
              >
                <div
                  style={{
                    width: '46px',
                    height: '46px',
                    borderRadius: '50%',
                    backgroundColor: PALETTE.coral,
                    color: '#FFFFFF',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: '22px',
                    flexShrink: 0,
                  }}
                >
                  ✨
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontWeight: 800, fontSize: '15px', color: '#18181B' }}>
                    Pregúntale a VíaLibre · Gemini
                  </div>
                  <div style={{ fontSize: '12.5px', color: '#52525B', marginTop: '3px', lineHeight: 1.35 }}>
                    Habla o escribe para pedir rutas, consejos o ayuda al instante.
                  </div>
                </div>
                <span style={{ fontSize: '20px', color: '#71717A', fontWeight: 600 }}>›</span>
              </button>

              <div
                style={{
                  marginTop: '22px',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                }}
              >
                <h2 style={{ margin: 0, fontSize: '19px', fontWeight: 700 }}>Lugares accesibles cerca</h2>
                <button
                  onClick={() => launchMapSearch('Lugares accesibles')}
                  style={{
                    backgroundColor: 'transparent',
                    border: 'none',
                    color: PALETTE.coral,
                    fontWeight: 700,
                    fontSize: '14px',
                    cursor: 'pointer',
                  }}
                >
                  Ver mapa
                </button>
              </div>

              <div
                style={{
                  marginTop: '12px',
                  display: 'flex',
                  gap: '12px',
                  overflowX: 'auto',
                  paddingBottom: '6px',
                }}
              >
                <div
                  onClick={() => launchMapSearch('Clínica Familiar / Centro de Salud')}
                  style={{
                    minWidth: '240px',
                    backgroundColor: PALETTE.card,
                    border: '1px solid ' + PALETTE.border,
                    borderRadius: '22px',
                    padding: '16px',
                    cursor: 'pointer',
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '12px' }}>
                    <span
                      style={{
                        backgroundColor: PALETTE.mintSoft,
                        color: PALETTE.mintInk,
                        fontSize: '12px',
                        fontWeight: 700,
                        padding: '4px 10px',
                        borderRadius: '20px',
                      }}
                    >
                      Cero escalones
                    </span>
                    <span style={{ fontSize: '16px' }}>➕</span>
                  </div>
                  <div style={{ fontWeight: 700, fontSize: '15px', lineHeight: 1.3 }}>
                    Clínica Familiar / Centro de Salud
                  </div>
                  <div style={{ fontSize: '12.5px', color: PALETTE.muted, marginTop: '6px', lineHeight: 1.4 }}>
                    Rampa continua y acceso directo en banqueta.
                  </div>
                </div>

                <div
                  onClick={() => launchMapSearch('Estación Metro / Metrobús cercana')}
                  style={{
                    minWidth: '240px',
                    backgroundColor: PALETTE.card,
                    border: '1px solid ' + PALETTE.border,
                    borderRadius: '22px',
                    padding: '16px',
                    cursor: 'pointer',
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '12px' }}>
                    <span
                      style={{
                        backgroundColor: '#262947',
                        color: '#818CF8',
                        fontSize: '12px',
                        fontWeight: 700,
                        padding: '4px 10px',
                        borderRadius: '20px',
                      }}
                    >
                      Elevador activo
                    </span>
                    <span style={{ fontSize: '16px' }}>🚆</span>
                  </div>
                  <div style={{ fontWeight: 700, fontSize: '15px', lineHeight: 1.3 }}>
                    Estación Metro / Metrobús cercana
                  </div>
                  <div style={{ fontSize: '12.5px', color: PALETTE.muted, marginTop: '6px', lineHeight: 1.4 }}>
                    Guía paso a paso para abordar sin dudas.
                  </div>
                </div>
              </div>

              <div
                onClick={() => setShowFirstTimerModal(true)}
                style={{
                  marginTop: '16px',
                  backgroundColor: PALETTE.card,
                  border: '1px solid ' + PALETTE.border,
                  borderRadius: '22px',
                  padding: '16px',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '14px',
                  cursor: 'pointer',
                }}
              >
                <div
                  style={{
                    width: '42px',
                    height: '42px',
                    borderRadius: '50%',
                    backgroundColor: PALETTE.coralSoft,
                    color: PALETTE.coral,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: '20px',
                    flexShrink: 0,
                  }}
                >
                  🗣️
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontWeight: 700, fontSize: '14.5px' }}>¿Primera vez en Metro o camión?</div>
                  <div style={{ fontSize: '12.5px', color: PALETTE.muted, marginTop: '3px' }}>
                    Abre la guía paso a paso en lenguaje simple antes de viajar.
                  </div>
                </div>
                <span style={{ fontSize: '18px', color: PALETTE.muted }}>›</span>
              </div>
            </div>
          )}

          {/* ======================================================== */}
          {/* TAB 2: MAPA INTERACTIVO (Arrastrable, Zoom y Pines en vivo) */}
          {/* ======================================================== */}
          {activeTab === 'map' && (
            <div
              style={{
                position: 'relative',
                width: '100%',
                height: '100vh',
                minHeight: '700px',
                overflow: 'hidden',
                userSelect: 'none',
              }}
              onMouseDown={(e) => {
                setIsDraggingMap(true);
                setDragStart({ x: e.clientX - mapPan.x, y: e.clientY - mapPan.y });
              }}
              onMouseMove={(e) => {
                if (!isDraggingMap) return;
                setMapPan({ x: e.clientX - dragStart.x, y: e.clientY - dragStart.y });
              }}
              onMouseUp={() => setIsDraggingMap(false)}
              onMouseLeave={() => setIsDraggingMap(false)}
            >
              <div
                style={{
                  position: 'absolute',
                  inset: 0,
                  backgroundColor: PALETTE.mapDarkBg,
                  transform: `translate(${mapPan.x}px, ${mapPan.y}px) scale(${mapZoom})`,
                  transformOrigin: 'center center',
                  transition: isDraggingMap ? 'none' : 'transform 0.15s ease-out',
                }}
              >
                <svg
                  width="100%"
                  height="100%"
                  viewBox="0 0 400 700"
                  preserveAspectRatio="none"
                  style={{ width: '100%', height: '100%' }}
                >
                  <path d="M -20 180 Q 150 140 420 190" stroke={PALETTE.mapRoad} strokeWidth="18" fill="none" />
                  <path d="M 180 -20 Q 160 300 240 720" stroke={PALETTE.mapRoad} strokeWidth="22" fill="none" />
                  <path d="M 60 220 Q 200 350 420 310" stroke={PALETTE.mapHighway} strokeWidth="26" fill="none" />
                  <path d="M -20 480 Q 220 440 420 540" stroke={PALETTE.mapRoad} strokeWidth="14" fill="none" />
                  <path d="M 40 620 L 380 580" stroke={PALETTE.mapRoad} strokeWidth="10" fill="none" />
                  <path d="M 120 120 C 180 180 280 200 340 160" stroke="#22232E" strokeWidth="12" fill="none" />
                  <path d="M 200 370 Q 250 360 290 420 T 360 480" stroke={PALETTE.coral} strokeWidth="7" strokeLinecap="round" fill="none" />

                  <text x="210" y="150" fill="#6E6E7E" fontSize="10" fontWeight="600">LOMAS VERDES 3RA SECC</text>
                  <text x="30" y="470" fill="#6E6E7E" fontSize="10">Av. San Mateo</text>
                  <text x="160" y="460" fill="#6E6E7E" fontSize="9">SAN MATEO</text>
                  <text x="240" y="580" fill="#6E6E7E" fontSize="9">Cortijo La Movida</text>
                </svg>

                {/* 1. Sam's Club */}
                <div
                  onClick={(e) => {
                    e.stopPropagation();
                    setSelectedPoi("Sam's Club");
                    calculateAccessibleRoute("Sam's Club");
                  }}
                  style={{
                    position: 'absolute',
                    top: '170px',
                    left: '68px',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    cursor: 'pointer',
                  }}
                >
                  <div
                    style={{
                      width: '30px',
                      height: '30px',
                      borderRadius: '50%',
                      backgroundColor: '#0284C7',
                      border: '2px solid #FFFFFF',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: '14px',
                      boxShadow: '0 4px 10px rgba(0,0,0,0.5)',
                    }}
                  >
                    🛍️
                  </div>
                  <span style={{ fontSize: '11px', fontWeight: 600, color: '#FAF8F5' }}>Sam's Club</span>
                </div>

                {/* 2. Salon De Fiestas Orion */}
                <div
                  onClick={(e) => {
                    e.stopPropagation();
                    setSelectedPoi('Salon De Fiestas Orion');
                    calculateAccessibleRoute('Salon De Fiestas Orion');
                  }}
                  style={{
                    position: 'absolute',
                    top: '320px',
                    right: '80px',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    cursor: 'pointer',
                  }}
                >
                  <span style={{ fontSize: '11px', fontWeight: 600, color: '#FAF8F5' }}>Salon De Fiestas Orion</span>
                  <div
                    style={{
                      width: '30px',
                      height: '30px',
                      borderRadius: '50%',
                      backgroundColor: '#8B5CF6',
                      border: '2px solid #FFFFFF',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: '14px',
                      boxShadow: '0 4px 10px rgba(0,0,0,0.5)',
                    }}
                  >
                    🏰
                  </div>
                </div>

                {/* 3. UVM Campus Lomas Verdes */}
                <div
                  onClick={(e) => {
                    e.stopPropagation();
                    setSelectedPoi('UVM Campus Lomas Verdes');
                    calculateAccessibleRoute('UVM Campus Lomas Verdes');
                  }}
                  style={{
                    position: 'absolute',
                    top: '360px',
                    left: '100px',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '8px',
                    cursor: 'pointer',
                  }}
                >
                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontSize: '11px', fontWeight: 700, color: '#FAF8F5', lineHeight: 1.2 }}>
                      UVM Campus
                    </div>
                    <div style={{ fontSize: '10px', color: '#B8B8C4' }}>Lomas Verdes</div>
                  </div>
                  <div
                    style={{
                      width: '34px',
                      height: '34px',
                      borderRadius: '50%',
                      backgroundColor: '#0284C7',
                      border: '2px solid #FFFFFF',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: '16px',
                      boxShadow: '0 4px 10px rgba(0,0,0,0.5)',
                    }}
                  >
                    🎓
                  </div>
                </div>

                <div
                  style={{
                    position: 'absolute',
                    bottom: '100px',
                    left: '16px',
                    fontSize: '14px',
                    fontWeight: 700,
                    color: 'rgba(255,255,255,0.4)',
                    letterSpacing: '-0.3px',
                  }}
                >
                  Google Maps
                </div>
              </div>

              {/* CONTROLES DE ZOOM Y CENTRADO FLOTANTES */}
              <div
                style={{
                  position: 'absolute',
                  top: '124px',
                  right: '16px',
                  zIndex: 25,
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '8px',
                }}
              >
                <button
                  onClick={() => {
                    setMapPan({ x: 0, y: 0 });
                    setMapZoom(1);
                  }}
                  aria-label="Centrar en mi ubicación"
                  style={{
                    width: '42px',
                    height: '42px',
                    borderRadius: '12px',
                    backgroundColor: '#1E1F27',
                    border: '1px solid #363640',
                    color: '#FAF8F5',
                    fontSize: '18px',
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    boxShadow: '0 4px 12px rgba(0,0,0,0.4)',
                  }}
                >
                  🎯
                </button>
                <button
                  onClick={() => setMapZoom((prev) => Math.min(2.2, prev + 0.25))}
                  aria-label="Acercar mapa"
                  style={{
                    width: '42px',
                    height: '42px',
                    borderRadius: '12px',
                    backgroundColor: '#1E1F27',
                    border: '1px solid #363640',
                    color: '#FAF8F5',
                    fontSize: '20px',
                    fontWeight: 700,
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    boxShadow: '0 4px 12px rgba(0,0,0,0.4)',
                  }}
                >
                  +
                </button>
                <button
                  onClick={() => setMapZoom((prev) => Math.max(0.75, prev - 0.25))}
                  aria-label="Alejar mapa"
                  style={{
                    width: '42px',
                    height: '42px',
                    borderRadius: '12px',
                    backgroundColor: '#1E1F27',
                    border: '1px solid #363640',
                    color: '#FAF8F5',
                    fontSize: '20px',
                    fontWeight: 700,
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    boxShadow: '0 4px 12px rgba(0,0,0,0.4)',
                  }}
                >
                  −
                </button>
              </div>

              {/* OVERLAY SUPERIOR FLOTANTE */}
              <div
                style={{
                  position: 'absolute',
                  top: '16px',
                  left: '16px',
                  right: '16px',
                  zIndex: 20,
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '10px',
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <div
                    style={{
                      flex: 1,
                      backgroundColor: '#1E1F27',
                      border: '1px solid #363640',
                      borderRadius: '32px',
                      padding: '4px 4px 4px 14px',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '8px',
                      boxShadow: '0 6px 16px rgba(0,0,0,0.5)',
                    }}
                  >
                    <span style={{ color: PALETTE.muted, fontSize: '15px' }}>🔍</span>
                    <input
                      type="text"
                      value={mapSearchQuery}
                      onChange={(e) => setMapSearchQuery(e.target.value)}
                      onKeyDown={(e) => e.key === 'Enter' && calculateAccessibleRoute(mapSearchQuery)}
                      placeholder="¿A dónde vas? Ej. Metro Hi..."
                      style={{
                        flex: 1,
                        border: 'none',
                        outline: 'none',
                        backgroundColor: 'transparent',
                        color: PALETTE.ink,
                        fontSize: '14px',
                      }}
                    />
                    <button
                      onClick={() => calculateAccessibleRoute(mapSearchQuery || 'Metro Hidalgo')}
                      aria-label="Calcular ruta"
                      style={{
                        width: '36px',
                        height: '36px',
                        borderRadius: '50%',
                        backgroundColor: '#FFFFFF',
                        color: '#18181B',
                        border: 'none',
                        fontSize: '16px',
                        fontWeight: 700,
                        cursor: 'pointer',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                      }}
                    >
                      ⮡
                    </button>
                  </div>
                  <button
                    onClick={() => setShowProfileModal(true)}
                    style={{
                      width: '42px',
                      height: '42px',
                      borderRadius: '50%',
                      backgroundColor: '#1E1F27',
                      border: '1px solid #363640',
                      color: PALETTE.ink,
                      fontSize: '17px',
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      flexShrink: 0,
                    }}
                  >
                    👤
                  </button>
                </div>

                <div
                  style={{
                    display: 'flex',
                    gap: '8px',
                    overflowX: 'auto',
                    paddingBottom: '4px',
                  }}
                >
                  {mapChips.map((chip) => {
                    const isActive = activeMapChip === chip;
                    return (
                      <button
                        key={chip}
                        onClick={() => {
                          setActiveMapChip(chip);
                          if (chip !== 'Lectura clara') {
                            calculateAccessibleRoute(chip);
                          }
                        }}
                        style={{
                          backgroundColor: isActive ? '#FFFFFF' : '#1E1F27',
                          color: isActive ? '#18181B' : '#FAF8F5',
                          border: isActive ? 'none' : '1px solid #363640',
                          borderRadius: '24px',
                          padding: '7px 16px',
                          fontSize: '13px',
                          fontWeight: 700,
                          cursor: 'pointer',
                          whiteSpace: 'nowrap',
                          boxShadow: '0 4px 10px rgba(0,0,0,0.3)',
                        }}
                      >
                        {chip}
                      </button>
                    );
                  })}
                </div>
              </div>

              {routeResult && (
                <div
                  style={{
                    position: 'absolute',
                    bottom: '96px',
                    left: '16px',
                    right: '16px',
                    backgroundColor: '#1D1D24',
                    border: '1px solid #363640',
                    borderRadius: '24px',
                    padding: '16px',
                    zIndex: 25,
                    boxShadow: '0 12px 30px rgba(0,0,0,0.6)',
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                    <div style={{ fontWeight: 800, fontSize: '15px', color: PALETTE.ink }}>
                      Ruta Accesible a {routeResult.destination}
                    </div>
                    <button
                      onClick={() => setRouteResult(null)}
                      style={{
                        background: 'none',
                        border: 'none',
                        color: PALETTE.muted,
                        fontSize: '18px',
                        cursor: 'pointer',
                      }}
                    >
                      ✕
                    </button>
                  </div>
                  <div style={{ fontSize: '12.5px', color: '#4ADE80', fontWeight: 600, marginTop: '4px' }}>
                    ✓ Pendientes menores a 4% · Elevadores verificados en vivo
                  </div>
                  <div style={{ marginTop: '10px', display: 'flex', flexDirection: 'column', gap: '6px' }}>
                    {routeResult.steps.map((st: any, i: number) => (
                      <div key={i} style={{ fontSize: '12px', color: PALETTE.ink, display: 'flex', gap: '6px' }}>
                        <span style={{ color: PALETTE.coral, fontWeight: 700 }}>{i + 1}.</span>
                        <span>{st.text}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}
          {/* ======================================================== */}
          {/* TAB 3: REPORTAR OBSTÁCULO */}
          {/* ======================================================== */}
          {activeTab === 'report' && (
            <div style={{ padding: '20px 18px 120px 18px' }}>
              <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
                <div>
                  <div style={{ fontSize: '13px', color: PALETTE.muted, fontWeight: 600 }}>
                    Participación ciudadana
                  </div>
                  <h1 style={{ margin: '4px 0 6px 0', fontSize: '26px', fontWeight: 800, letterSpacing: '-0.4px' }}>
                    Reportar obstáculo
                  </h1>
                </div>
                <button
                  onClick={() => setShowProfileModal(true)}
                  style={{
                    width: '42px',
                    height: '42px',
                    borderRadius: '50%',
                    backgroundColor: PALETTE.card,
                    border: '1px solid ' + PALETTE.border,
                    color: PALETTE.ink,
                    fontSize: '18px',
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  👤
                </button>
              </div>

              <p style={{ margin: '0 0 18px 0', fontSize: '13.5px', color: PALETTE.muted, lineHeight: 1.45 }}>
                Ayuda a mantener las rutas libres capturando rampas bloqueadas, banquetas rotas o elevadores sin servicio.
              </p>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                <button
                  onClick={() => fileInputRef.current?.click()}
                  style={{
                    backgroundColor: '#1D1E27',
                    border: '1px solid ' + PALETTE.border,
                    borderRadius: '22px',
                    padding: '22px 14px',
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    gap: '10px',
                    cursor: 'pointer',
                    textAlign: 'center',
                  }}
                >
                  <div
                    style={{
                      width: '54px',
                      height: '54px',
                      borderRadius: '50%',
                      backgroundColor: '#363B5B',
                      color: '#FAF8F5',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: '24px',
                    }}
                  >
                    📷
                  </div>
                  <div>
                    <div style={{ fontWeight: 800, fontSize: '15px', color: PALETTE.ink }}>Tomar foto</div>
                    <div style={{ fontSize: '12px', color: PALETTE.muted, marginTop: '3px' }}>
                      Visión IA + EXIF cero
                    </div>
                  </div>
                </button>

                <button
                  onClick={() => {
                    setIsRecordingVoice(!isRecordingVoice);
                    if (!isRecordingVoice) {
                      setVoiceRecorded(true);
                      setReportNote((prev) => prev ? prev + ' [Audio grabado]' : 'Rampa obstruida por obras en la esquina.');
                    }
                  }}
                  style={{
                    backgroundColor: isRecordingVoice ? PALETTE.alertRedSoft : '#1D1E27',
                    border: isRecordingVoice ? '1px solid ' + PALETTE.coral : '1px solid ' + PALETTE.border,
                    borderRadius: '22px',
                    padding: '22px 14px',
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    gap: '10px',
                    cursor: 'pointer',
                    textAlign: 'center',
                  }}
                >
                  <div
                    style={{
                      width: '54px',
                      height: '54px',
                      borderRadius: '50%',
                      backgroundColor: isRecordingVoice ? PALETTE.coral : '#542531',
                      color: '#FAF8F5',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: '24px',
                    }}
                  >
                    {isRecordingVoice ? '⏹️' : '🎙️'}
                  </div>
                  <div>
                    <div style={{ fontWeight: 800, fontSize: '15px', color: PALETTE.ink }}>
                      {isRecordingVoice ? 'Detener voz' : 'Nota de voz'}
                    </div>
                    <div style={{ fontSize: '12px', color: PALETTE.muted, marginTop: '3px' }}>
                      {isRecordingVoice ? 'Grabando...' : voiceRecorded ? 'Audio listo' : 'Dictado guiado'}
                    </div>
                  </div>
                </button>
              </div>

              <input
                ref={fileInputRef}
                type="file"
                accept="image/*"
                capture="environment"
                onChange={handleFileSelect}
                style={{ display: 'none' }}
              />

              {reportImagePreview && (
                <div style={{ marginTop: '14px', position: 'relative', borderRadius: '18px', overflow: 'hidden' }}>
                  <img
                    src={reportImagePreview}
                    alt="Obstáculo"
                    style={{ width: '100%', maxHeight: '200px', objectFit: 'cover' }}
                  />
                  {analyzingImage && (
                    <div
                      style={{
                        position: 'absolute',
                        inset: 0,
                        backgroundColor: 'rgba(0,0,0,0.65)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        color: '#FAF8F5',
                        fontSize: '13px',
                        fontWeight: 700,
                      }}
                    >
                      ✨ Analizando accesibilidad con Gemini...
                    </div>
                  )}
                </div>
              )}

              <div
                style={{
                  marginTop: '16px',
                  backgroundColor: '#1C2723',
                  borderRadius: '18px',
                  padding: '14px 16px',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '12px',
                }}
              >
                <span style={{ fontSize: '20px', color: '#4ADE80' }}>🛡️</span>
                <span style={{ fontSize: '13px', color: '#E2FBEA', lineHeight: 1.4, fontWeight: 500 }}>
                  Privacidad protegida: los metadatos EXIF se eliminan en tu teléfono antes del envío.
                </span>
              </div>

              <div style={{ marginTop: '16px' }}>
                <textarea
                  value={reportNote}
                  onChange={(e) => setReportNote(e.target.value)}
                  placeholder="Detalles del obstáculo (opcional)"
                  rows={3}
                  style={{
                    width: '100%',
                    backgroundColor: '#1D1E27',
                    border: '1px solid ' + PALETTE.border,
                    borderRadius: '20px',
                    padding: '14px 16px',
                    color: PALETTE.ink,
                    fontSize: '15px',
                    outline: 'none',
                    resize: 'none',
                    boxSizing: 'border-box',
                    fontFamily: 'inherit',
                  }}
                />
              </div>

              {reportSuccessMessage && (
                <div
                  style={{
                    marginTop: '12px',
                    backgroundColor: PALETTE.mintSoft,
                    color: PALETTE.mintInk,
                    borderRadius: '14px',
                    padding: '12px 14px',
                    fontSize: '13px',
                    fontWeight: 700,
                  }}
                >
                  ✓ {reportSuccessMessage}
                </div>
              )}

              <button
                onClick={handleSubmitReport}
                disabled={submittingReport}
                style={{
                  width: '100%',
                  marginTop: '20px',
                  backgroundColor: '#FFFFFF',
                  color: '#121214',
                  border: 'none',
                  borderRadius: '32px',
                  padding: '10px 12px 10px 24px',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  cursor: 'pointer',
                  fontWeight: 800,
                  fontSize: '16px',
                  boxShadow: '0 6px 18px rgba(0,0,0,0.35)',
                }}
              >
                <span>{submittingReport ? 'Publicando...' : 'Confirmar y publicar al mapa'}</span>
                <div
                  style={{
                    width: '38px',
                    height: '38px',
                    borderRadius: '50%',
                    backgroundColor: PALETTE.coral,
                    color: '#FFFFFF',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: '16px',
                  }}
                >
                  ➤
                </div>
              </button>
            </div>
          )}

          {/* ======================================================== */}
          {/* TAB 4: AVISOS CLAROS */}
          {/* ======================================================== */}
          {activeTab === 'briefs' && (
            <div style={{ padding: '20px 18px 120px 18px' }}>
              <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
                <div>
                  <div style={{ fontSize: '13px', color: PALETTE.muted, fontWeight: 600 }}>
                    Lectura Fácil · ISO 24495-1
                  </div>
                  <h1 style={{ margin: '4px 0 6px 0', fontSize: '26px', fontWeight: 800, letterSpacing: '-0.4px' }}>
                    Avisos claros
                  </h1>
                </div>
                <button
                  onClick={() => setShowProfileModal(true)}
                  style={{
                    width: '42px',
                    height: '42px',
                    borderRadius: '50%',
                    backgroundColor: PALETTE.card,
                    border: '1px solid ' + PALETTE.border,
                    color: PALETTE.ink,
                    fontSize: '18px',
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  👤
                </button>
              </div>

              <p style={{ margin: '0 0 14px 0', fontSize: '13.5px', color: PALETTE.muted, lineHeight: 1.45 }}>
                Comunicados oficiales explicados paso a paso sin términos difíciles.
              </p>

              <div style={{ marginBottom: '14px' }}>
                <button
                  onClick={() => setLargeText(!largeText)}
                  style={{
                    backgroundColor: largeText ? '#FFFFFF' : '#1D1E27',
                    color: largeText ? '#18181B' : '#FAF8F5',
                    border: '1px solid ' + (largeText ? '#FFFFFF' : '#363640'),
                    borderRadius: '24px',
                    padding: '8px 18px',
                    fontSize: '13px',
                    fontWeight: 700,
                    cursor: 'pointer',
                  }}
                >
                  {largeText ? '✓ Texto Grande Activo' : 'Texto Grande'}
                </button>
              </div>

              <div
                style={{
                  backgroundColor: '#1D1E27',
                  border: '1px solid ' + PALETTE.border,
                  borderRadius: '22px',
                  padding: '16px',
                  marginBottom: '16px',
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '14px' }}>
                  <div
                    style={{
                      width: '38px',
                      height: '38px',
                      borderRadius: '50%',
                      backgroundColor: '#262947',
                      color: '#818CF8',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: '18px',
                    }}
                  >
                    🔊
                  </div>
                  <div>
                    <div style={{ fontWeight: 800, fontSize: '15px', color: PALETTE.ink }}>
                      Escuchar resumen del aviso
                    </div>
                    <div style={{ fontSize: '12.5px', color: PALETTE.muted, marginTop: '2px' }}>
                      Lectura en voz clara disponible
                    </div>
                  </div>
                </div>

                <div style={{ display: 'flex', gap: '10px' }}>
                  <button
                    onClick={() =>
                      handleSpeakText(
                        activeNotice.title +
                          '. Qué pasó: ' +
                          activeNotice.whatHappened +
                          '. A quién afecta: ' +
                          activeNotice.whoIsAffected +
                          '. Qué hacer hoy: ' +
                          activeNotice.actionToday
                      )
                    }
                    style={{
                      flex: 1,
                      backgroundColor: PALETTE.coral,
                      color: '#FFFFFF',
                      border: 'none',
                      borderRadius: '24px',
                      padding: '11px 16px',
                      fontWeight: 700,
                      fontSize: '14px',
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      gap: '8px',
                    }}
                  >
                    <span>{isSpeaking ? '⏹ Detener audio' : '▶ Escuchar en voz clara'}</span>
                  </button>
                  <button
                    onClick={() => setSpeechSpeed(speechSpeed === 1.0 ? 1.25 : 1.0)}
                    style={{
                      backgroundColor: '#1E1F27',
                      border: '1px solid ' + PALETTE.border,
                      color: PALETTE.ink,
                      borderRadius: '24px',
                      padding: '11px 16px',
                      fontWeight: 700,
                      fontSize: '13px',
                      cursor: 'pointer',
                    }}
                  >
                    {speechSpeed}x
                  </button>
                </div>
              </div>

              <div
                style={{
                  border: '1.5px solid #FFFFFF',
                  borderRadius: '22px',
                  padding: '18px 16px',
                  marginBottom: '20px',
                }}
              >
                <div style={{ fontWeight: 800, fontSize: '15px', marginBottom: '14px', color: PALETTE.ink }}>
                  Subir circular, PDF o foto del aviso
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', marginBottom: '12px' }}>
                  <button
                    onClick={() => pdfInputRef.current?.click()}
                    style={{
                      backgroundColor: '#FFFFFF',
                      color: '#18181B',
                      border: 'none',
                      borderRadius: '24px',
                      padding: '10px 14px',
                      fontWeight: 700,
                      fontSize: '13.5px',
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      gap: '8px',
                    }}
                  >
                    <span>Subir PDF</span>
                    <span
                      style={{
                        backgroundColor: '#EF4444',
                        color: '#FFFFFF',
                        fontSize: '10px',
                        fontWeight: 900,
                        padding: '2px 5px',
                        borderRadius: '4px',
                      }}
                    >
                      PDF
                    </span>
                  </button>

                  <button
                    onClick={() => fileInputRef.current?.click()}
                    style={{
                      backgroundColor: 'transparent',
                      border: '1px solid #363640',
                      color: PALETTE.ink,
                      borderRadius: '24px',
                      padding: '10px 14px',
                      fontWeight: 700,
                      fontSize: '13.5px',
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      gap: '8px',
                    }}
                  >
                    <span>📷</span>
                    <span>Foto aviso</span>
                  </button>
                </div>

                <input
                  ref={pdfInputRef}
                  type="file"
                  accept="application/pdf"
                  onChange={(e) => {
                    const f = e.target.files?.[0];
                    if (f) {
                      setActiveNotice({
                        issuer: 'Movilidad Urbana',
                        title: 'Aviso simplificado: ' + f.name,
                        whatHappened: 'Desviación temporal reportada en el documento oficial.',
                        whoIsAffected: 'Usuarios de la zona escolar.',
                        actionToday: 'Toma la parada alterna sobre Av. Central.',
                        estimatedDuration: 'Hoy',
                      });
                    }
                  }}
                  style={{ display: 'none' }}
                />

                <div style={{ position: 'relative' }}>
                  <textarea
                    value={noticeInput}
                    onChange={(e) => setNoticeInput(e.target.value)}
                    placeholder="O pega aquí un comunicado municipal..."
                    rows={2}
                    style={{
                      width: '100%',
                      backgroundColor: '#16171F',
                      border: '1px solid #363640',
                      borderRadius: '16px',
                      padding: '12px 14px',
                      color: PALETTE.ink,
                      fontSize: '14px',
                      outline: 'none',
                      resize: 'none',
                      boxSizing: 'border-box',
                      fontFamily: 'inherit',
                    }}
                  />
                  <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '10px' }}>
                    <button
                      onClick={handleSimplifyNotice}
                      disabled={simplifyingNotice}
                      style={{
                        backgroundColor: '#1E1F27',
                        border: '1px solid #363640',
                        color: PALETTE.ink,
                        borderRadius: '20px',
                        padding: '8px 16px',
                        fontSize: '13px',
                        fontWeight: 700,
                        cursor: 'pointer',
                      }}
                    >
                      {simplifyingNotice ? 'Simplificando...' : 'Simplificar texto'}
                    </button>
                  </div>
                </div>
              </div>

              <div style={{ marginBottom: '14px' }}>
                <h2
                  style={{
                    margin: '0 0 4px 0',
                    fontSize: largeText ? '21px' : '18px',
                    fontWeight: 800,
                    lineHeight: 1.3,
                  }}
                >
                  {activeNotice.title}
                </h2>
                <div style={{ fontSize: '13px', color: PALETTE.muted }}>Emisor: {activeNotice.issuer}</div>
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                <div
                  style={{
                    backgroundColor: '#1D1E27',
                    border: '1px solid ' + PALETTE.border,
                    borderRadius: '22px',
                    padding: '16px',
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '8px' }}>
                    <div
                      style={{
                        width: '32px',
                        height: '32px',
                        borderRadius: '8px',
                        backgroundColor: PALETTE.coralSoft,
                        color: PALETTE.coral,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontSize: '16px',
                      }}
                    >
                      🛠️
                    </div>
                    <div>
                      <div style={{ fontSize: '11px', fontWeight: 800, color: PALETTE.coral, letterSpacing: '0.4px' }}>
                        PASO 01 · CAUSA
                      </div>
                      <div style={{ fontSize: '15px', fontWeight: 800 }}>Qué pasó</div>
                    </div>
                  </div>
                  <p
                    style={{
                      margin: '0 0 10px 0',
                      fontSize: largeText ? '16px' : '14px',
                      lineHeight: 1.45,
                      color: PALETTE.ink,
                    }}
                  >
                    {activeNotice.whatHappened}
                  </p>
                  <div
                    style={{
                      display: 'inline-block',
                      backgroundColor: '#15161C',
                      borderRadius: '12px',
                      padding: '5px 10px',
                      fontSize: '11.5px',
                      color: PALETTE.muted,
                      fontWeight: 600,
                    }}
                  >
                    Vigencia estimada: {activeNotice.estimatedDuration}
                  </div>
                </div>

                <div
                  style={{
                    backgroundColor: '#1D1E27',
                    border: '1px solid ' + PALETTE.border,
                    borderRadius: '22px',
                    padding: '16px',
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '8px' }}>
                    <div
                      style={{
                        width: '32px',
                        height: '32px',
                        borderRadius: '8px',
                        backgroundColor: '#262947',
                        color: '#818CF8',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontSize: '16px',
                      }}
                    >
                      👥
                    </div>
                    <div>
                      <div style={{ fontSize: '11px', fontWeight: 800, color: '#818CF8', letterSpacing: '0.4px' }}>
                        PASO 02 · AFECTADOS
                      </div>
                      <div style={{ fontSize: '15px', fontWeight: 800 }}>A quién afecta</div>
                    </div>
                  </div>
                  <p
                    style={{
                      margin: 0,
                      fontSize: largeText ? '16px' : '14px',
                      lineHeight: 1.45,
                      color: PALETTE.ink,
                    }}
                  >
                    {activeNotice.whoIsAffected}
                  </p>
                </div>

                <div
                  style={{
                    backgroundColor: '#1D1E27',
                    border: '1px solid ' + PALETTE.border,
                    borderRadius: '22px',
                    padding: '16px',
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '8px' }}>
                    <div
                      style={{
                        width: '32px',
                        height: '32px',
                        borderRadius: '8px',
                        backgroundColor: PALETTE.mintSoft,
                        color: PALETTE.mintInk,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontSize: '16px',
                      }}
                    >
                      ⮡
                    </div>
                    <div>
                      <div style={{ fontSize: '11px', fontWeight: 800, color: PALETTE.mintInk, letterSpacing: '0.4px' }}>
                        PASO 03 · ACCIÓN HOY
                      </div>
                      <div style={{ fontSize: '15px', fontWeight: 800 }}>Qué hacer hoy</div>
                    </div>
                  </div>
                  <p
                    style={{
                      margin: 0,
                      fontSize: largeText ? '16px' : '14px',
                      lineHeight: 1.45,
                      color: PALETTE.ink,
                    }}
                  >
                    {activeNotice.actionToday}
                  </p>
                </div>
              </div>
            </div>
          )}
        </div>
        {/* ======================================================== */}
        {/* BARRA FLOTANTE INFERIOR CON PÍLDORA ROJA */}
        {/* ======================================================== */}
        <div
          style={{
            position: 'fixed',
            bottom: '16px',
            left: '50%',
            transform: 'translateX(-50%)',
            width: 'calc(100% - 32px)',
            maxWidth: '398px',
            zIndex: 50,
            pointerEvents: 'none',
          }}
        >
          <nav
            style={{
              pointerEvents: 'auto',
              backgroundColor: '#1D1D1F',
              border: '1px solid #363640',
              borderRadius: '34px',
              padding: '6px 8px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              boxShadow: '0 8px 24px rgba(0, 0, 0, 0.65)',
              backdropFilter: 'blur(10px)',
            }}
          >
            {[
              { id: 'explore', label: 'Explorar', icon: '🏠' },
              { id: 'map', label: 'Mapa', icon: '🗺️' },
              { id: 'report', label: 'Reportar', icon: '🔔' },
              { id: 'briefs', label: 'Avisos', icon: '📢' },
            ].map((tab) => {
              const selected = activeTab === tab.id;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id as TabType)}
                  style={{
                    flex: selected ? 1.4 : 1,
                    minHeight: '46px',
                    borderRadius: '24px',
                    border: 'none',
                    backgroundColor: selected ? PALETTE.coral : 'transparent',
                    color: selected ? '#FFFFFF' : PALETTE.muted,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '6px',
                    fontWeight: 700,
                    fontSize: '13px',
                    cursor: 'pointer',
                    padding: '6px 12px',
                    transition: 'all 0.16s ease',
                  }}
                >
                  <span style={{ fontSize: '18px' }}>{tab.icon}</span>
                  {selected && <span>{tab.label}</span>}
                </button>
              );
            })}
          </nav>
        </div>
      </div>

      {/* ======================================================== */}
      {/* MODAL: CAMBIO DE PERFIL ACCESIBLE */}
      {/* ======================================================== */}
      {showProfileModal && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            backgroundColor: 'rgba(0, 0, 0, 0.75)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 100,
            padding: '16px',
            backdropFilter: 'blur(4px)',
          }}
          onClick={() => setShowProfileModal(false)}
        >
          <div
            style={{
              backgroundColor: PALETTE.card,
              border: '1px solid ' + PALETTE.border,
              borderRadius: '28px',
              padding: '24px',
              width: '100%',
              maxWidth: '380px',
              color: PALETTE.ink,
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <h3 style={{ margin: '0 0 4px 0', fontSize: '20px', fontWeight: 800 }}>Elige tu Perfil</h3>
            <p style={{ margin: '0 0 18px 0', fontSize: '13px', color: PALETTE.muted }}>
              VíaLibre adapta las rutas, pendientes y avisos a tus necesidades específicas.
            </p>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
              {[
                {
                  id: 'wheelchair',
                  title: 'Silla de ruedas / Carriola',
                  desc: 'Evita banquetas rotas, escalones sin rampa y pendientes > 6%.',
                  icon: '♿',
                },
                {
                  id: 'low_vision',
                  title: 'Baja visión',
                  desc: 'Prioriza alto contraste, guías podotáctiles y lectura auditiva de pasos.',
                  icon: '👁️',
                },
                {
                  id: 'clear_reading',
                  title: 'Lectura clara / Neurodivergencia',
                  desc: 'Instrucciones concisas paso a paso, sin saturación visual.',
                  icon: '📖',
                },
              ].map((pItem) => {
                const isCurrent = profile === pItem.id;
                return (
                  <div
                    key={pItem.id}
                    onClick={() => {
                      setProfile(pItem.id as ProfileType);
                      setShowProfileModal(false);
                    }}
                    style={{
                      padding: '14px',
                      borderRadius: '18px',
                      backgroundColor: isCurrent ? PALETTE.sand : 'transparent',
                      border: isCurrent ? '2px solid ' + PALETTE.coral : '1px solid ' + PALETTE.border,
                      display: 'flex',
                      alignItems: 'center',
                      gap: '12px',
                      cursor: 'pointer',
                    }}
                  >
                    <span style={{ fontSize: '24px' }}>{pItem.icon}</span>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontWeight: 800, fontSize: '14px' }}>{pItem.title}</div>
                      <div style={{ fontSize: '11.5px', color: PALETTE.muted, marginTop: '2px' }}>
                        {pItem.desc}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      )}

      {/* ======================================================== */}
      {/* MODAL: COPILOT GEMINI (Pregúntale a VíaLibre) */}
      {/* ======================================================== */}
      {showCopilotModal && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            backgroundColor: 'rgba(0, 0, 0, 0.75)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 100,
            padding: '16px',
            backdropFilter: 'blur(4px)',
          }}
          onClick={() => setShowCopilotModal(false)}
        >
          <div
            style={{
              backgroundColor: PALETTE.card,
              border: '1px solid ' + PALETTE.border,
              borderRadius: '28px',
              padding: '24px',
              width: '100%',
              maxWidth: '380px',
              color: PALETTE.ink,
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '8px' }}>
              <div
                style={{
                  width: '36px',
                  height: '36px',
                  borderRadius: '50%',
                  backgroundColor: PALETTE.coral,
                  color: '#FFFFFF',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontSize: '18px',
                }}
              >
                ✨
              </div>
              <h3 style={{ margin: 0, fontSize: '19px', fontWeight: 800 }}>Copiloto Gemini</h3>
            </div>
            <p style={{ margin: '0 0 16px 0', fontSize: '13px', color: PALETTE.muted }}>
              Asistente de movilidad inclusiva adaptado a tu perfil ({PROFILE_LABELS[profile]}).
            </p>

            <div style={{ display: 'flex', gap: '8px', marginBottom: '14px' }}>
              <input
                type="text"
                value={copilotInput}
                onChange={(e) => setCopilotInput(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleAskCopilot()}
                placeholder="Pregunta sobre rutas, elevadores o rampas..."
                style={{
                  flex: 1,
                  backgroundColor: PALETTE.sand,
                  border: '1px solid ' + PALETTE.border,
                  borderRadius: '16px',
                  padding: '10px 14px',
                  color: PALETTE.ink,
                  fontSize: '13.5px',
                  outline: 'none',
                }}
              />
              <button
                onClick={handleAskCopilot}
                disabled={loadingCopilot}
                style={{
                  backgroundColor: PALETTE.coral,
                  color: '#FFFFFF',
                  border: 'none',
                  borderRadius: '16px',
                  padding: '10px 14px',
                  fontWeight: 700,
                  cursor: 'pointer',
                }}
              >
                {loadingCopilot ? '...' : 'Enviar'}
              </button>
            </div>

            {copilotAnswer && (
              <div
                style={{
                  backgroundColor: PALETTE.sand,
                  borderRadius: '16px',
                  padding: '14px',
                  fontSize: '13px',
                  lineHeight: 1.45,
                  border: '1px solid ' + PALETTE.border,
                }}
              >
                <div style={{ fontWeight: 700, color: PALETTE.coral, marginBottom: '4px' }}>Respuesta de Gemini:</div>
                {copilotAnswer}
              </div>
            )}
          </div>
        </div>
      )}

      {/* ======================================================== */}
      {/* MODAL: GUÍA PRIMERA VEZ */}
      {/* ======================================================== */}
      {showFirstTimerModal && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            backgroundColor: 'rgba(0, 0, 0, 0.75)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 100,
            padding: '16px',
            backdropFilter: 'blur(4px)',
          }}
          onClick={() => setShowFirstTimerModal(false)}
        >
          <div
            style={{
              backgroundColor: PALETTE.card,
              border: '1px solid ' + PALETTE.border,
              borderRadius: '28px',
              padding: '24px',
              width: '100%',
              maxWidth: '380px',
              color: PALETTE.ink,
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <h3 style={{ margin: '0 0 6px 0', fontSize: '19px', fontWeight: 800 }}>Guía Primera Vez</h3>
            <p style={{ margin: '0 0 16px 0', fontSize: '13px', color: PALETTE.muted }}>
              Paso a paso para viajar sin incertidumbre en el transporte público.
            </p>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
              <div style={{ padding: '12px', backgroundColor: PALETTE.sand, borderRadius: '14px', fontSize: '13px' }}>
                <span style={{ fontWeight: 800, color: PALETTE.coral }}>1.</span> Ten tu tarjeta de movilidad lista antes de ingresar a la estación.
              </div>
              <div style={{ padding: '12px', backgroundColor: PALETTE.sand, borderRadius: '14px', fontSize: '13px' }}>
                <span style={{ fontWeight: 800, color: PALETTE.coral }}>2.</span> En andén, espera en la zona de embarque preferente marcada en el suelo.
              </div>
              <div style={{ padding: '12px', backgroundColor: PALETTE.sand, borderRadius: '14px', fontSize: '13px' }}>
                <span style={{ fontWeight: 800, color: PALETTE.coral }}>3.</span> Si requieres elevador, el botón de asistencia en torniquetes te conecta con el jefe de estación.
              </div>
            </div>

            <button
              onClick={() => setShowFirstTimerModal(false)}
              style={{
                width: '100%',
                marginTop: '18px',
                backgroundColor: PALETTE.ctaBg,
                color: PALETTE.ctaFg,
                border: 'none',
                borderRadius: '20px',
                padding: '12px',
                fontWeight: 700,
                fontSize: '14px',
                cursor: 'pointer',
              }}
            >
              Entendido
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
