'use client';

import React, { useState, useEffect } from 'react';

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

export default function MobileAppPage() {
  const [activeTab, setActiveTab] = useState<'perfil' | 'ruta' | 'reporte' | 'avisos'>('perfil');
  const [profile, setProfile] = useState<ProfileType>('wheelchair');
  const [destination, setDestination] = useState('Hospital General (Acceso sin escalones)');
  const [routeResult, setRouteResult] = useState<any>(null);
  const [loadingRoute, setLoadingRoute] = useState(false);
  const [barriers, setBarriers] = useState<Barrier[]>([]);

  // Estado para reporte
  const [reportType, setReportType] = useState<'photo' | 'audio'>('photo');
  const [reportPreview, setReportPreview] = useState<string | null>(null);
  const [reporting, setReporting] = useState(false);
  const [reportResult, setReportResult] = useState<any>(null);

  // Estado para avisos
  const [noticeInput, setNoticeInput] = useState('');
  const [translatingNotice, setTranslatingNotice] = useState(false);
  const [noticeResult, setNoticeResult] = useState<any>(null);
  const [speaking, setSpeaking] = useState(false);

  // Cargar barreras cercanas iniciales
  useEffect(() => {
    fetch('/api/barriers/nearby?lat=19.4326&lng=-99.1332&radius=1500')
      .then((res) => res.json())
      .then((data) => {
        if (data.barriers) setBarriers(data.barriers);
      })
      .catch((e) => console.error(e));
  }, []);

  // Calcular ruta accesible
  const handleCalculateRoute = async () => {
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
      setRouteResult(data.route);
    } catch (e) {
      console.error(e);
    } finally {
      setLoadingRoute(false);
    }
  };

  // Enviar reporte a Gemini
  const handleSimulateReport = async () => {
    setReporting(true);
    setReportResult(null);
    try {
      // Imagen 1x1 png en base64 de muestra para activar el endpoint de visión
      const demoBase64 =
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
      setReportResult(data.data);
    } catch (e) {
      console.error(e);
    } finally {
      setReporting(false);
    }
  };

  // Traducir aviso a Lenguaje Claro
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

  // Lectura por voz en español accesible
  const handleSpeakText = (text: string) => {
    if ('speechSynthesis' in window) {
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

  return (
    <div
      style={{
        maxWidth: '430px',
        margin: '0 auto',
        minHeight: '100vh',
        backgroundColor: '#0A192F',
        color: '#FFFFFF',
        display: 'flex',
        flexDirection: 'column',
        boxShadow: '0 0 40px rgba(0,0,0,0.6)',
      }}
    >
      {/* Barra superior accesible */}
      <header
        style={{
          padding: '16px 20px',
          backgroundColor: '#071224',
          borderBottom: '2px solid #FFB300',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <div
            style={{
              width: '32px',
              height: '32px',
              backgroundColor: '#FFB300',
              borderRadius: '8px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: '#0A192F',
              fontWeight: '900',
              fontSize: '18px',
            }}
          >
            V
          </div>
          <span style={{ fontSize: '18px', fontWeight: 'bold', letterSpacing: '0.5px' }}>
            VíaLibre
          </span>
        </div>
        <span
          style={{
            fontSize: '11px',
            backgroundColor: '#1E3A8A',
            color: '#93C5FD',
            padding: '4px 10px',
            borderRadius: '12px',
            fontWeight: '600',
          }}
        >
          {profile === 'wheelchair'
            ? '♿ Silla de ruedas'
            : profile === 'low_vision'
            ? '👁️ Baja visión'
            : '📖 Lectura clara'}
        </span>
      </header>

      {/* Contenido principal scrollable */}
      <main style={{ flex: 1, padding: '20px', overflowY: 'auto' }}>
        {/* PANTALLA 1: PERFIL */}
        {activeTab === 'perfil' && (
          <div>
            <h1 style={{ fontSize: '22px', color: '#FFB300', margin: '0 0 8px 0' }}>
              Elige tu Perfil
            </h1>
            <p style={{ color: '#CBD5E1', fontSize: '14px', marginBottom: '20px', lineHeight: 1.5 }}>
              VíaLibre adapta las rutas, pendientes y avisos a tus necesidades específicas sin pedir contraseñas.
            </p>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              <button
                onClick={() => setProfile('wheelchair')}
                style={{
                  padding: '18px',
                  borderRadius: '12px',
                  backgroundColor: profile === 'wheelchair' ? '#1E3A8A' : '#0F2444',
                  border: profile === 'wheelchair' ? '2px solid #FFB300' : '1px solid #1E293B',
                  color: '#FFFFFF',
                  textAlign: 'left',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '16px',
                }}
              >
                <span style={{ fontSize: '32px' }}>♿</span>
                <div>
                  <div style={{ fontWeight: 'bold', fontSize: '16px' }}>Silla de ruedas / Carriola</div>
                  <div style={{ fontSize: '13px', color: '#94A3B8', marginTop: '4px' }}>
                    Evita banquetas rotas, escalones sin rampa y pendientes &gt; 6%
                  </div>
                </div>
              </button>

              <button
                onClick={() => setProfile('low_vision')}
                style={{
                  padding: '18px',
                  borderRadius: '12px',
                  backgroundColor: profile === 'low_vision' ? '#1E3A8A' : '#0F2444',
                  border: profile === 'low_vision' ? '2px solid #FFB300' : '1px solid #1E293B',
                  color: '#FFFFFF',
                  textAlign: 'left',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '16px',
                }}
              >
                <span style={{ fontSize: '32px' }}>👁️</span>
                <div>
                  <div style={{ fontWeight: 'bold', fontSize: '16px' }}>Baja visión</div>
                  <div style={{ fontSize: '13px', color: '#94A3B8', marginTop: '4px' }}>
                    Prioriza alto contraste, guías podotáctiles y lectura auditiva de pasos
                  </div>
                </div>
              </button>

              <button
                onClick={() => setProfile('clear_reading')}
                style={{
                  padding: '18px',
                  borderRadius: '12px',
                  backgroundColor: profile === 'clear_reading' ? '#1E3A8A' : '#0F2444',
                  border: profile === 'clear_reading' ? '2px solid #FFB300' : '1px solid #1E293B',
                  color: '#FFFFFF',
                  textAlign: 'left',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '16px',
                }}
              >
                <span style={{ fontSize: '32px' }}>📖</span>
                <div>
                  <div style={{ fontWeight: 'bold', fontSize: '16px' }}>Lectura clara / Neurodivergencia</div>
                  <div style={{ fontSize: '13px', color: '#94A3B8', marginTop: '4px' }}>
                    Instrucciones concisas paso a paso, sin saturación visual
                  </div>
                </div>
              </button>
            </div>

            <div style={{ marginTop: '28px' }}>
              <button
                onClick={() => setActiveTab('ruta')}
                style={{
                  width: '100%',
                  padding: '16px',
                  borderRadius: '12px',
                  backgroundColor: '#FFB300',
                  color: '#0A192F',
                  fontWeight: 'bold',
                  fontSize: '16px',
                  border: 'none',
                  cursor: 'pointer',
                }}
              >
                Continuar a Rutas Accesibles →
              </button>
            </div>
          </div>
        )}

        {/* PANTALLA 2: RUTA Y MAPA */}
        {activeTab === 'ruta' && (
          <div>
            <h1 style={{ fontSize: '20px', color: '#FFB300', margin: '0 0 12px 0' }}>
              Ruta Peatonal Adaptada
            </h1>

            <div style={{ marginBottom: '16px' }}>
              <label style={{ display: 'block', fontSize: '13px', color: '#94A3B8', marginBottom: '6px' }}>
                Destino accesible:
              </label>
              <input
                type="text"
                value={destination}
                onChange={(e) => setDestination(e.target.value)}
                style={{
                  width: '100%',
                  padding: '12px 14px',
                  backgroundColor: '#0F2444',
                  border: '1px solid #1E3A8A',
                  borderRadius: '8px',
                  color: '#FFFFFF',
                  fontSize: '14px',
                  boxSizing: 'border-box',
                }}
              />
              <button
                onClick={handleCalculateRoute}
                disabled={loadingRoute}
                style={{
                  width: '100%',
                  marginTop: '10px',
                  padding: '12px',
                  backgroundColor: '#2563EB',
                  color: '#FFFFFF',
                  border: 'none',
                  borderRadius: '8px',
                  fontWeight: 'bold',
                  cursor: 'pointer',
                }}
              >
                {loadingRoute ? 'Calculando ruta con Google Maps...' : '🔍 Calcular Ruta Accesible'}
              </button>
            </div>

            {/* Simulación visual de mapa de alto contraste */}
            <div
              style={{
                height: '180px',
                backgroundColor: '#08172E',
                borderRadius: '12px',
                border: '1px solid #1E3A8A',
                position: 'relative',
                display: 'flex',
                flexDirection: 'column',
                justifyContent: 'center',
                alignItems: 'center',
                marginBottom: '16px',
                padding: '16px',
                boxSizing: 'border-box',
              }}
            >
              <div style={{ fontSize: '13px', color: '#38BDF8', fontWeight: 'bold' }}>
                📍 Mapa Interactivo Peatonal
              </div>
              <div style={{ fontSize: '12px', color: '#94A3B8', marginTop: '6px', textAlign: 'center' }}>
                Mostrando {barriers.length} barreras reportadas en el radio activo
              </div>
              <div style={{ display: 'flex', gap: '8px', marginTop: '12px' }}>
                <span style={{ fontSize: '11px', backgroundColor: '#DC2626', padding: '4px 8px', borderRadius: '4px' }}>
                  ▲ 1 Bloqueo crítico
                </span>
                <span style={{ fontSize: '11px', backgroundColor: '#D97706', padding: '4px 8px', borderRadius: '4px' }}>
                  ■ 1 Rampa tapada
                </span>
              </div>
            </div>

            {routeResult && (
              <div style={{ backgroundColor: '#0F2444', padding: '16px', borderRadius: '12px', border: '1px solid #10B981' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span style={{ fontWeight: 'bold', color: '#10B981', fontSize: '16px' }}>
                    Ruta Sugerida · {routeResult.distanceMeters} m ({Math.round(routeResult.durationSeconds / 60)} min)
                  </span>
                  <button
                    onClick={() =>
                      handleSpeakText(
                        routeResult.steps.map((s: any) => s.instruction).join('. ')
                      )
                    }
                    style={{
                      backgroundColor: '#FFB300',
                      color: '#0A192F',
                      border: 'none',
                      borderRadius: '6px',
                      padding: '6px 10px',
                      fontWeight: 'bold',
                      fontSize: '12px',
                      cursor: 'pointer',
                    }}
                  >
                    🔊 {speaking ? 'Reproduciendo...' : 'Escuchar'}
                  </button>
                </div>

                <div style={{ marginTop: '12px', display: 'flex', flexDirection: 'column', gap: '8px' }}>
                  {routeResult.steps.map((step: any, index: number) => (
                    <div
                      key={index}
                      style={{
                        padding: '10px',
                        backgroundColor: '#0A192F',
                        borderRadius: '6px',
                        fontSize: '13px',
                        borderLeft: '3px solid #38BDF8',
                      }}
                    >
                      <strong>Paso {index + 1}:</strong> {step.instruction}
                      {step.slopePercentage && (
                        <span style={{ display: 'block', fontSize: '11px', color: '#FBBF24', marginTop: '2px' }}>
                          Pendiente leve: {step.slopePercentage}% (Accesible)
                        </span>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}

        {/* PANTALLA 3: REPORTE EN UN TOQUE */}
        {activeTab === 'reporte' && (
          <div>
            <h1 style={{ fontSize: '20px', color: '#FFB300', margin: '0 0 8px 0' }}>
              Reportar Obstáculo
            </h1>
            <p style={{ color: '#CBD5E1', fontSize: '13px', marginBottom: '16px' }}>
              Toma una foto o graba un audio. Gemini clasificará el obstáculo y protegerá tu privacidad eliminando datos EXIF.
            </p>

            <div style={{ display: 'flex', gap: '10px', marginBottom: '16px' }}>
              <button
                onClick={() => setReportType('photo')}
                style={{
                  flex: 1,
                  padding: '12px',
                  borderRadius: '8px',
                  backgroundColor: reportType === 'photo' ? '#2563EB' : '#0F2444',
                  color: '#FFFFFF',
                  border: 'none',
                  fontWeight: 'bold',
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
                  borderRadius: '8px',
                  backgroundColor: reportType === 'audio' ? '#2563EB' : '#0F2444',
                  color: '#FFFFFF',
                  border: 'none',
                  fontWeight: 'bold',
                  cursor: 'pointer',
                }}
              >
                🎙️ Nota de voz
              </button>
            </div>

            <div
              style={{
                height: '160px',
                border: '2px dashed #1E3A8A',
                borderRadius: '12px',
                backgroundColor: '#071224',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                marginBottom: '16px',
                padding: '16px',
                textAlign: 'center',
              }}
            >
              <span style={{ fontSize: '36px', marginBottom: '8px' }}>
                {reportType === 'photo' ? '📸' : '🎙️'}
              </span>
              <span style={{ fontSize: '13px', color: '#94A3B8' }}>
                {reportType === 'photo'
                  ? 'Captura una foto de la banqueta o rampa'
                  : 'Graba un audio breve describiendo el obstáculo'}
              </span>
            </div>

            <button
              onClick={handleSimulateReport}
              disabled={reporting}
              style={{
                width: '100%',
                padding: '14px',
                backgroundColor: '#10B981',
                color: '#0A192F',
                fontWeight: 'bold',
                fontSize: '15px',
                border: 'none',
                borderRadius: '8px',
                cursor: 'pointer',
              }}
            >
              {reporting ? 'Gemini analizando y deduplicando...' : '🚀 Analizar y Publicar en un Toque'}
            </button>

            {reportResult && (
              <div
                style={{
                  marginTop: '16px',
                  padding: '14px',
                  backgroundColor: '#0F2444',
                  borderRadius: '10px',
                  borderLeft: '4px solid #10B981',
                }}
              >
                <div style={{ fontWeight: 'bold', color: '#34D399', fontSize: '15px' }}>
                  ✓ Reporte Procesado por Gemini
                </div>
                <div style={{ fontSize: '13px', marginTop: '6px', color: '#FFFFFF' }}>
                  <strong>Título:</strong> {reportResult.title}
                </div>
                <div style={{ fontSize: '12px', color: '#CBD5E1', marginTop: '4px' }}>
                  <strong>Categoría Open311:</strong> {reportResult.category} · Severidad: {reportResult.severity}
                </div>
                <div style={{ fontSize: '12px', color: '#FBBF24', marginTop: '6px' }}>
                  {reportResult.isDuplicate
                    ? '⚠️ Coincidencia detectada en 25m: Confirmación agregada (+1)'
                    : '📍 Nuevo obstáculo publicado en el mapa'}
                </div>
              </div>
            )}
          </div>
        )}

        {/* PANTALLA 4: AVISOS EN LENGUAJE CLARO */}
        {activeTab === 'avisos' && (
          <div>
            <h1 style={{ fontSize: '20px', color: '#FFB300', margin: '0 0 8px 0' }}>
              Avisos en Lenguaje Claro
            </h1>
            <p style={{ color: '#CBD5E1', fontSize: '13px', marginBottom: '16px' }}>
              Norma ISO 24495-1: Traduce cualquier comunicado técnico municipal a 3 bloques claros y directos.
            </p>

            <textarea
              rows={4}
              value={noticeInput}
              onChange={(e) => setNoticeInput(e.target.value)}
              placeholder="Pega aquí el texto del comunicado municipal o aviso de obras..."
              style={{
                width: '100%',
                padding: '12px',
                backgroundColor: '#0F2444',
                border: '1px solid #1E3A8A',
                borderRadius: '8px',
                color: '#FFFFFF',
                fontSize: '13px',
                boxSizing: 'border-box',
                marginBottom: '10px',
              }}
            />

            <div style={{ display: 'flex', gap: '8px', marginBottom: '16px' }}>
              <button
                onClick={() =>
                  setNoticeInput(
                    'Se informa a la ciudadanía que debido a trabajos de rehabilitación de drenaje en el cuadrante oriente, la circulación peatonal sobre Calzada Juárez quedará suspendida temporalmente debiendo transitar por los desvíos habilitados en Calle Morelos.'
                  )
                }
                style={{
                  fontSize: '11px',
                  padding: '6px 10px',
                  backgroundColor: '#1E293B',
                  color: '#94A3B8',
                  border: 'none',
                  borderRadius: '6px',
                  cursor: 'pointer',
                }}
              >
                Cargar aviso de muestra
              </button>
            </div>

            <button
              onClick={handleTranslateNotice}
              disabled={translatingNotice}
              style={{
                width: '100%',
                padding: '14px',
                backgroundColor: '#FFB300',
                color: '#0A192F',
                fontWeight: 'bold',
                fontSize: '15px',
                border: 'none',
                borderRadius: '8px',
                cursor: 'pointer',
              }}
            >
              {translatingNotice ? 'Gemini traduciendo a Lenguaje Claro...' : '✨ Traducir a Lenguaje Claro'}
            </button>

            {noticeResult && (
              <div style={{ marginTop: '16px', display: 'flex', flexDirection: 'column', gap: '10px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span style={{ fontSize: '13px', color: '#93C5FD', fontWeight: 'bold' }}>
                    Resumen en 3 Bloques Accionables:
                  </span>
                  <button
                    onClick={() =>
                      handleSpeakText(
                        `Qué pasó: ${noticeResult.quePaso}. A quién afecta: ${noticeResult.aQuienAfecta}. Qué hacer hoy: ${noticeResult.queHacerHoy}`
                      )
                    }
                    style={{
                      backgroundColor: '#3B82F6',
                      color: '#FFFFFF',
                      border: 'none',
                      borderRadius: '6px',
                      padding: '6px 10px',
                      fontWeight: 'bold',
                      fontSize: '12px',
                      cursor: 'pointer',
                    }}
                  >
                    🔊 {speaking ? 'Leyendo...' : 'Escuchar audio'}
                  </button>
                </div>

                <div style={{ backgroundColor: '#0F2444', padding: '12px', borderRadius: '8px', borderLeft: '4px solid #3B82F6' }}>
                  <div style={{ fontSize: '11px', color: '#93C5FD', fontWeight: 'bold' }}>1. ¿QUÉ PASÓ?</div>
                  <div style={{ fontSize: '13px', marginTop: '4px', color: '#FFFFFF' }}>
                    {noticeResult.quePaso}
                  </div>
                </div>

                <div style={{ backgroundColor: '#0F2444', padding: '12px', borderRadius: '8px', borderLeft: '4px solid #F59E0B' }}>
                  <div style={{ fontSize: '11px', color: '#FCD34D', fontWeight: 'bold' }}>2. ¿A QUIÉN AFECTA?</div>
                  <div style={{ fontSize: '13px', marginTop: '4px', color: '#FFFFFF' }}>
                    {noticeResult.aQuienAfecta}
                  </div>
                </div>

                <div style={{ backgroundColor: '#0F2444', padding: '12px', borderRadius: '8px', borderLeft: '4px solid #10B981' }}>
                  <div style={{ fontSize: '11px', color: '#6EE7B7', fontWeight: 'bold' }}>3. ¿QUÉ HACER HOY?</div>
                  <div style={{ fontSize: '13px', marginTop: '4px', color: '#FFFFFF' }}>
                    {noticeResult.queHacerHoy}
                  </div>
                </div>
              </div>
            )}
          </div>
        )}
      </main>

      {/* Barra de navegación inferior móvil (Touch target 48x48) */}
      <nav
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(4, 1fr)',
          backgroundColor: '#071224',
          borderTop: '1px solid #1E293B',
          minHeight: '64px',
        }}
      >
        <button
          onClick={() => setActiveTab('perfil')}
          style={{
            backgroundColor: 'transparent',
            border: 'none',
            color: activeTab === 'perfil' ? '#FFB300' : '#64748B',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            cursor: 'pointer',
            padding: '8px',
          }}
        >
          <span style={{ fontSize: '20px' }}>♿</span>
          <span style={{ fontSize: '11px', marginTop: '2px', fontWeight: activeTab === 'perfil' ? 'bold' : 'normal' }}>
            Perfil
          </span>
        </button>

        <button
          onClick={() => setActiveTab('ruta')}
          style={{
            backgroundColor: 'transparent',
            border: 'none',
            color: activeTab === 'ruta' ? '#FFB300' : '#64748B',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            cursor: 'pointer',
            padding: '8px',
          }}
        >
          <span style={{ fontSize: '20px' }}>🗺️</span>
          <span style={{ fontSize: '11px', marginTop: '2px', fontWeight: activeTab === 'ruta' ? 'bold' : 'normal' }}>
            Ruta
          </span>
        </button>

        <button
          onClick={() => setActiveTab('reporte')}
          style={{
            backgroundColor: 'transparent',
            border: 'none',
            color: activeTab === 'reporte' ? '#FFB300' : '#64748B',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            cursor: 'pointer',
            padding: '8px',
          }}
        >
          <span style={{ fontSize: '20px' }}>📢</span>
          <span style={{ fontSize: '11px', marginTop: '2px', fontWeight: activeTab === 'reporte' ? 'bold' : 'normal' }}>
            Reportar
          </span>
        </button>

        <button
          onClick={() => setActiveTab('avisos')}
          style={{
            backgroundColor: 'transparent',
            border: 'none',
            color: activeTab === 'avisos' ? '#FFB300' : '#64748B',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            cursor: 'pointer',
            padding: '8px',
          }}
        >
          <span style={{ fontSize: '20px' }}>📖</span>
          <span style={{ fontSize: '11px', marginTop: '2px', fontWeight: activeTab === 'avisos' ? 'bold' : 'normal' }}>
            Avisos
          </span>
        </button>
      </nav>
    </div>
  );
}
