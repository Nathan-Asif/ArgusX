import type { Metadata } from "next";
import { Inter, Outfit } from "next/font/google";
import { AuthProvider } from "@/lib/AuthContext";
import "./globals.css";

const inter = Inter({
  variable: "--font-sans",
  subsets: ["latin"],
});

const outfit = Outfit({
  variable: "--font-title",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "ArgusX Web Portal - Guardentic Ride Safety",
  description: "Tesla-style fleet dashboard, real-time rider tracking, and relational safety analytics for ArgusX.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={`${inter.variable} ${outfit.variable} dark`}>
      <body className="bg-background text-foreground min-h-screen relative font-sans flex flex-col antialiased">
        {/* Background Grid Pattern */}
        <div className="absolute inset-0 grid-bg pointer-events-none z-0" />
        
        {/* Top Glow Ambient Lighting */}
        <div className="absolute top-0 left-1/4 right-1/4 h-96 bg-accent-purple/10 rounded-full blur-[120px] pointer-events-none z-0" />
        <div className="absolute bottom-0 right-10 w-96 h-96 bg-accent-cyan/5 rounded-full blur-[150px] pointer-events-none z-0" />

        <AuthProvider>
          <div className="relative z-10 flex flex-col flex-1">
            {children}
          </div>
        </AuthProvider>
      </body>
    </html>
  );
}

