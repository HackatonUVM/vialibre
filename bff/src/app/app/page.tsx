'use client';

import React, { useState, useEffect } from 'react';

type TabType = 'explore' | 'map' | 'report' | 'briefs';
type ProfileType = 'wheelchair' | 'low_vision' | 'clear_reading';

interface Barrier {
  id: string;
  title: string;
  category: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  latitude: number;
  longitude: number;
  confirmations: number;
}

const DARK_PALETTE = {
  isDark: true,
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
};

const LIGHT_PALETTE = {
  isDark: false,
  canvas: '#FAF8F5',
  card: '#FFFFFF',
  sand: '#F1EBE3',
  border: '#E7E2DA',
  ink: '#18181B',
  muted: '#52525B',
  coral: '#C83E4D',
  coralSoft: '#FCE8EA',
  lavender: '#E6E6FA',
  lavenderInk: '#3730A3',
  mintSoft: '#DCFCE7',
  mintInk: '#166534',
  amberSoft: '#FEF3C7',
  amberInk: '#92400E',
  alertRed: '#B91C1C',
  alertRedSoft: '#FEE2E2',
  ctaBg: '#18181B',
  ctaFg: '#FFFFFF',
};

const PROFILE_LABELS: Record<ProfileType, string> = {
  wheelchair: 'Silla de ruedas',
  low_vision: 'Baja visión',
  clear_reading: 'Lectura clara',
};

export default function ViaLibreAppPage() {
  const [isDark, setIsDark] = useState(true);
  const [highContrast, setHighContrast] = useState(false);
  const [activeTab, setActiveTab] = useState<TabType>('explore');
  const [profile, setProfile] = useState<ProfileType>('clear_reading');

  // Modales estilo Calma Urbana
  const [showProfileModal, setShowProfileModal] = useState(false);
  const [showCopilotModal, setShowCopilotModal] = useState(false);
  const [showFirstTimerModal, setShowFirstTimerModal] = useState(false);

  // Explorar & Mapa
  const [searchQuery, setSearchQuery] = useState('');
  const [destination, setDestination] = useState('Clínica Familiar / Centro de Salud');
  const [routeResult, setRouteResult] = useState<any>(null);
  const [loadingRoute, setLoadingRoute] = useState(false);
  const [barriers, setBarriers] = useState<Barrier[]>([]);

  // Reportar
  const [reportType, setReportType] = useState<'photo' | 'audio'>('photo');
  const [selectedImageBase64, setSelectedImageBase64] = useState<string | null>(null);
  const [selectedImagePreview, setSelectedImagePreview] = useState<string | null>(null);
  const [reporting, setReporting] = useState(false);
  const [reportResult, setReportResult] = useState<any>(null);

  // Avisos en Lenguaje Claro
  const [noticeInput, setNoticeInput] = useState('');
  const [translatingNotice, setTranslatingNotice] = useState(false);
  const [noticeResult, setNoticeResult] = useState<any>(null);
  const [speaking, setSpeaking] = useState(false);

  // Copiloto Gemini
  const [copilotPrompt, setCopilotPrompt] = useState('');
  const [copilotAnswer, setCopilotAnswer] = useState<string | null>(null);
  const [loadingCopilot, setLoadingCopilot] = useState(false);

  const p = isDark ? DARK_PALETTE : LIGHT_PALETTE;
  const borderWidth = highContrast ? '2px' : '1px';
  const borderColor = highContrast ? p.ink : p.border;

  useEffect(() => {
    fetch('/api/barriers/nearby?lat=19.4326&lng=-99.1332&radius=1500')
      .then((res) => res.json())
      .then((data) => {
        if (data.barriers && data.barriers.length > 0) {
          setBarriers(data.barriers);
        } else {
          setBarriers([
            {
              id: 'sample-1',
              title: 'Rampa obstruida por obras en Av. Juárez',
              category: 'Rampa inaccesible',
              severity: 'high',
              latitude: 19.4336,
              longitude: -99.1342,
              confirmations: 4,
            },
            {
              id: 'sample-2',
              title: 'Banqueta levantada junto a parada Metrobús',
              category: 'Banqueta obstruida',
              severity: 'medium',
              latitude: 19.4315,
              longitude: -99.132,
              confirmations: 2,
            },
          ]);
        }
      })
      .catch(() => {});
  }, []);

  const handleCalculateRoute = async (customDestination?: string) => {
    const destLabel = customDestination || destination;
    if (customDestination) setDestination(customDestination);
    setLoadingRoute(true);
    try {
      const res = await fetch('/api/routes/accessible', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          origin: { latitude: 19.4326, longitude: -99.1332 },
          destination: { latitude: 19.435, longitude: -99.136 },
          profile,
        }),
      });
      const data = await res.json();
      setRouteResult({ ...data.route, targetName: destLabel });
    } catch (e) {
      console.error(e);
    } finally {
      setLoadingRoute(false);
    }
  };

  const launchMapSearch = (overrideQuery?: string) => {
    const q = (overrideQuery ?? searchQuery).trim();
    setActiveTab('map');
    if (q) {
      handleCalculateRoute(q);
    }
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => {
      const result = reader.result as string;
      setSelectedImagePreview(result);
      const base64 = result.split(',')[1] || '';
      setSelectedImageBase64(base64);
    };
    reader.readAsDataURL(file);
  };

  const handleSendReport = async () => {
    setReporting(true);
    setReportResult(null);
    try {
      const demoBase64 =
        selectedImageBase64 ||
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

      const res = await fetch('/api/barriers/report', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          latitude: 19.4326,
          longitude: -99.1332,
          type: reportType,
          mediaBase64: demoBase64,
          mimeType: 'image/png',
          userProfile: profile,
        }),
      });
      const data = await res.json();
      setReportResult(data.data || { error: data.error });
    } catch (e) {
      console.error(e);
    } finally {
      setReporting(false);
    }
  };

  const handleTranslateNotice = async () => {
    if (!noticeInput.trim()) return;
    setTranslatingNotice(true);
    setNoticeResult(null);
    try {
      const res = await fetch('/api/notices/simplify', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text: noticeInput }),
      });
      const data = await res.json();
      setNoticeResult(data.summary);
    } catch (e) {
      console.error(e);
    } finally {
      setTranslatingNotice(false);
    }
  };

  const handleAskCopilot = async () => {
    if (!copilotPrompt.trim()) return;
    setLoadingCopilot(true);
    setCopilotAnswer(null);
    try {
      const res = await fetch('/api/notices/simplify', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          text: `Consulta del usuario (${PROFILE_LABELS[profile]}): ${copilotPrompt}`,
        }),
      });
      const data = await res.json();
      if (data.summary) {
        setCopilotAnswer(
          `${data.summary.quePaso}\n\nPara tu perfil (${PROFILE_LABELS[profile]}): ${data.summary.queHacerHoy}`
        );
      } else {
        setCopilotAnswer(
          `Para tu perfil (${PROFILE_LABELS[profile]}), te recomiendo ir por cruces semaforizados con rampa continua y evitar obras reportadas en Av. Juárez.`
        );
      }
    } catch {
      setCopilotAnswer(
        `Ruta sugerida para ${PROFILE_LABELS[profile]}: busca entradas con acceso a nivel de banqueta y verifica elevadores antes de bajar.`
      );
    } finally {
      setLoadingCopilot(false);
    }
  };

  const handleSpeakText = (text: string) => {
    if (typeof window !== 'undefined' && 'speechSynthesis' in window) {
      window.speechSynthesis.cancel();
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.lang = 'es-MX';
      utterance.rate = 0.95;
      utterance.onstart = () => setSpeaking(true);
      utterance.onend = () => setSpeaking(false);
      utterance.onerror = () => setSpeaking(false);
      window.speechSynthesis.speak(utterance);
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

  const navItems: { id: TabType; label: string; icon: string }[] = [
    { id: 'explore', label: 'Explorar', icon: '🏠' },
    { id: 'map', label: 'Mapa', icon: '🗺️' },
    { id: 'report', label: 'Reportar', icon: '🔔' },
    { id: 'briefs', label: 'Avisos', icon: '📢' },
  ];

  return (
    <div
      style={{
        minHeight: '100vh',
        backgroundColor: p.canvas,
        color: p.ink,
        display: 'flex',
        justifyContent: 'center',
      }}
    >
      <div
        style={{
          width: '100%',
          maxWidth: '430px',
          minHeight: '100vh',
          backgroundColor: p.canvas,
          color: p.ink,
          position: 'relative',
          display: 'flex',
          flexDirection: 'column',
          paddingBottom: '104px',
          boxSizing: 'border-box',
        }}
      >
        {/* CONTENIDO PRINCIPAL */}
        <main style={{ padding: '18px 18px 24px 18px', flex: 1 }}>
          {/* TAB 1: EXPLORAR (Idéntica a Calma Urbana) */}
          {activeTab === 'explore' && (
            <div>
              {/* Header superior con logo + título + botón perfil */}
              <header
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  gap: '12px',
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                  <img
                    src={p.isDark ? '/logo_dark.png' : '/logo_light.png'}
                    alt="VíaLibre"
                    style={{
                      width: '40px',
                      height: '40px',
                      borderRadius: '11px',
                      objectFit: 'cover',
                    }}
                  />
                  <div>
                    <div style={{ fontSize: '12px', color: p.muted, fontWeight: 600 }}>
                      VíaLibre · Movilidad inclusiva
                    </div>
                    <h1 style={{ margin: '2px 0 0 0', fontSize: '23px', fontWeight: 800, letterSpacing: '-0.4px' }}>
                      ¿A dónde vamos hoy?
                    </h1>
                  </div>
                </div>

                <button
                  onClick={() => setShowProfileModal(true)}
                  aria-label="Abrir configuración de perfil y apariencia"
                  style={{
                    width: '44px',
                    height: '44px',
                    borderRadius: '50%',
                    backgroundColor: p.card,
                    border: `${borderWidth} solid ${borderColor}`,
                    color: p.ink,
                    fontSize: '18px',
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    flexShrink: 0,
                  }}
                >
                  👤
                </button>
              </header>

              {/* Chip de perfil activo */}
              <div style={{ marginTop: '12px' }}>
                <button
                  onClick={() => setShowProfileModal(true)}
                  style={{
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '8px',
                    backgroundColor: p.sand,
                    border: `${borderWidth} solid ${borderColor}`,
                    borderRadius: '24px',
                    padding: '7px 14px',
                    color: p.ink,
                    fontSize: '13px',
                    fontWeight: 700,
                    cursor: 'pointer',
                  }}
                >
                  <span>🎛️</span>
                  <span>Perfil: {PROFILE_LABELS[profile]}</span>
                </button>
              </div>

              {/* Barra de búsqueda píldora */}
              <div
                style={{
                  marginTop: '16px',
                  backgroundColor: p.card,
                  border: `${borderWidth} solid ${borderColor}`,
                  borderRadius: '32px',
                  padding: '6px 6px 6px 16px',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '10px',
                }}
              >
                <span style={{ color: p.muted, fontSize: '16px' }}>🔍</span>
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
                    color: p.ink,
                    fontSize: '15px',
                    minWidth: 0,
                  }}
                />
                <button
                  onClick={() => launchMapSearch()}
                  aria-label="Buscar ruta accesible"
                  style={{
                    width: '44px',
                    height: '44px',
                    borderRadius: '50%',
                    backgroundColor: p.ctaBg,
                    color: p.ctaFg,
                    border: 'none',
                    fontSize: '18px',
                    fontWeight: 700,
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    flexShrink: 0,
                  }}
                >
                  →
                </button>
              </div>

              {/* Contenedor Lavanda con 8 accesos directos */}
              <section
                style={{
                  marginTop: '18px',
                  backgroundColor: p.lavender,
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
                      color: p.ink,
                    }}
                  >
                    <div
                      style={{
                        width: '50px',
                        height: '50px',
                        borderRadius: '50%',
                        backgroundColor: p.card,
                        border: `${borderWidth} solid ${borderColor}`,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontSize: '20px',
                      }}
                    >
                      {item.emoji}
                    </div>
                    <span style={{ fontSize: '12px', fontWeight: 600, color: p.ink, textAlign: 'center' }}>
                      {item.label}
                    </span>
                  </button>
                ))}
              </section>

              {/* Tarjeta CTA Copilot Gemini con círculo coral/rosa */}
              <button
                onClick={() => setShowCopilotModal(true)}
                style={{
                  width: '100%',
                  marginTop: '14px',
                  backgroundColor: p.ctaBg,
                  color: p.ctaFg,
                  border: 'none',
                  borderRadius: '22px',
                  padding: '16px',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '14px',
                  textAlign: 'left',
                  cursor: 'pointer',
                }}
              >
                <div
                  style={{
                    width: '46px',
                    height: '46px',
                    borderRadius: '50%',
                    backgroundColor: p.coral,
                    color: '#FFFFFF',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: '20px',
                    flexShrink: 0,
                  }}
                >
                  ✨
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontWeight: 800, fontSize: '15px' }}>Pregúntale a VíaLibre · Gemini</div>
                  <div style={{ fontSize: '12.5px', opacity: 0.78, marginTop: '3px', lineHeight: 1.35 }}>
                    Habla o escribe para pedir rutas, consejos o ayuda al instante.
                  </div>
                </div>
                <span style={{ fontSize: '16px', opacity: 0.75 }}>›</span>
              </button>

              {/* Lugares accesibles cerca */}
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
                  onClick={() => launchMapSearch('Clínica cercana accesible')}
                  style={{
                    backgroundColor: 'transparent',
                    border: 'none',
                    color: p.coral,
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
                  marginTop: '10px',
                  display: 'flex',
                  gap: '12px',
                  overflowX: 'auto',
                  paddingBottom: '4px',
                }}
              >
                <div
                  onClick={() => launchMapSearch('Clínica Familiar / Centro de Salud')}
                  style={{
                    minWidth: '236px',
                    backgroundColor: p.card,
                    border: `${borderWidth} solid ${borderColor}`,
                    borderRadius: '20px',
                    padding: '16px',
                    cursor: 'pointer',
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '12px' }}>
                    <span
                      style={{
                        backgroundColor: p.mintSoft,
                        color: p.mintInk,
                        fontSize: '12px',
                        fontWeight: 700,
                        padding: '5px 11px',
                        borderRadius: '20px',
                      }}
                    >
                      Cero escalones
                    </span>
                    <span style={{ fontSize: '16px' }}>🏥</span>
                  </div>
                  <div style={{ fontWeight: 700, fontSize: '15px', lineHeight: 1.3 }}>
                    Clínica Familiar / Centro de Salud
                  </div>
                  <div style={{ fontSize: '12.5px', color: p.muted, marginTop: '6px', lineHeight: 1.4 }}>
                    Rampa continua y acceso directo en banqueta.
                  </div>
                </div>

                <div
                  onClick={() => launchMapSearch('Estación Metro / Metrobús cercana')}
                  style={{
                    minWidth: '236px',
                    backgroundColor: p.card,
                    border: `${borderWidth} solid ${borderColor}`,
                    borderRadius: '20px',
                    padding: '16px',
                    cursor: 'pointer',
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '12px' }}>
                    <span
                      style={{
                        backgroundColor: p.lavender,
                        color: p.lavenderInk,
                        fontSize: '12px',
                        fontWeight: 700,
                        padding: '5px 11px',
                        borderRadius: '20px',
                      }}
                    >
                      Elevador activo
                    </span>
                    <span style={{ fontSize: '16px' }}>🚇</span>
                  </div>
                  <div style={{ fontWeight: 700, fontSize: '15px', lineHeight: 1.3 }}>
                    Estación Metro / Metrobús cercana
                  </div>
                  <div style={{ fontSize: '12.5px', color: p.muted, marginTop: '6px', lineHeight: 1.4 }}>
                    Guía paso a paso para abordar sin dudas.
                  </div>
                </div>

                <div
                  onClick={() => setActiveTab('briefs')}
                  style={{
                    minWidth: '236px',
                    backgroundColor: p.card,
                    border: `${borderWidth} solid ${borderColor}`,
                    borderRadius: '20px',
                    padding: '16px',
                    cursor: 'pointer',
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '12px' }}>
                    <span
                      style={{
                        backgroundColor: p.amberSoft,
                        color: p.amberInk,
                        fontSize: '12px',
                        fontWeight: 700,
                        padding: '5px 11px',
                        borderRadius: '20px',
                      }}
                    >
                      Aviso claro hoy
                    </span>
                    <span style={{ fontSize: '16px' }}>📢</span>
                  </div>
                  <div style={{ fontWeight: 700, fontSize: '15px', lineHeight: 1.3 }}>
                    Desvíos y obras en tu zona
                  </div>
                  <div style={{ fontSize: '12.5px', color: p.muted, marginTop: '6px', lineHeight: 1.4 }}>
                    Explicados en 3 pasos y listos para escuchar.
                  </div>
                </div>
              </div>

              {/* Tarjeta Primera Vez */}
              <button
                onClick={() => setShowFirstTimerModal(true)}
                style={{
                  width: '100%',
                  marginTop: '18px',
                  backgroundColor: p.sand,
                  border: `${borderWidth} solid ${borderColor}`,
                  borderRadius: '22px',
                  padding: '16px',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '14px',
                  textAlign: 'left',
                  cursor: 'pointer',
                  color: p.ink,
                }}
              >
                <div
                  style={{
                    width: '48px',
                    height: '48px',
                    borderRadius: '16px',
                    backgroundColor: p.coralSoft,
                    color: p.coral,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: '22px',
                    flexShrink: 0,
                  }}
                >
                  🗣️
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontWeight: 700, fontSize: '15px' }}>¿Primera vez en Metro o camión?</div>
                  <div style={{ fontSize: '12.5px', color: p.muted, marginTop: '4px' }}>
                    Abre la guía paso a paso en lenguaje simple antes de viajar.
                  </div>
                </div>
                <span style={{ fontSize: '16px' }}>›</span>
              </button>
            </div>
          )}

          {/* TAB 2: MAPA Y RUTAS */}
          {activeTab === 'map' && (
            <div>
              <div style={{ fontSize: '12px', color: p.muted, fontWeight: 600 }}>Navegación accesible</div>
              <h1 style={{ margin: '2px 0 14px 0', fontSize: '24px', fontWeight: 800 }}>Mapa y Ruta Segura</h1>

              <div
                style={{
                  backgroundColor: p.card,
                  border: `${borderWidth} solid ${borderColor}`,
                  borderRadius: '20px',
                  padding: '16px',
                  marginBottom: '14px',
                }}
              >
                <label style={{ display: 'block', fontSize: '13px', color: p.muted, marginBottom: '6px' }}>
                  Destino accesible (Perfil: {PROFILE_LABELS[profile]})
                </label>
                <input
                  type="text"
                  value={destination}
                  onChange={(e) => setDestination(e.target.value)}
                  style={{
                    width: '100%',
                    padding: '12px 14px',
                    borderRadius: '14px',
                    border: `${borderWidth} solid ${borderColor}`,
                    backgroundColor: p.sand,
                    color: p.ink,
                    fontSize: '14px',
                    boxSizing: 'border-box',
                  }}
                />
                <button
                  onClick={() => handleCalculateRoute()}
                  disabled={loadingRoute}
                  style={{
                    width: '100%',
                    marginTop: '12px',
                    padding: '13px',
                    borderRadius: '26px',
                    backgroundColor: p.coral,
                    color: '#FFFFFF',
                    fontWeight: 700,
                    fontSize: '15px',
                    border: 'none',
                    cursor: 'pointer',
                  }}
                >
                  {loadingRoute ? 'Calculando ruta accesible...' : '🔍 Calcular Ruta Accesible'}
                </button>
              </div>

              {/* Resumen de barreras en radio activo */}
              <div
                style={{
                  backgroundColor: p.lavender,
                  borderRadius: '20px',
                  padding: '16px',
                  marginBottom: '14px',
                }}
              >
                <div style={{ fontWeight: 700, fontSize: '14px', color: p.lavenderInk }}>
                  📍 Barreras detectadas en el radio activo ({barriers.length})
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginTop: '10px' }}>
                  {barriers.map((b) => (
                    <div
                      key={b.id}
                      style={{
                        backgroundColor: p.card,
                        border: `${borderWidth} solid ${borderColor}`,
                        borderRadius: '14px',
                        padding: '10px 12px',
                        display: 'flex',
                        justifyContent: 'space-between',
                        alignItems: 'center',
                        gap: '10px',
                      }}
                    >
                      <div>
                        <div style={{ fontWeight: 700, fontSize: '13px' }}>{b.title}</div>
                        <div style={{ fontSize: '12px', color: p.muted }}>{b.category}</div>
                      </div>
                      <span
                        style={{
                          fontSize: '11px',
                          fontWeight: 700,
                          padding: '4px 9px',
                          borderRadius: '12px',
                          backgroundColor: p.coralSoft,
                          color: p.coral,
                          flexShrink: 0,
                        }}
                      >
                        {b.confirmations} conf.
                      </span>
                    </div>
                  ))}
                </div>
              </div>

              {routeResult && (
                <div
                  style={{
                    backgroundColor: p.card,
                    border: `${borderWidth} solid ${borderColor}`,
                    borderRadius: '20px',
                    padding: '16px',
                  }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '8px' }}>
                    <div>
                      <span
                        style={{
                          backgroundColor: p.mintSoft,
                          color: p.mintInk,
                          fontSize: '12px',
                          fontWeight: 700,
                          padding: '4px 10px',
                          borderRadius: '14px',
                        }}
                      >
                        Score {routeResult.accessibilityScore}/100
                      </span>
                      <div style={{ fontWeight: 800, fontSize: '16px', marginTop: '6px' }}>
                        {routeResult.distanceMeters} m · {Math.round(routeResult.durationSeconds / 60)} min
                      </div>
                    </div>
                    <button
                      onClick={() =>
                        handleSpeakText(routeResult.steps.map((s: any) => s.instruction).join('. '))
                      }
                      style={{
                        backgroundColor: p.coral,
                        color: '#FFFFFF',
                        border: 'none',
                        borderRadius: '20px',
                        padding: '8px 14px',
                        fontWeight: 700,
                        fontSize: '13px',
                        cursor: 'pointer',
                      }}
                    >
                      🔊 {speaking ? 'Leyendo...' : 'Escuchar'}
                    </button>
                  </div>

                  <div style={{ marginTop: '12px', display: 'flex', flexDirection: 'column', gap: '8px' }}>
                    {routeResult.steps.map((step: any, idx: number) => (
                      <div
                        key={idx}
                        style={{
                          backgroundColor: p.sand,
                          borderRadius: '14px',
                          padding: '11px 12px',
                          fontSize: '13px',
                        }}
                      >
                        <strong>Paso {idx + 1}:</strong> {step.instruction}
                        {step.slopePercentage !== undefined && (
                          <div style={{ fontSize: '11.5px', color: p.mintInk, marginTop: '3px', fontWeight: 600 }}>
                            Pendiente leve: {step.slopePercentage}%
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}

          {/* TAB 3: REPORTAR */}
          {activeTab === 'report' && (
            <div>
              <div style={{ fontSize: '12px', color: p.muted, fontWeight: 600 }}>Colaboración ciudadana</div>
              <h1 style={{ margin: '2px 0 8px 0', fontSize: '24px', fontWeight: 800 }}>Reportar Obstáculo</h1>
              <p style={{ fontSize: '13.5px', color: p.muted, margin: '0 0 16px 0', lineHeight: 1.45 }}>
                Sube una fotografía o nota de voz. Gemini clasifica la barrera y la deduplica en un radio de 25m.
              </p>

              <div style={{ display: 'flex', gap: '10px', marginBottom: '14px' }}>
                <button
                  onClick={() => setReportType('photo')}
                  style={{
                    flex: 1,
                    padding: '12px',
                    borderRadius: '18px',
                    backgroundColor: reportType === 'photo' ? p.coral : p.card,
                    color: reportType === 'photo' ? '#FFFFFF' : p.ink,
                    border: `${borderWidth} solid ${reportType === 'photo' ? p.coral : borderColor}`,
                    fontWeight: 700,
                    cursor: 'pointer',
                  }}
                >
                  📷 Fotografía
                </button>
                <button
                  onClick={() => setReportType('audio')}
                  style={{
                    flex: 1,
                    padding: '12px',
                    borderRadius: '18px',
                    backgroundColor: reportType === 'audio' ? p.coral : p.card,
                    color: reportType === 'audio' ? '#FFFFFF' : p.ink,
                    border: `${borderWidth} solid ${reportType === 'audio' ? p.coral : borderColor}`,
                    fontWeight: 700,
                    cursor: 'pointer',
                  }}
                >
                  🎙️ Nota de voz
                </button>
              </div>

              <label
                style={{
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  justifyContent: 'center',
                  minHeight: '164px',
                  backgroundColor: p.card,
                  border: `2px dashed ${p.coral}`,
                  borderRadius: '20px',
                  padding: '16px',
                  textAlign: 'center',
                  cursor: 'pointer',
                  marginBottom: '14px',
                }}
              >
                {selectedImagePreview && reportType === 'photo' ? (
                  <img
                    src={selectedImagePreview}
                    alt="Vista previa"
                    style={{ maxHeight: '140px', borderRadius: '12px', objectFit: 'cover' }}
                  />
                ) : (
                  <>
                    <span style={{ fontSize: '34px', marginBottom: '8px' }}>
                      {reportType === 'photo' ? '📸' : '🎙️'}
                    </span>
                    <span style={{ fontSize: '13.5px', fontWeight: 600 }}>
                      {reportType === 'photo'
                        ? 'Toca para tomar o subir foto de la barrera'
                        : 'Modo nota de voz listo para análisis'}
                    </span>
                    <span style={{ fontSize: '12px', color: p.muted, marginTop: '4px' }}>
                      Privacidad: metadatos EXIF eliminados antes del envío
                    </span>
                  </>
                )}
                {reportType === 'photo' && (
                  <input type="file" accept="image/*" onChange={handleFileChange} style={{ display: 'none' }} />
                )}
              </label>

              <button
                onClick={handleSendReport}
                disabled={reporting}
                style={{
                  width: '100%',
                  padding: '15px',
                  borderRadius: '28px',
                  backgroundColor: p.coral,
                  color: '#FFFFFF',
                  fontWeight: 700,
                  fontSize: '15px',
                  border: 'none',
                  cursor: 'pointer',
                }}
              >
                {reporting ? 'Gemini analizando y deduplicando...' : '🚀 Analizar y Publicar Reporte'}
              </button>

              {reportResult && (
                <div
                  style={{
                    marginTop: '14px',
                    backgroundColor: p.card,
                    border: `${borderWidth} solid ${borderColor}`,
                    borderRadius: '20px',
                    padding: '16px',
                  }}
                >
                  <span
                    style={{
                      backgroundColor: p.mintSoft,
                      color: p.mintInk,
                      fontSize: '12px',
                      fontWeight: 700,
                      padding: '4px 10px',
                      borderRadius: '14px',
                    }}
                  >
                    ✓ Procesado por Gemini
                  </span>
                  <div style={{ fontWeight: 700, fontSize: '15px', marginTop: '10px' }}>{reportResult.title}</div>
                  <div style={{ fontSize: '13px', color: p.muted, marginTop: '4px' }}>
                    {reportResult.category} · Severidad: {reportResult.severity}
                  </div>
                  <div style={{ fontSize: '12.5px', color: p.coral, marginTop: '6px', fontWeight: 600 }}>
                    {reportResult.isDuplicate
                      ? 'Coincidencia en 25m: confirmación agregada (+1)'
                      : 'Nuevo obstáculo publicado en el mapa'}
                  </div>
                </div>
              )}
            </div>
          )}

          {/* TAB 4: AVISOS EN LENGUAJE CLARO */}
          {activeTab === 'briefs' && (
            <div>
              <div style={{ fontSize: '12px', color: p.muted, fontWeight: 600 }}>ISO 24495-1 · W3C COGA</div>
              <h1 style={{ margin: '2px 0 8px 0', fontSize: '24px', fontWeight: 800 }}>
                Avisos en Lenguaje Claro
              </h1>
              <p style={{ fontSize: '13.5px', color: p.muted, margin: '0 0 14px 0', lineHeight: 1.45 }}>
                Convierte comunicados técnicos o desvíos municipales en 3 pasos fáciles de entender y escuchar.
              </p>

              <textarea
                rows={4}
                value={noticeInput}
                onChange={(e) => setNoticeInput(e.target.value)}
                placeholder="Pega aquí el comunicado o aviso municipal..."
                style={{
                  width: '100%',
                  padding: '14px',
                  borderRadius: '18px',
                  border: `${borderWidth} solid ${borderColor}`,
                  backgroundColor: p.card,
                  color: p.ink,
                  fontSize: '14px',
                  boxSizing: 'border-box',
                  marginBottom: '10px',
                }}
              />

              <button
                onClick={() =>
                  setNoticeInput(
                    'Se informa a la ciudadanía que debido a trabajos de rehabilitación de drenaje en el cuadrante oriente, la circulación peatonal sobre Calzada Juárez quedará suspendida temporalmente debiendo transitar por los desvíos habilitados en Calle Morelos.'
                  )
                }
                style={{
                  backgroundColor: p.sand,
                  color: p.ink,
                  border: `${borderWidth} solid ${borderColor}`,
                  borderRadius: '16px',
                  padding: '7px 12px',
                  fontSize: '12px',
                  fontWeight: 600,
                  cursor: 'pointer',
                  marginBottom: '12px',
                }}
              >
                Cargar aviso de muestra
              </button>

              <button
                onClick={handleTranslateNotice}
                disabled={translatingNotice}
                style={{
                  width: '100%',
                  padding: '15px',
                  borderRadius: '28px',
                  backgroundColor: p.coral,
                  color: '#FFFFFF',
                  fontWeight: 700,
                  fontSize: '15px',
                  border: 'none',
                  cursor: 'pointer',
                }}
              >
                {translatingNotice ? 'Traduciendo a Lenguaje Claro...' : '✨ Traducir a Lenguaje Claro'}
              </button>

              {noticeResult && (
                <div style={{ marginTop: '16px', display: 'flex', flexDirection: 'column', gap: '10px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ fontWeight: 700, fontSize: '14px' }}>Resumen en 3 bloques</span>
                    <button
                      onClick={() =>
                        handleSpeakText(
                          `Qué pasó: ${noticeResult.quePaso}. A quién afecta: ${noticeResult.aQuienAfecta}. Qué hacer hoy: ${noticeResult.queHacerHoy}`
                        )
                      }
                      style={{
                        backgroundColor: p.ctaBg,
                        color: p.ctaFg,
                        border: 'none',
                        borderRadius: '20px',
                        padding: '7px 14px',
                        fontWeight: 700,
                        fontSize: '12.5px',
                        cursor: 'pointer',
                      }}
                    >
                      🔊 {speaking ? 'Leyendo...' : 'Escuchar audio'}
                    </button>
                  </div>

                  <div
                    style={{
                      backgroundColor: p.card,
                      border: `${borderWidth} solid ${borderColor}`,
                      borderRadius: '18px',
                      padding: '14px',
                    }}
                  >
                    <span
                      style={{
                        backgroundColor: p.coralSoft,
                        color: p.coral,
                        fontSize: '11px',
                        fontWeight: 700,
                        padding: '3px 9px',
                        borderRadius: '10px',
                      }}
                    >
                      1. ¿QUÉ PASÓ?
                    </span>
                    <div style={{ fontSize: '14px', marginTop: '8px', lineHeight: 1.45 }}>
                      {noticeResult.quePaso}
                    </div>
                  </div>

                  <div
                    style={{
                      backgroundColor: p.card,
                      border: `${borderWidth} solid ${borderColor}`,
                      borderRadius: '18px',
                      padding: '14px',
                    }}
                  >
                    <span
                      style={{
                        backgroundColor: p.amberSoft,
                        color: p.amberInk,
                        fontSize: '11px',
                        fontWeight: 700,
                        padding: '3px 9px',
                        borderRadius: '10px',
                      }}
                    >
                      2. ¿A QUIÉN AFECTA?
                    </span>
                    <div style={{ fontSize: '14px', marginTop: '8px', lineHeight: 1.45 }}>
                      {noticeResult.aQuienAfecta}
                    </div>
                  </div>

                  <div
                    style={{
                      backgroundColor: p.card,
                      border: `${borderWidth} solid ${borderColor}`,
                      borderRadius: '18px',
                      padding: '14px',
                    }}
                  >
                    <span
                      style={{
                        backgroundColor: p.mintSoft,
                        color: p.mintInk,
                        fontSize: '11px',
                        fontWeight: 700,
                        padding: '3px 9px',
                        borderRadius: '10px',
                      }}
                    >
                      3. ¿QUÉ HACER HOY?
                    </span>
                    <div style={{ fontSize: '14px', marginTop: '8px', lineHeight: 1.45 }}>
                      {noticeResult.queHacerHoy}
                    </div>
                  </div>
                </div>
              )}
            </div>
          )}
        </main>

        {/* BARRA DE NAVEGACIÓN FLOTANTE ESTILO PÍLDORA CON CORAL/ROSA ACTIVO */}
        <nav
          aria-label="Navegación principal"
          style={{
            position: 'fixed',
            bottom: '14px',
            left: '50%',
            transform: 'translateX(-50%)',
            width: 'calc(100% - 32px)',
            maxWidth: '398px',
            backgroundColor: p.card,
            border: `${borderWidth} solid ${borderColor}`,
            borderRadius: '32px',
            padding: '8px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            gap: '4px',
            boxShadow: p.isDark ? '0 8px 24px rgba(0,0,0,0.45)' : '0 8px 24px rgba(0,0,0,0.10)',
            zIndex: 30,
          }}
        >
          {navItems.map((item) => {
            const selected = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => setActiveTab(item.id)}
                style={{
                  flex: selected ? 1.4 : 1,
                  minHeight: '46px',
                  borderRadius: '24px',
                  border: 'none',
                  backgroundColor: selected ? p.coral : 'transparent',
                  color: selected ? '#FFFFFF' : p.muted,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '6px',
                  fontWeight: 700,
                  fontSize: '13px',
                  cursor: 'pointer',
                  padding: '6px 10px',
                  transition: 'all 0.16s ease',
                }}
              >
                <span style={{ fontSize: '17px' }}>{item.icon}</span>
                {selected && <span>{item.label}</span>}
              </button>
            );
          })}
        </nav>

        {/* MODAL PERFIL Y APARIENCIA (Claro / Oscuro / Alto Contraste) */}
        {showProfileModal && (
          <div
            onClick={() => setShowProfileModal(false)}
            style={{
              position: 'fixed',
              inset: 0,
              backgroundColor: 'rgba(0,0,0,0.65)',
              display: 'flex',
              alignItems: 'flex-end',
              justifyContent: 'center',
              zIndex: 50,
            }}
          >
            <div
              onClick={(e) => e.stopPropagation()}
              style={{
                width: '100%',
                maxWidth: '430px',
                backgroundColor: p.card,
                borderTopLeftRadius: '28px',
                borderTopRightRadius: '28px',
                border: `1px solid ${p.border}`,
                padding: '22px 20px 28px 20px',
                boxSizing: 'border-box',
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px' }}>
                <h2 style={{ margin: 0, fontSize: '20px', fontWeight: 800 }}>Elige tu perfil</h2>
                <button
                  onClick={() => setShowProfileModal(false)}
                  style={{
                    backgroundColor: p.sand,
                    color: p.ink,
                    border: 'none',
                    borderRadius: '50%',
                    width: '34px',
                    height: '34px',
                    cursor: 'pointer',
                    fontWeight: 700,
                  }}
                >
                  ✕
                </button>
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', marginBottom: '16px' }}>
                {(
                  [
                    { id: 'wheelchair', title: 'Silla de ruedas / Carriola', sub: 'Rutas sin escalones ni pendientes > 6%' },
                    { id: 'low_vision', title: 'Baja visión', sub: 'Guía por voz y alto contraste' },
                    { id: 'clear_reading', title: 'Lectura clara', sub: 'Instrucciones simples paso a paso' },
                  ] as const
                ).map((item) => {
                  const active = profile === item.id;
                  return (
                    <button
                      key={item.id}
                      onClick={() => setProfile(item.id)}
                      style={{
                        textAlign: 'left',
                        padding: '14px',
                        borderRadius: '18px',
                        backgroundColor: active ? p.coralSoft : p.sand,
                        border: `2px solid ${active ? p.coral : p.border}`,
                        color: p.ink,
                        cursor: 'pointer',
                      }}
                    >
                      <div style={{ fontWeight: 700, fontSize: '15px' }}>{item.title}</div>
                      <div style={{ fontSize: '12.5px', color: p.muted, marginTop: '2px' }}>{item.sub}</div>
                    </button>
                  );
                })}
              </div>

              <div style={{ display: 'flex', gap: '10px' }}>
                <button
                  onClick={() => setIsDark(!isDark)}
                  style={{
                    flex: 1,
                    padding: '12px',
                    borderRadius: '20px',
                    backgroundColor: p.sand,
                    border: `1px solid ${p.border}`,
                    color: p.ink,
                    fontWeight: 700,
                    cursor: 'pointer',
                  }}
                >
                  {isDark ? '🌙 Modo Oscuro' : '☀️ Modo Claro'}
                </button>
                <button
                  onClick={() => setHighContrast(!highContrast)}
                  style={{
                    flex: 1,
                    padding: '12px',
                    borderRadius: '20px',
                    backgroundColor: highContrast ? p.coral : p.sand,
                    border: `1px solid ${p.border}`,
                    color: highContrast ? '#FFFFFF' : p.ink,
                    fontWeight: 700,
                    cursor: 'pointer',
                  }}
                >
                  {highContrast ? '✓ Alto Contraste' : 'Alto Contraste'}
                </button>
              </div>
            </div>
          </div>
        )}

        {/* MODAL COPILOTO GEMINI */}
        {showCopilotModal && (
          <div
            onClick={() => setShowCopilotModal(false)}
            style={{
              position: 'fixed',
              inset: 0,
              backgroundColor: 'rgba(0,0,0,0.65)',
              display: 'flex',
              alignItems: 'flex-end',
              justifyContent: 'center',
              zIndex: 50,
            }}
          >
            <div
              onClick={(e) => e.stopPropagation()}
              style={{
                width: '100%',
                maxWidth: '430px',
                backgroundColor: p.card,
                borderTopLeftRadius: '28px',
                borderTopRightRadius: '28px',
                border: `1px solid ${p.border}`,
                padding: '22px 20px 28px 20px',
                boxSizing: 'border-box',
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
                <h2 style={{ margin: 0, fontSize: '19px', fontWeight: 800 }}>✨ Copiloto VíaLibre · Gemini</h2>
                <button
                  onClick={() => setShowCopilotModal(false)}
                  style={{
                    backgroundColor: p.sand,
                    color: p.ink,
                    border: 'none',
                    borderRadius: '50%',
                    width: '34px',
                    height: '34px',
                    cursor: 'pointer',
                    fontWeight: 700,
                  }}
                >
                  ✕
                </button>
              </div>
              <textarea
                rows={3}
                value={copilotPrompt}
                onChange={(e) => setCopilotPrompt(e.target.value)}
                placeholder="Ej. ¿Cómo tomo el Metrobús sin escalones desde aquí?"
                style={{
                  width: '100%',
                  padding: '12px',
                  borderRadius: '16px',
                  border: `1px solid ${p.border}`,
                  backgroundColor: p.sand,
                  color: p.ink,
                  fontSize: '14px',
                  boxSizing: 'border-box',
                  marginBottom: '10px',
                }}
              />
              <button
                onClick={handleAskCopilot}
                disabled={loadingCopilot}
                style={{
                  width: '100%',
                  padding: '13px',
                  borderRadius: '24px',
                  backgroundColor: p.coral,
                  color: '#FFFFFF',
                  border: 'none',
                  fontWeight: 700,
                  cursor: 'pointer',
                }}
              >
                {loadingCopilot ? 'Consultando a Gemini...' : 'Preguntar ahora'}
              </button>
              {copilotAnswer && (
                <div
                  style={{
                    marginTop: '12px',
                    padding: '12px',
                    borderRadius: '16px',
                    backgroundColor: p.sand,
                    fontSize: '13.5px',
                    lineHeight: 1.5,
                    whiteSpace: 'pre-line',
                  }}
                >
                  {copilotAnswer}
                </div>
              )}
            </div>
          </div>
        )}

        {/* MODAL GUÍA PRIMERA VEZ */}
        {showFirstTimerModal && (
          <div
            onClick={() => setShowFirstTimerModal(false)}
            style={{
              position: 'fixed',
              inset: 0,
              backgroundColor: 'rgba(0,0,0,0.65)',
              display: 'flex',
              alignItems: 'flex-end',
              justifyContent: 'center',
              zIndex: 50,
            }}
          >
            <div
              onClick={(e) => e.stopPropagation()}
              style={{
                width: '100%',
                maxWidth: '430px',
                backgroundColor: p.card,
                borderTopLeftRadius: '28px',
                borderTopRightRadius: '28px',
                border: `1px solid ${p.border}`,
                padding: '22px 20px 28px 20px',
                boxSizing: 'border-box',
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
                <h2 style={{ margin: 0, fontSize: '19px', fontWeight: 800 }}>🧭 Guía rápida · Primera vez</h2>
                <button
                  onClick={() => setShowFirstTimerModal(false)}
                  style={{
                    backgroundColor: p.sand,
                    color: p.ink,
                    border: 'none',
                    borderRadius: '50%',
                    width: '34px',
                    height: '34px',
                    cursor: 'pointer',
                    fontWeight: 700,
                  }}
                >
                  ✕
                </button>
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', fontSize: '13.5px', lineHeight: 1.45 }}>
                <div style={{ backgroundColor: p.sand, padding: '12px', borderRadius: '16px' }}>
                  <strong>1. Identifica la entrada accesible:</strong> Revisa la dirección final y pide al personal abrir puerta amplia o elevador.
                </div>
                <div style={{ backgroundColor: p.sand, padding: '12px', borderRadius: '16px' }}>
                  <strong>2. Valida con calma:</strong> Acerca tu tarjeta al lector verde hasta escuchar el sonido de confirmación.
                </div>
                <div style={{ backgroundColor: p.sand, padding: '12px', borderRadius: '16px' }}>
                  <strong>3. Pide bajada con anticipación:</strong> Usa lugares reservados cerca de la puerta y presiona el timbre dos cuadras antes.
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
