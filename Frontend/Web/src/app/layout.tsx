import type { Metadata, Viewport } from "next";
import { AuthProvider } from "@/lib/AuthContext";
import "./globals.css";

export const metadata: Metadata = {
  title: "ArgusX Web Portal - Guardentic Ride Safety",
  description: "Tesla-style fleet dashboard, real-time rider tracking, and relational safety analytics for ArgusX.",
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link href="https://fonts.googleapis.com/css2?family=Share+Tech+Mono&family=Zen+Dots&display=swap" rel="stylesheet" />
      </head>
      <body className="bg-[#131314] text-[#e5e2e3] min-h-screen relative flex flex-col antialiased">
        {/* Background Grid Pattern */}
        <div className="fixed inset-0 grid-bg pointer-events-none z-0" />

        {/* Top Glow Ambient Lighting */}
        <div className="fixed top-0 left-1/4 right-1/4 h-96 pointer-events-none z-0" style={{background: 'radial-gradient(ellipse at center, rgba(142, 45, 226, 0.08) 0%, transparent 70%)'}} />
        <div className="fixed bottom-0 right-10 w-96 h-96 pointer-events-none z-0" style={{background: 'radial-gradient(ellipse at center, rgba(0, 229, 255, 0.04) 0%, transparent 70%)'}} />

        <AuthProvider>
          <div className="relative z-10 flex flex-col flex-1">
            {children}
          </div>
        </AuthProvider>
      </body>
    </html>
  );
}
