export default function HomePage() {
  return (
    <main style={{ maxWidth: '850px', margin: '0 auto', padding: '48px 24px' }}>
      <header style={{ borderBottom: '1px solid #1E293B', paddingBottom: '24px', marginBottom: '32px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div style={{
            width: '48px',
            height: '48px',
            borderRadius: '12px',
            backgroundColor: '#FFB300',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: '#0A192F',
            fontWeight: 'bold',
            fontSize: '24px'
          }}>
            V
          </div>
          <div>
            <h1 style={{ margin: 0, fontSize: '28px', color: '#FFFFFF' }}>VíaLibre — BFF & API Gateway</h1>
            <p style={{ margin: '4px 0 0 0', color: '#94A3B8', fontSize: '15px' }}>
              Reto 2: Ciudad para todas y todos · ODS 10 (10.2) y ODS 11 (11.2, 11.7)
            </p>
          </div>
        </div>
      </header>

      <section style={{ backgroundColor: '#0F2444', borderRadius: '12px', padding: '24px', marginBottom: '28px', border: '1px solid #1E3A8A' }}>
        <h2 style={{ margin: '0 0 12px 0', fontSize: '18px', color: '#FFB300' }}>Estado del Servicio</h2>
        <p style={{ margin: 0, color: '#E2E8F0', lineHeight: 1.6 }}>
          Este servicio opera como la capa segura <strong>BFF (Backend for Frontend)</strong> en Next.js App Router para Vercel, protegiendo las credenciales de <strong>Google Gemini (@google/genai)</strong>, <strong>Google Maps Platform</strong> y orquestando la deduplicación espacial en <strong>Supabase (PostGIS + pgvector)</strong>.
        </p>
      </section>

      <section>
        <h2 style={{ fontSize: '20px', color: '#FFFFFF', marginBottom: '16px' }}>Endpoints Activos de la API</h2>
        
        <div style={{ display: 'grid', gap: '12px' }}>
          <div style={{ backgroundColor: '#0F2444', padding: '16px', borderRadius: '8px', borderLeft: '4px solid #10B981' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontWeight: 'bold', color: '#10B981', fontFamily: 'monospace' }}>GET /api/health</span>
              <span style={{ fontSize: '12px', color: '#94A3B8' }}>Público</span>
            </div>
            <p style={{ margin: '6px 0 0 0', fontSize: '14px', color: '#CBD5E1' }}>Monitoreo de estado de salud del servicio e integraciones activas.</p>
          </div>

          <div style={{ backgroundColor: '#0F2444', padding: '16px', borderRadius: '8px', borderLeft: '4px solid #3B82F6' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontWeight: 'bold', color: '#60A5FA', fontFamily: 'monospace' }}>POST /api/barriers/report</span>
              <span style={{ fontSize: '12px', color: '#94A3B8' }}>Bearer JWT</span>
            </div>
            <p style={{ margin: '6px 0 0 0', fontSize: '14px', color: '#CBD5E1' }}>
              Reporte ciudadano con visión/audio de Gemini, clasificación Open311 y deduplicación atómica en 25m.
            </p>
          </div>

          <div style={{ backgroundColor: '#0F2444', padding: '16px', borderRadius: '8px', borderLeft: '4px solid #3B82F6' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontWeight: 'bold', color: '#60A5FA', fontFamily: 'monospace' }}>GET /api/barriers/nearby</span>
              <span style={{ fontSize: '12px', color: '#94A3B8' }}>Público</span>
            </div>
            <p style={{ margin: '6px 0 0 0', fontSize: '14px', color: '#CBD5E1' }}>
              Consulta geoespacial de barreras activas cercanas mediante coordenadas y radio en metros.
            </p>
          </div>

          <div style={{ backgroundColor: '#0F2444', padding: '16px', borderRadius: '8px', borderLeft: '4px solid #F59E0B' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontWeight: 'bold', color: '#FBBF24', fontFamily: 'monospace' }}>POST /api/routes/accessible</span>
              <span style={{ fontSize: '12px', color: '#94A3B8' }}>Público</span>
            </div>
            <p style={{ margin: '6px 0 0 0', fontSize: '14px', color: '#CBD5E1' }}>
              Enrutamiento peatonal accesible por perfil (silla de ruedas, baja visión, carriola) con pendientes y alertas.
            </p>
          </div>

          <div style={{ backgroundColor: '#0F2444', padding: '16px', borderRadius: '8px', borderLeft: '4px solid #A855F7' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontWeight: 'bold', color: '#C084FC', fontFamily: 'monospace' }}>POST /api/notices/simplify</span>
              <span style={{ fontSize: '12px', color: '#94A3B8' }}>Bearer JWT</span>
            </div>
            <p style={{ margin: '6px 0 0 0', fontSize: '14px', color: '#CBD5E1' }}>
              Traductor de comunicados y avisos públicos a Lenguaje Claro (ISO 24495-1) en 3 bloques accesibles.
            </p>
          </div>

          <div style={{ backgroundColor: '#0F2444', padding: '16px', borderRadius: '8px', borderLeft: '4px solid #64748B' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontWeight: 'bold', color: '#94A3B8', fontFamily: 'monospace' }}>POST /api/storage/signed-url</span>
              <span style={{ fontSize: '12px', color: '#94A3B8' }}>Bearer JWT</span>
            </div>
            <p style={{ margin: '6px 0 0 0', fontSize: '14px', color: '#CBD5E1' }}>
              Generación de URLs firmadas para subida directa de archivos mayores a 2MB a Supabase Storage.
            </p>
          </div>
        </div>
      </section>

      <footer style={{ marginTop: '48px', paddingTop: '16px', borderTop: '1px solid #1E293B', color: '#64748B', fontSize: '13px', textAlign: 'center' }}>
        Grupo Xiuh · UVM Campus Lomas Verdes · Hackatón Nacional de Innovación con IA Aplicada
      </footer>
    </main>
  );
}
