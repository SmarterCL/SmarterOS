import type { Metadata } from 'next'
import './globals.css'
import { ClerkProvider } from '@clerk/nextjs'
import { esCL } from '@clerk/localizations'

export const metadata: Metadata = {
  title: 'v0 App',
  description: 'Created with v0',
  generator: 'v0.dev',
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <ClerkProvider localization={esCL} appearance={{ variables: { colorPrimary: '#0070f3' } }}>
      <html lang="es-CL">
        <body>{children}</body>
      </html>
    </ClerkProvider>
  )
}
