export default function HomePage() {
  const endpoints = [
    {
      method: 'GET /api/health',
      badge: 'Público',
      accent: '#86EFAC',
      desc: 'Monitoreo de salud del servicio e integraciones activas (Supabase, Gemini, Google Maps).',
    },
    {
      method: 'POST /api/routes/accessible',
      badge: 'Activo',
      accent: '#EF4756',
      desc: 'Cálculo de rutas peatonales adaptadas por perfil considerando pendientes y barreras.',
    },
    {
      method: 'POST /api/barriers/report',
      badge: 'Bearer JWT / Demo',
      accent: '#DCE0FF',
      desc: 'Reporte ciudadano con visión/audio de Gemini, clasificación Open311 y deduplicación en 25m.',
    },
    {
      method: 'GET /api/barriers/nearby',
      badge: 'Público',
      accent: '#86EFAC',
      desc: 'Consulta geoespacial PostGIS de obstáculos cercanos activos.',
    },
    {
      method: 'POST /api/notices/simplify',
      badge: 'Bearer JWT / Demo',
      accent: '#FDE68A',
      desc: 'Traducción de comunicados oficiales a Lenguaje Claro (ISO 24495-1) en 3 bloques.',
    },
  ];

  return (
    <main style={{ maxWidth: '860px', margin: '0 auto', padding: '44px 20px' }}>
      <header
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          gap: '16px',
          flexWrap: 'wrap',
          borderBottom: '1px solid #363640',
          paddingBottom: '24px',
          marginBottom: '28px',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
          <img
            src="/logo_dark.png"
            alt="Logo VíaLibre"
            style={{
              width: '52px',
              height: '52px',
              borderRadius: '14px',
              objectFit: 'cover',
              border: '1px solid #363640',
            }}
          />
          <div>
            <div style={{ fontSize: '12px', color: '#B8B8C4', fontWeight: 600 }}>
              Reto 2 · Ciudad para todas y todos · ODS 10 y 11
            </div>
            <h1 style={{ margin: '2px 0 0 0', fontSize: '26px', color: '#FAF8F5', fontWeight: 800 }}>
              VíaLibre — Calma Urbana & BFF
            </h1>
          </div>
        </div>

        <a
          href="/app"
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '8px',
            backgroundColor: '#EF4756',
            color: '#FFFFFF',
            padding: '13px 22px',
            borderRadius: '28px',
            textDecoration: 'none',
            fontWeight: 700,
            fontSize: '15px',
          }}
        >
          Abrir App VíaLibre →
        </a>
      </header>

      <section
        style={{
          backgroundColor: '#1D1D1F',
          borderRadius: '24px',
          padding: '24px',
          marginBottom: '28px',
          border: '1px solid #363640',
        }}
      >
        <h2 style={{ margin: '0 0 10px 0', fontSize: '18px', color: '#FAF8F5', fontWeight: 700 }}>
          Portal Web y Gateway BFF en línea
        </h2>
        <p style={{ margin: 0, color: '#B8B8C4', lineHeight: 1.6, fontSize: '14px' }}>
          Accede directamente a la versión web móvil de <strong style={{ color: '#FAF8F5' }}>VíaLibre</strong> con el
          sistema de diseño <strong style={{ color: '#EF4756' }}>Calma Urbana</strong> o consulta el estado de los
          endpoints conectados a Supabase, Google Gemini y Google Maps Platform.
        </p>

        <div style={{ marginTop: '20px', display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
          <a
            href="/app"
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '8px',
              backgroundColor: '#FAF8F5',
              color: '#18181B',
              padding: '12px 20px',
              borderRadius: '24px',
              textDecoration: 'none',
              fontWeight: 700,
              fontSize: '14px',
            }}
          >
            ✨ Ir a la App Móvil Web (/app)
          </a>
          <a
            href="/api/health"
            target="_blank"
            rel="noreferrer"
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '8px',
              backgroundColor: '#26262C',
              color: '#FAF8F5',
              padding: '12px 20px',
              borderRadius: '24px',
              textDecoration: 'none',
              fontWeight: 600,
              fontSize: '14px',
              border: '1px solid #363640',
            }}
          >
            🩺 Probar /api/health
          </a>
        </div>
      </section>

      <section>
        <h2 style={{ fontSize: '19px', color: '#FAF8F5', marginBottom: '14px', fontWeight: 700 }}>
          Endpoints Activos de la API
        </h2>
        <div style={{ display: 'grid', gap: '12px' }}>
          {endpoints.map((ep) => (
            <div
              key={ep.method}
              style={{
                backgroundColor: '#1D1D1F',
                padding: '16px 18px',
                borderRadius: '18px',
                border: '1px solid #363640',
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '12px' }}>
                <span style={{ fontWeight: 700, color: ep.accent, fontFamily: 'monospace', fontSize: '14px' }}>
                  {ep.method}
                </span>
                <span
                  style={{
                    fontSize: '11px',
                    color: '#B8B8C4',
                    backgroundColor: '#26262C',
                    padding: '4px 10px',
                    borderRadius: '12px',
                    border: '1px solid #363640',
                  }}
                >
                  {ep.badge}
                </span>
              </div>
              <p style={{ margin: '8px 0 0 0', fontSize: '13px', color: '#B8B8C4', lineHeight: 1.5 }}>{ep.desc}</p>
            </div>
          ))}
        </div>
      </section>
    </main>
  );
}
