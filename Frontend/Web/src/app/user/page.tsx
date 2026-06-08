"use client";

import Link from "next/link";
import Sidebar from "@/components/Sidebar";
import { useAuth } from "@/lib/AuthContext";
import {
  Award,
  Activity,
  Navigation,
  ShieldCheck,
  ArrowRight,
  Zap,
  Settings,
  User,
} from "lucide-react";

export default function UserDashboard() {
  const { user } = useAuth();
  const displayName = user?.name ?? "Rider";

  return (
    <div className="flex flex-row min-h-screen">
      <Sidebar />

      <main className="flex-1 flex flex-col min-w-0 overflow-y-auto p-8 relative z-10">
        {/* Hero Welcome */}
        <header className="pb-8 border-b border-white/5 mb-8 relative overflow-hidden rounded-2xl glass-panel-purple p-8">
          <div className="absolute top-0 right-0 w-64 h-64 bg-accent-purple/10 rounded-full blur-[80px] pointer-events-none" />
          <div className="relative z-10">
            <div className="flex items-center gap-4 mb-4">
              <div className="w-16 h-16 rounded-full bg-gradient-to-br from-accent-purple to-accent-pink p-[2px]">
                <div className="w-full h-full bg-black rounded-full flex items-center justify-center text-xl font-black text-white font-title">
                  {displayName.charAt(0)}
                </div>
              </div>
              <div>
                <h1 className="font-title text-2xl sm:text-3xl font-black tracking-wide text-white">
                  Welcome back, {displayName}
                </h1>
                <p className="text-xs text-slate-400 mt-1 font-mono">
                  SESSION: ACTIVE — TIER 1 MASTER OPERATOR
                </p>
              </div>
            </div>

            {/* Quick Stats Row */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mt-6">
              <div className="bg-white/[0.03] border border-white/5 rounded-xl p-4">
                <div className="text-[10px] text-slate-500 font-mono uppercase">
                  Safety Score
                </div>
                <div className="text-2xl font-black text-accent-green mt-1 font-title">
                  96
                </div>
              </div>
              <div className="bg-white/[0.03] border border-white/5 rounded-xl p-4">
                <div className="text-[10px] text-slate-500 font-mono uppercase">
                  Total Rides
                </div>
                <div className="text-2xl font-black text-white mt-1 font-title">
                  142
                </div>
              </div>
              <div className="bg-white/[0.03] border border-white/5 rounded-xl p-4">
                <div className="text-[10px] text-slate-500 font-mono uppercase">
                  Miles Logged
                </div>
                <div className="text-2xl font-black text-white mt-1 font-title">
                  1,248
                </div>
              </div>
              <div className="bg-white/[0.03] border border-white/5 rounded-xl p-4">
                <div className="text-[10px] text-slate-500 font-mono uppercase">
                  Interventions
                </div>
                <div className="text-2xl font-black text-accent-purple mt-1 font-title">
                  18
                </div>
              </div>
            </div>
          </div>
        </header>

        {/* Navigation Cards */}
        <section className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <Link
            href="/user/analytics"
            className="glass-panel p-6 rounded-2xl border border-white/5 hover:border-accent-purple/30 transition-all duration-300 group flex flex-col gap-4"
          >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-accent-purple/10 flex items-center justify-center group-hover:bg-accent-purple/20 transition-colors">
                <Activity className="w-5 h-5 text-accent-purple" />
              </div>
              <div>
                <h3 className="font-bold text-white text-sm group-hover:text-accent-purple transition-colors">
                  Ride Analytics
                </h3>
                <p className="text-[11px] text-slate-500 mt-0.5">
                  HUD settings &amp; performance metrics
                </p>
              </div>
            </div>
            <div className="flex items-center gap-1 text-[11px] text-accent-purple font-bold">
              <span>View Dashboard</span>
              <ArrowRight className="w-3.5 h-3.5 group-hover:translate-x-1 transition-transform" />
            </div>
          </Link>

          <Link
            href="/user/profile"
            className="glass-panel p-6 rounded-2xl border border-white/5 hover:border-accent-cyan/30 transition-all duration-300 group flex flex-col gap-4"
          >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-accent-cyan/10 flex items-center justify-center group-hover:bg-accent-cyan/20 transition-colors">
                <User className="w-5 h-5 text-accent-cyan" />
              </div>
              <div>
                <h3 className="font-bold text-white text-sm group-hover:text-accent-cyan transition-colors">
                  Profile &amp; Account
                </h3>
                <p className="text-[11px] text-slate-500 mt-0.5">
                  Personal info, email &amp; preferences
                </p>
              </div>
            </div>
            <div className="flex items-center gap-1 text-[11px] text-accent-cyan font-bold">
              <span>Edit Profile</span>
              <ArrowRight className="w-3.5 h-3.5 group-hover:translate-x-1 transition-transform" />
            </div>
          </Link>

          <div className="glass-panel p-6 rounded-2xl border border-white/5 flex flex-col gap-4 opacity-50">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-accent-pink/10 flex items-center justify-center">
                <Navigation className="w-5 h-5 text-accent-pink" />
              </div>
              <div>
                <h3 className="font-bold text-white text-sm">
                  Ride History Map
                </h3>
                <p className="text-[11px] text-slate-500 mt-0.5">
                  Spatial routes &amp; safety heatmaps
                </p>
              </div>
            </div>
            <div className="flex items-center gap-1 text-[11px] text-slate-500 font-bold font-mono">
              COMING SOON
            </div>
          </div>
        </section>

        {/* Recent Activity */}
        <section className="glass-panel p-6 rounded-2xl border border-white/5">
          <h3 className="font-title font-bold text-slate-200 mb-4 flex items-center gap-2">
            <Zap className="w-4 h-4 text-accent-purple" />
            Recent Ride Sessions
          </h3>
          <div className="space-y-3">
            {[
              {
                date: "Jun 6, 2026",
                duration: "48 mins",
                score: 94,
                threats: 2,
              },
              {
                date: "Jun 5, 2026",
                duration: "34 mins",
                score: 97,
                threats: 1,
              },
              {
                date: "Jun 4, 2026",
                duration: "1h 12m",
                score: 89,
                threats: 3,
              },
            ].map((ride, i) => (
              <div
                key={i}
                className="flex items-center justify-between py-3 px-4 bg-white/[0.01] border border-white/5 rounded-xl hover:bg-white/[0.03] transition-all"
              >
                <div className="flex items-center gap-4">
                  <div className="w-8 h-8 rounded-lg bg-accent-purple/10 flex items-center justify-center">
                    <ShieldCheck className="w-4 h-4 text-accent-purple" />
                  </div>
                  <div>
                    <div className="text-sm font-bold text-slate-200">
                      {ride.date}
                    </div>
                    <div className="text-[10px] text-slate-500 font-mono">
                      Duration: {ride.duration} • Threats: {ride.threats}
                    </div>
                  </div>
                </div>
                <span
                  className={`font-bold text-sm ${
                    ride.score >= 95
                      ? "text-accent-green"
                      : ride.score >= 85
                      ? "text-accent-yellow"
                      : "text-accent-red"
                  }`}
                >
                  {ride.score}/100
                </span>
              </div>
            ))}
          </div>
        </section>
      </main>
    </div>
  );
}
