import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'VíaLibre — Movilidad peatonal y transporte accesible',
  description:
    'Navegación peatonal accesible, reporte ciudadano de barreras y avisos en Lenguaje Claro (Reto 2: Ciudad para todas y todos — ODS 10 y 11)',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="es">
      <body
        style={{
          margin: 0,
          fontFamily: 'Inter, system-ui, -apple-system, BlinkMacSystemFont, sans-serif',
          backgroundColor: '#141416',
          color: '#FAF8F5',
          minHeight: '100vh',
        }}
      >
        {children}
      </body>
    </html>
  );
}
