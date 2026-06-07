"use client";

import Link from "next/link";
import { ShieldAlert, ArrowRight, UserCheck, ShieldCheck } from "lucide-react";

export default function Home() {
  return (
    <div className="flex flex-col flex-1 items-center justify-center p-6 relative min-h-screen">
      {/* Background Decorative Rings */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-accent-purple/5 rounded-full blur-3xl pointer-events-none" />
      
      {/* Central Interactive Content */}
      <div className="max-w-xl w-full text-center space-y-8 z-10 glass-panel-purple p-10 rounded-2xl border border-white/10">
        
        {/* Pulsing Argus Ring */}
        <div className="flex justify-center mb-6">
          <div className="w-24 h-24 rounded-full bg-gradient-to-tr from-accent-purple via-black to-accent-pink p-1 relative flex items-center justify-center pulse-ring-violet">
            <div className="absolute inset-0 bg-black rounded-full m-1 flex items-center justify-center">
              <ShieldAlert className="w-10 h-10 text-accent-purple animate-pulse" />
            </div>
          </div>
        </div>

        {/* Branding & Vision */}
        <div className="space-y-3">
          <h1 className="font-title text-4xl sm:text-5xl font-black tracking-widest bg-gradient-to-r from-white via-slate-100 to-accent-purple bg-clip-text text-transparent">
            ARGUSX
          </h1>
          <p className="text-sm text-slate-400 font-medium tracking-wide max-w-sm mx-auto">
            Distributed Multimodal AI Guardentic Vision System for Real-Time Operator Safety
          </p>
        </div>

        {/* Portal Entry Buttons */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-6">
          {/* Admin Fleet Dashboard */}
          <Link
            href="/admin/fleet-tracking"
            className="flex flex-col items-center gap-3 p-5 rounded-xl border border-white/5 bg-white/[0.02] hover:bg-accent-purple/10 hover:border-accent-purple/30 transition-all duration-300 group"
          >
            <div className="w-10 h-10 rounded-full bg-white/[0.04] flex items-center justify-center text-accent-purple group-hover:bg-accent-purple/20 transition-all">
              <ShieldCheck className="w-5 h-5" />
            </div>
            <div className="text-center">
              <h3 className="font-bold text-white text-sm group-hover:text-accent-purple transition-all">
                Fleet Command
              </h3>
              <p className="text-[11px] text-slate-500 mt-1">
                Tesla-style monitoring & telemetry
              </p>
            </div>
            <div className="flex items-center gap-1 text-[11px] text-accent-purple font-bold mt-2">
              <span>Enter Station</span>
              <ArrowRight className="w-3.5 h-3.5 group-hover:translate-x-1 transition-all" />
            </div>
          </Link>

          {/* User Onboarding Portal */}
          <Link
            href="/user/analytics"
            className="flex flex-col items-center gap-3 p-5 rounded-xl border border-white/5 bg-white/[0.02] hover:bg-accent-pink/10 hover:border-accent-pink/30 transition-all duration-300 group"
          >
            <div className="w-10 h-10 rounded-full bg-white/[0.04] flex items-center justify-center text-accent-pink group-hover:bg-accent-pink/20 transition-all">
              <UserCheck className="w-5 h-5" />
            </div>
            <div className="text-center">
              <h3 className="font-bold text-white text-sm group-hover:text-accent-pink transition-all">
                Rider Portal
              </h3>
              <p className="text-[11px] text-slate-500 mt-1">
                Personal ride metrics & HUD settings
              </p>
            </div>
            <div className="flex items-center gap-1 text-[11px] text-accent-pink font-bold mt-2">
              <span>Enter Portal</span>
              <ArrowRight className="w-3.5 h-3.5 group-hover:translate-x-1 transition-all" />
            </div>
          </Link>
        </div>

        {/* Footer Info */}
        <div className="pt-4 border-t border-white/5 text-[10px] text-slate-600 font-mono flex justify-between items-center">
          <span>COMPILED: SYSTEM_OK</span>
          <span>LATENCY: 12ms</span>
        </div>
      </div>
    </div>
  );
}
