"use client";

import Link from "next/link";
import Sidebar from "@/components/Sidebar";
import {
  Users,
  Map,
  LineChart,
  ShieldCheck,
  Activity,
  Zap,
  AlertTriangle,
  TrendingUp,
  ArrowRight,
} from "lucide-react";

export default function AdminDashboard() {
  return (
    <div className="flex flex-row min-h-screen">
      <Sidebar />

      <main className="flex-1 flex flex-col min-w-0 overflow-y-auto p-8 relative z-10">
        {/* Header */}
        <header className="flex flex-col md:flex-row md:items-center md:justify-between pb-6 border-b border-white/5 mb-8 gap-4">
          <div>
            <h1 className="font-title text-3xl font-black tracking-wide text-white">
              Command Center
            </h1>
            <p className="text-xs text-slate-400 mt-1">
              Administrative Overview — Real-Time Fleet Intelligence &amp;
              System Monitoring
            </p>
          </div>
          <div className="glass-panel border border-white/5 px-4 py-2 rounded-lg text-xs flex items-center gap-2 text-slate-300 font-mono">
            <span className="w-2 h-2 rounded-full bg-accent-green animate-pulse" />
            ALL SYSTEMS NOMINAL
          </div>
        </header>

        {/* Top Summary Cards */}
        <section className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <div className="glass-panel p-6 rounded-2xl border border-white/5">
            <div className="flex justify-between items-start text-slate-400">
              <span className="text-xs font-mono uppercase tracking-wider">
                Active Operators
              </span>
              <Users className="w-4 h-4 text-accent-purple" />
            </div>
            <div className="text-3xl font-black text-white mt-3 font-title">
              3
            </div>
            <div className="text-[10px] text-accent-green mt-1.5 font-bold flex items-center gap-1">
              <span className="w-1.5 h-1.5 rounded-full bg-accent-green animate-pulse" />
              LIVE CONNECTIONS
            </div>
          </div>

          <div className="glass-panel p-6 rounded-2xl border border-white/5">
            <div className="flex justify-between items-start text-slate-400">
              <span className="text-xs font-mono uppercase tracking-wider">
                Registered Riders
              </span>
              <ShieldCheck className="w-4 h-4 text-accent-cyan" />
            </div>
            <div className="text-3xl font-black text-white mt-3 font-title">
              18
            </div>
            <div className="text-[10px] text-slate-500 mt-1.5 font-mono">
              IN DATABASE
            </div>
          </div>

          <div className="glass-panel p-6 rounded-2xl border border-white/5">
            <div className="flex justify-between items-start text-slate-400">
              <span className="text-xs font-mono uppercase tracking-wider">
                Threats Today
              </span>
              <AlertTriangle className="w-4 h-4 text-accent-yellow" />
            </div>
            <div className="text-3xl font-black text-white mt-3 font-title">
              12
            </div>
            <div className="text-[10px] text-accent-yellow mt-1.5 font-bold">
              2 CRITICAL / 10 WARNING
            </div>
          </div>

          <div className="glass-panel p-6 rounded-2xl border border-white/5">
            <div className="flex justify-between items-start text-slate-400">
              <span className="text-xs font-mono uppercase tracking-wider">
                System Uptime
              </span>
              <Activity className="w-4 h-4 text-accent-green" />
            </div>
            <div className="text-3xl font-black text-white mt-3 font-title">
              99.7%
            </div>
            <div className="text-[10px] text-accent-cyan mt-1.5 font-bold">
              14 DAYS CONTINUOUS
            </div>
          </div>
        </section>

        {/* Quick Navigation Grid */}
        <section className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <Link
            href="/admin/fleet-tracking"
            className="glass-panel p-6 rounded-2xl border border-white/5 hover:border-accent-purple/30 transition-all duration-300 group flex flex-col gap-4"
          >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-accent-purple/10 flex items-center justify-center group-hover:bg-accent-purple/20 transition-colors">
                <Map className="w-5 h-5 text-accent-purple" />
              </div>
              <div>
                <h3 className="font-bold text-white text-sm group-hover:text-accent-purple transition-colors">
                  Fleet Tracker
                </h3>
                <p className="text-[11px] text-slate-500 mt-0.5">
                  Live spatial telemetry &amp; rider positions
                </p>
              </div>
            </div>
            <div className="flex items-center gap-1 text-[11px] text-accent-purple font-bold">
              <span>Open Station</span>
              <ArrowRight className="w-3.5 h-3.5 group-hover:translate-x-1 transition-transform" />
            </div>
          </Link>

          <Link
            href="/admin/analytics"
            className="glass-panel p-6 rounded-2xl border border-white/5 hover:border-accent-cyan/30 transition-all duration-300 group flex flex-col gap-4"
          >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-accent-cyan/10 flex items-center justify-center group-hover:bg-accent-cyan/20 transition-colors">
                <LineChart className="w-5 h-5 text-accent-cyan" />
              </div>
              <div>
                <h3 className="font-bold text-white text-sm group-hover:text-accent-cyan transition-colors">
                  System Analytics
                </h3>
                <p className="text-[11px] text-slate-500 mt-0.5">
                  Safety databases &amp; performance stats
                </p>
              </div>
            </div>
            <div className="flex items-center gap-1 text-[11px] text-accent-cyan font-bold">
              <span>View Reports</span>
              <ArrowRight className="w-3.5 h-3.5 group-hover:translate-x-1 transition-transform" />
            </div>
          </Link>

          <Link
            href="/admin/users"
            className="glass-panel p-6 rounded-2xl border border-white/5 hover:border-accent-pink/30 transition-all duration-300 group flex flex-col gap-4"
          >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-accent-pink/10 flex items-center justify-center group-hover:bg-accent-pink/20 transition-colors">
                <Users className="w-5 h-5 text-accent-pink" />
              </div>
              <div>
                <h3 className="font-bold text-white text-sm group-hover:text-accent-pink transition-colors">
                  User Management
                </h3>
                <p className="text-[11px] text-slate-500 mt-0.5">
                  Operators, bans, profiles &amp; locations
                </p>
              </div>
            </div>
            <div className="flex items-center gap-1 text-[11px] text-accent-pink font-bold">
              <span>Manage Users</span>
              <ArrowRight className="w-3.5 h-3.5 group-hover:translate-x-1 transition-transform" />
            </div>
          </Link>
        </section>

        {/* Live System Status Panel */}
        <section className="glass-panel p-6 rounded-2xl border border-white/5">
          <h3 className="font-title font-bold text-slate-200 mb-4 flex items-center gap-2">
            <Zap className="w-4 h-4 text-accent-purple" />
            System Integration Status
          </h3>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            {[
              {
                name: "FastAPI Orchestrator",
                status: "ONLINE",
                color: "text-accent-cyan",
                dotColor: "bg-accent-cyan",
              },
              {
                name: "LangGraph Agent Kernel",
                status: "COMPILED",
                color: "text-accent-green",
                dotColor: "bg-accent-green",
              },
              {
                name: "FAISS Vector Store",
                status: "768-DIM READY",
                color: "text-accent-purple",
                dotColor: "bg-accent-purple",
              },
              {
                name: "Supabase PostgreSQL",
                status: "CONNECTED",
                color: "text-accent-cyan",
                dotColor: "bg-accent-cyan",
              },
            ].map((svc) => (
              <div
                key={svc.name}
                className="bg-white/[0.01] border border-white/5 rounded-xl p-4 flex items-center justify-between"
              >
                <span className="text-xs text-slate-400">{svc.name}</span>
                <span
                  className={`flex items-center gap-1.5 text-[10px] font-bold ${svc.color}`}
                >
                  <span
                    className={`w-1.5 h-1.5 rounded-full ${svc.dotColor} animate-pulse`}
                  />
                  {svc.status}
                </span>
              </div>
            ))}
          </div>
        </section>
      </main>
    </div>
  );
}
