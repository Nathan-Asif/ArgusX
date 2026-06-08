"use client";

import { useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/lib/AuthContext";
import {
  ShieldAlert,
  Mail,
  Lock,
  ArrowRight,
  Loader2,
  AlertCircle,
  Eye,
  EyeOff,
} from "lucide-react";

export default function LoginPage() {
  const { login, user } = useAuth();
  const router = useRouter();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  // If already logged in, redirect
  if (user) {
    router.replace(user.role === "admin" ? "/admin" : "/user");
    return null;
  }

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

    // Tiny delay for UX polish, then redirect
    setTimeout(() => {
      // Re-read from context isn't reliable here — peek at what we know
      const isAdmin = email.toLowerCase().includes("admin");
      router.replace(isAdmin ? "/admin" : "/user");
    }, 300);
  };

  return (
    <div className="flex flex-col flex-1 items-center justify-center p-6 relative min-h-screen">
      {/* Ambient background effects */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[700px] h-[700px] bg-accent-purple/[0.04] rounded-full blur-[120px] pointer-events-none" />
      <div className="absolute top-1/4 right-1/4 w-[400px] h-[400px] bg-accent-pink/[0.03] rounded-full blur-[100px] pointer-events-none" />

      {/* ── Login Card ──────────────────────────────────────── */}
      <div className="max-w-md w-full text-center z-10 animate-fade-in-up">
        {/* Pulsing Argus Iris */}
        <div className="flex justify-center mb-8">
          <div className="w-[88px] h-[88px] rounded-full bg-gradient-to-tr from-accent-purple via-black to-accent-pink p-[3px] relative flex items-center justify-center animate-iris-breathe">
            <div className="absolute inset-0 bg-black rounded-full m-[3px] flex items-center justify-center">
              <ShieldAlert className="w-9 h-9 text-accent-purple animate-pulse" />
            </div>
            {/* Outer ring glow */}
            <div className="absolute -inset-3 rounded-full border border-accent-purple/10 pulse-ring-violet pointer-events-none" />
          </div>
        </div>

        {/* Brand */}
        <div className="space-y-2 mb-8 animate-fade-in-up-delay">
          <h1 className="font-title text-4xl sm:text-5xl font-black tracking-[0.2em] bg-gradient-to-r from-white via-slate-100 to-accent-purple bg-clip-text text-transparent">
            ARGUSX
          </h1>
          <p className="text-[11px] text-slate-500 font-mono tracking-widest uppercase">
            Guardentic Vision System — Secure Access
          </p>
        </div>

        {/* Glass Form Card */}
        <div className="glass-panel-purple p-8 rounded-2xl border border-white/10 text-left animate-fade-in-up-delay-2">
          <h2 className="text-sm font-bold text-slate-200 mb-1">
            Operator Authentication
          </h2>
          <p className="text-[11px] text-slate-500 mb-6">
            Enter your system credentials to access the portal.
          </p>

          <form onSubmit={handleSubmit} className="space-y-5">
            {/* Email */}
            <div className="space-y-1.5">
              <label
                htmlFor="login-email"
                className="text-[10px] text-slate-500 font-mono uppercase tracking-wider block"
              >
                Email Address
              </label>
              <div className="relative">
                <Mail className="w-4 h-4 text-slate-500 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
                <input
                  id="login-email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="admin@argusx.io"
                  required
                  autoComplete="email"
                  className="glass-input pl-10"
                />
              </div>
            </div>

            {/* Password */}
            <div className="space-y-1.5">
              <label
                htmlFor="login-password"
                className="text-[10px] text-slate-500 font-mono uppercase tracking-wider block"
              >
                Password
              </label>
              <div className="relative">
                <Lock className="w-4 h-4 text-slate-500 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
                <input
                  id="login-password"
                  type={showPassword ? "text" : "password"}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  required
                  autoComplete="current-password"
                  className="glass-input pl-10 pr-10"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-300 transition-colors"
                  tabIndex={-1}
                >
                  {showPassword ? (
                    <EyeOff className="w-4 h-4" />
                  ) : (
                    <Eye className="w-4 h-4" />
                  )}
                </button>
              </div>
            </div>

            {/* Error */}
            {error && (
              <div className="flex items-center gap-2 bg-accent-red/10 border border-accent-red/20 text-accent-red text-xs p-3 rounded-lg">
                <AlertCircle className="w-4 h-4 shrink-0" />
                <span>{error}</span>
              </div>
            )}

            {/* Submit */}
            <button
              type="submit"
              disabled={loading || !email || !password}
              className="btn-primary w-full py-3 text-sm"
            >
              {loading ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  Authenticating…
                </>
              ) : (
                <>
                  Access Station
                  <ArrowRight className="w-4 h-4" />
                </>
              )}
            </button>
          </form>

          {/* Hint */}
          <div className="mt-6 pt-4 border-t border-white/5">
            <p className="text-[10px] text-slate-600 font-mono leading-relaxed">
              DEMO ACCESS — Admin:{" "}
              <span className="text-slate-400">admin@argusx.io</span> /{" "}
              <span className="text-slate-400">argusx2026</span>
              <br />
              Rider:{" "}
              <span className="text-slate-400">rider@argusx.io</span> /{" "}
              <span className="text-slate-400">rider2026</span>
            </p>
          </div>
        </div>

        {/* Footer */}
        <div className="mt-6 text-[10px] text-slate-600 font-mono flex justify-between items-center px-2">
          <span>PROTOCOL: TLS 1.3 / JWT</span>
          <span>SYSTEM: SECURE</span>
        </div>
      </div>
    </div>
  );
}
