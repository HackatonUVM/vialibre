import type { Metadata, Viewport } from 'next';

export const viewport: Viewport = {
  themeColor: '#141416',
  width: 'device-width',
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
};

export const metadata: Metadata = {
  title: 'VíaLibre — Movilidad peatonal y transporte accesible',
  description:
    'Navegación peatonal accesible, reporte ciudadano de barreras y avisos en Lenguaje Claro (Reto 2: Ciudad para todas y todos — ODS 10 y 11)',
  manifest: '/manifest.webmanifest',
  appleWebApp: {
    capable: true,
    statusBarStyle: 'black-translucent',
    title: 'VíaLibre',
  },
  icons: {
    icon: '/logo_dark.png',
    apple: '/logo_dark.png',
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="es">
      <head>
        <link rel="manifest" href="/manifest.webmanifest" />
        <link rel="apple-touch-icon" href="/logo_dark.png" />
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
      </head>
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
