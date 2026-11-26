import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'VíaLibre — BFF & API Gateway',
  description: 'Backend for Frontend para VíaLibre (Reto 2: Ciudad para todas y todos — ODS 10 y 11)',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="es">
      <body style={{
        margin: 0,
        fontFamily: 'Inter, system-ui, -apple-system, sans-serif',
        backgroundColor: '#0A192F',
        color: '#F8FAFC',
        minHeight: '100vh',
      }}>
        {children}
      </body>
    </html>
  );
}
