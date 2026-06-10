"use client";

import { useState, useEffect, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/lib/AuthContext";
import {
  Mail,
  Lock,
  ArrowRight,
  Loader2,
  AlertCircle,
  Eye,
  EyeOff,
  Shield,
  Wifi,
  Activity,
} from "lucide-react";

export default function LoginPage() {
  const { login, user } = useAuth();
  const router = useRouter();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [tick, setTick] = useState(0);

  useEffect(() => {
    if (user) router.replace(user.role === "admin" ? "/admin" : "/user");
  }, [user, router]);

  // Blinking clock tick for the HUD decoration
  useEffect(() => {
    const id = setInterval(() => setTick((t) => t + 1), 1000);
    return () => clearInterval(id);
  }, []);

  if (user) return null;

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);
    const result = await login(email, password);
    if (result.error) {
      setError(result.error);
      setLoading(false);
      return;
    }
    setTimeout(() => {
      const isAdmin = email.toLowerCase().includes("admin");
      router.replace(isAdmin ? "/admin" : "/user");
    }, 300);
  };

  const now = new Date();
  const timeStr = now.toLocaleTimeString("en-US", {
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hour12: false,
  });

  return (
    <div
      className="flex min-h-[100dvh] w-full"
      style={{ fontFamily: "'Outfit', sans-serif" }}
    >
      {/* ── LEFT PANEL — Brand & HUD Decoration ─────────────── */}
      <div
        className="hidden lg:flex flex-col justify-between w-[45%] shrink-0 relative overflow-hidden p-12"
        style={{ background: "linear-gradient(160deg, #0e0e0f 0%, #131314 40%, #1a0f28 100%)" }}
      >
        {/* Grid overlay */}
        <div className="absolute inset-0 grid-bg opacity-60 pointer-events-none" />

        {/* Purple glow blob */}
        <div
          className="absolute top-1/3 left-1/4 w-[400px] h-[400px] pointer-events-none"
          style={{ background: "radial-gradient(ellipse at center, rgba(142,45,226,0.12) 0%, transparent 70%)" }}
        />
        <div
          className="absolute bottom-0 right-0 w-[300px] h-[300px] pointer-events-none"
          style={{ background: "radial-gradient(ellipse at center, rgba(75,6,225,0.08) 0%, transparent 70%)" }}
        />

        {/* Top: brand logo + wordmark */}
        <div className="flex items-center gap-4 relative z-10 animate-fade-in-up">
          <div
            className="w-12 h-12 flex items-center justify-center relative overflow-hidden animate-iris-breathe"
            style={{ border: "1px solid rgba(221,183,255,0.25)", background: "rgba(142,45,226,0.1)" }}
          >
            <img src="/logo.png" alt="ArgusX" className="w-8 h-8 object-contain" />
            <div className="absolute inset-0" style={{ border: "1px solid rgba(142,45,226,0.2)" }} />
          </div>
          <div>
            <p
              className="text-xl tracking-[0.25em] text-white"
              style={{ fontFamily: "'Zen Dots', sans-serif", textTransform: "uppercase" }}
            >
              ARGUS<span style={{ color: "#ddb7ff" }}>X</span>
            </p>
            <p className="text-[10px] tracking-[0.2em] uppercase" style={{ color: "#998ca0", fontFamily: "'Zen Dots', sans-serif" }}>
              Guardentic OS v1.0
            </p>
          </div>
        </div>

        {/* Center: the big hero text */}
        <div className="relative z-10 animate-fade-in-up-delay">
          <p className="text-[10px] tracking-[0.25em] uppercase mb-6" style={{ color: "#00e5ff", fontFamily: "'Zen Dots', sans-serif" }}>
            Tactical Safety Intelligence
          </p>
          <h1
            className="text-5xl mb-6 leading-tight"
            style={{
              fontFamily: "'Zen Dots', sans-serif",
              textTransform: "uppercase",
              background: "linear-gradient(135deg, #e5e2e3 0%, #cfc2d7 50%, #ddb7ff 100%)",
              WebkitBackgroundClip: "text",
              WebkitTextFillColor: "transparent",
              backgroundClip: "text",
              letterSpacing: "0.04em",
            }}
          >
            Operator<br />Command<br />Station
          </h1>
          <p className="text-sm leading-relaxed max-w-[320px]" style={{ color: "#998ca0", fontFamily: "'Outfit', sans-serif" }}>
            Real-time fleet intelligence, rider safety analytics, and agentic threat detection. Authenticate to access the grid.
          </p>

          {/* HUD stat row */}
          <div className="flex gap-6 mt-10">
            {[
              { icon: Wifi, label: "Network", val: "SECURED" },
              { icon: Shield, label: "Encryption", val: "AES-256" },
              { icon: Activity, label: "Status", val: "NOMINAL" },
            ].map(({ icon: Icon, label, val }) => (
              <div key={label}>
                <div className="flex items-center gap-1.5 mb-1">
                  <Icon className="w-3 h-3" style={{ color: "#8e2de2" }} />
                  <span className="text-[9px] uppercase tracking-[0.18em]" style={{ color: "#6d6478", fontFamily: "'Zen Dots', sans-serif" }}>{label}</span>
                </div>
                <p className="text-xs font-bold" style={{ color: "#ddb7ff", fontFamily: "'Cormorant Garamond', Georgia, serif", letterSpacing: "0.1em" }}>{val}</p>
              </div>
            ))}
          </div>
        </div>

        {/* Bottom: live clock + protocol line */}
        <div className="relative z-10 flex items-end justify-between animate-fade-in-up-delay-2">
          <div>
            <p
              className="text-2xl tabular-nums"
              style={{ fontFamily: "'Cormorant Garamond', Georgia, serif", color: "#998ca0", letterSpacing: "0.12em" }}
            >
              {timeStr}
            </p>
            <p className="text-[9px] uppercase tracking-[0.18em] mt-1" style={{ color: "#6d6478", fontFamily: "'Zen Dots', sans-serif" }}>
              LOCAL — UTC+05:00
            </p>
          </div>
          <p className="text-[9px] uppercase tracking-[0.18em]" style={{ color: "#6d6478", fontFamily: "'Zen Dots', sans-serif" }}>
            TLS 1.3 / JWT
          </p>
        </div>

        {/* Decorative vertical rule */}
        <div
          className="absolute top-0 right-0 w-px h-full"
          style={{ background: "linear-gradient(to bottom, transparent 0%, rgba(221,183,255,0.1) 30%, rgba(142,45,226,0.2) 60%, transparent 100%)" }}
        />
      </div>

      {/* ── RIGHT PANEL — Auth Form ──────────────────────────── */}
      <div
        className="flex-1 flex flex-col items-center justify-center p-8 md:p-16 relative"
        style={{ background: "#131314" }}
      >
        {/* Subtle ambient glow */}
        <div
          className="absolute top-0 right-0 w-[500px] h-[500px] pointer-events-none"
          style={{ background: "radial-gradient(ellipse at top right, rgba(75,6,225,0.06) 0%, transparent 60%)" }}
        />

        {/* Mobile-only logo */}
        <div className="lg:hidden flex items-center gap-3 mb-12 self-start animate-fade-in-up">
          <div
            className="w-9 h-9 flex items-center justify-center overflow-hidden"
            style={{ border: "1px solid rgba(221,183,255,0.2)", background: "rgba(142,45,226,0.08)" }}
          >
            <img src="/logo.png" alt="ArgusX" className="w-6 h-6 object-contain" />
          </div>
          <span
            className="text-lg tracking-[0.2em] text-white"
            style={{ fontFamily: "'Zen Dots', sans-serif", textTransform: "uppercase" }}
          >
            ARGUS<span style={{ color: "#ddb7ff" }}>X</span>
          </span>
        </div>

        <div className="w-full max-w-[400px] relative z-10">
          {/* Heading */}
          <div className="mb-10 animate-fade-in-up">
            <h2
              className="text-2xl mb-2"
              style={{
                fontFamily: "'Zen Dots', sans-serif",
                textTransform: "uppercase",
                letterSpacing: "0.06em",
                color: "#e5e2e3",
              }}
            >
              Authenticate
            </h2>
            <p className="text-sm" style={{ color: "#998ca0", fontFamily: "'Outfit', sans-serif" }}>
              Enter your operator credentials to access the portal.
            </p>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-5 animate-fade-in-up-delay">
            {/* Email */}
            <div className="space-y-2">
              <label
                htmlFor="login-email"
                className="block text-[11px] uppercase tracking-[0.15em] font-bold"
                style={{ color: "#998ca0", fontFamily: "'Zen Dots', sans-serif" }}
              >
                Email Address
              </label>
              <div className="relative">
                <Mail className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" style={{ color: "#998ca0" }} />
                <input
                  id="login-email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="operator@argusx.io"
                  required
                  autoComplete="email"
                  className="glass-input"
                />
              </div>
            </div>

            {/* Password */}
            <div className="space-y-2">
              <label
                htmlFor="login-password"
                className="block text-[11px] uppercase tracking-[0.15em] font-bold"
                style={{ color: "#998ca0", fontFamily: "'Zen Dots', sans-serif" }}
              >
                Password
              </label>
              <div className="relative">
                <Lock className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" style={{ color: "#998ca0" }} />
                <input
                  id="login-password"
                  type={showPassword ? "text" : "password"}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  required
                  autoComplete="current-password"
                  className="glass-input"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3.5 top-1/2 -translate-y-1/2 transition-colors"
                  style={{ color: "#998ca0" }}
                  tabIndex={-1}
                >
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>

            {/* Error */}
            {error && (
              <div
                className="flex items-center gap-2.5 p-3 text-xs"
                style={{
                  background: "rgba(255,82,82,0.08)",
                  border: "1px solid rgba(255,82,82,0.25)",
                  color: "#ff5252",
                  fontFamily: "'Outfit', sans-serif",
                }}
              >
                <AlertCircle className="w-4 h-4 shrink-0" />
                <span>{error}</span>
              </div>
            )}

            {/* Submit */}
            <button
              id="login-submit"
              type="submit"
              disabled={loading || !email || !password}
              className="btn-primary w-full py-3.5"
            >
              {loading ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  Authenticating
                </>
              ) : (
                <>
                  Access Station
                  <ArrowRight className="w-4 h-4" />
                </>
              )}
            </button>
          </form>

          {/* Demo hint */}
          <div
            className="mt-8 pt-6 animate-fade-in-up-delay-2"
            style={{ borderTop: "1px solid rgba(255,255,255,0.04)" }}
          >
            <p
              className="text-[10px] uppercase tracking-[0.15em] mb-3 font-bold"
              style={{ color: "#6d6478", fontFamily: "'Zen Dots', sans-serif" }}
            >
              Demo Access
            </p>
            <div className="space-y-2">
              {[
                { role: "Admin", email: "nathanasif@gmail.com", pass: "admin123" },
                { role: "Rider", email: "rider@argusx.io", pass: "rider2026" },
              ].map((cred) => (
                <button
                  key={cred.role}
                  type="button"
                  onClick={() => { setEmail(cred.email); setPassword(cred.pass); }}
                  className="w-full text-left px-3 py-2.5 transition-colors group"
                  style={{
                    background: "rgba(255,255,255,0.015)",
                    border: "1px solid rgba(255,255,255,0.05)",
                    cursor: "pointer",
                  }}
                >
                  <div className="flex items-center justify-between">
                    <span
                      className="text-[10px] font-bold uppercase tracking-[0.12em]"
                      style={{ color: "#998ca0", fontFamily: "'Zen Dots', sans-serif" }}
                    >
                      {cred.role}
                    </span>
                    <span
                      className="text-[10px] font-bold uppercase tracking-[0.1em]"
                      style={{ color: "#ddb7ff", fontFamily: "'Cormorant Garamond', serif" }}
                    >
                      Fill In
                    </span>
                  </div>
                  <p
                    className="text-[11px] mt-0.5"
                    style={{ color: "#4d4354", fontFamily: "'Cormorant Garamond', serif", letterSpacing: "0.05em" }}
                  >
                    {cred.email}
                  </p>
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
