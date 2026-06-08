"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useAuth } from "@/lib/AuthContext";
import {
  ShieldAlert,
  Map,
  LineChart,
  Users,
  Activity,
  Radio,
  LayoutDashboard,
  User,
  LogOut,
  ChevronRight,
} from "lucide-react";

export default function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const { user, logout } = useAuth();

  const isAdmin = user?.role === "admin";

  /* ── Navigation structure ── */
  const adminLinks = [
    {
      label: "Dashboard",
      href: "/admin",
      icon: LayoutDashboard,
    },
    {
      label: "Fleet Tracker",
      href: "/admin/fleet-tracking",
      icon: Map,
    },
    {
      label: "System Analytics",
      href: "/admin/analytics",
      icon: LineChart,
    },
    {
      label: "User Management",
      href: "/admin/users",
      icon: Users,
    },
  ];

  const userLinks = [
    {
      label: "Dashboard",
      href: "/user",
      icon: LayoutDashboard,
    },
    {
      label: "Ride Analytics",
      href: "/user/analytics",
      icon: Activity,
    },
    {
      label: "Profile & Account",
      href: "/user/profile",
      icon: User,
    },
  ];

  const handleLogout = async () => {
    await logout();
    router.replace("/login");
  };

  return (
    <aside className="w-80 border-r border-white/5 bg-black/40 backdrop-blur-xl flex flex-col h-screen sticky top-0 z-30 shrink-0">
      {/* Brand Header */}
      <div className="p-6 border-b border-white/5 flex items-center gap-3">
        <div className="w-10 h-10 rounded-full bg-accent-purple/10 border border-accent-purple/30 flex items-center justify-center relative">
          <div className="absolute inset-1 rounded-full border border-accent-purple/40 pulse-ring-violet" />
          <ShieldAlert className="w-5 h-5 text-accent-purple" />
        </div>
        <div>
          <h1 className="font-title text-xl font-bold tracking-wider bg-gradient-to-r from-white via-slate-100 to-accent-purple bg-clip-text text-transparent">
            ARGUS<span className="text-accent-purple font-black">X</span>
          </h1>
          <p className="text-[10px] tracking-widest text-slate-500 font-medium uppercase">
            Guardentic OS v1.0
          </p>
        </div>
      </div>

      {/* Nav List */}
      <nav className="flex-1 p-6 space-y-8 overflow-y-auto">
        {/* Admin Section */}
        {isAdmin && (
          <div>
            <h2 className="text-[10px] tracking-widest text-slate-500 uppercase font-bold mb-4 flex items-center gap-2">
              <Radio className="w-3 h-3 text-accent-purple animate-pulse" />
              Admin Station
            </h2>
            <div className="space-y-1.5">
              {adminLinks.map((link) => {
                const isActive = pathname === link.href;
                const Icon = link.icon;
                return (
                  <Link
                    key={link.href}
                    href={link.href}
                    className={`flex items-center gap-3.5 px-4 py-3 rounded-lg text-sm font-medium transition-all duration-300 relative group overflow-hidden ${
                      isActive
                        ? "text-white bg-gradient-to-r from-accent-purple/20 to-accent-purple/5 border-l-2 border-accent-purple"
                        : "text-slate-400 hover:text-slate-200 hover:bg-white/[0.02]"
                    }`}
                  >
                    <Icon
                      className={`w-4 h-4 transition-colors duration-300 ${
                        isActive
                          ? "text-accent-purple"
                          : "text-slate-400 group-hover:text-slate-200"
                      }`}
                    />
                    <span>{link.label}</span>
                    {isActive && (
                      <div className="absolute -right-8 -top-8 w-16 h-16 bg-accent-purple/10 rounded-full blur-xl pointer-events-none" />
                    )}
                  </Link>
                );
              })}
            </div>
          </div>
        )}

        {/* Operator Section */}
        <div>
          <h2 className="text-[10px] tracking-widest text-slate-500 uppercase font-bold mb-4 flex items-center gap-2">
            <Activity className="w-3 h-3 text-slate-500" />
            Operator Portal
          </h2>
          <div className="space-y-1.5">
            {userLinks.map((link) => {
              const isActive = pathname === link.href;
              const Icon = link.icon;
              return (
                <Link
                  key={link.href}
                  href={link.href}
                  className={`flex items-center gap-3.5 px-4 py-3 rounded-lg text-sm font-medium transition-all duration-300 relative group overflow-hidden ${
                    isActive
                      ? "text-white bg-gradient-to-r from-accent-purple/20 to-accent-purple/5 border-l-2 border-accent-purple"
                      : "text-slate-400 hover:text-slate-200 hover:bg-white/[0.02]"
                  }`}
                >
                  <Icon
                    className={`w-4 h-4 transition-colors duration-300 ${
                      isActive
                        ? "text-accent-purple"
                        : "text-slate-400 group-hover:text-slate-200"
                    }`}
                  />
                  <span>{link.label}</span>
                  {isActive && (
                    <div className="absolute -right-8 -top-8 w-16 h-16 bg-accent-purple/10 rounded-full blur-xl pointer-events-none" />
                  )}
                </Link>
              );
            })}
          </div>
        </div>

        {/* System Health */}
        <div className="pt-6 border-t border-white/5 space-y-4">
          <h2 className="text-[10px] tracking-widest text-slate-500 uppercase font-bold flex items-center gap-2">
            <Activity className="w-3 h-3 text-slate-500" /> System Integration
          </h2>
          <div className="glass-panel p-4 rounded-xl space-y-3.5 border border-white/[0.03]">
            <div className="flex items-center justify-between text-xs">
              <span className="text-slate-500">FastAPI API</span>
              <span className="flex items-center gap-1.5 font-bold text-accent-cyan">
                <span className="w-1.5 h-1.5 rounded-full bg-accent-cyan animate-pulse" />
                ONLINE
              </span>
            </div>
            <div className="flex items-center justify-between text-xs">
              <span className="text-slate-500">FAISS Index</span>
              <span className="flex items-center gap-1.5 font-bold text-accent-cyan">
                <span className="w-1.5 h-1.5 rounded-full bg-accent-cyan animate-pulse" />
                768-DIM
              </span>
            </div>
            <div className="flex items-center justify-between text-xs">
              <span className="text-slate-500">Supabase DB</span>
              <span className="flex items-center gap-1.5 font-bold text-yellow-500">
                <span className="w-1.5 h-1.5 rounded-full bg-yellow-500 animate-pulse" />
                NO_AUTH
              </span>
            </div>
          </div>
        </div>
      </nav>

      {/* User Info & Logout Footer */}
      <div className="p-4 border-t border-white/5">
        {/* Logged-in user card */}
        {user && (
          <div className="flex items-center gap-3 p-3 rounded-xl bg-white/[0.02] border border-white/5 mb-3">
            <div className="w-9 h-9 rounded-full bg-gradient-to-br from-accent-purple/50 to-accent-pink/30 flex items-center justify-center text-xs font-bold text-white shrink-0">
              {user.name.charAt(0).toUpperCase()}
            </div>
            <div className="flex-1 min-w-0">
              <div className="text-sm font-bold text-slate-200 truncate">
                {user.name}
              </div>
              <div className="text-[10px] text-slate-500 font-mono truncate">
                {user.email}
              </div>
            </div>
            <span className="px-2 py-0.5 rounded text-[9px] font-bold uppercase tracking-wider bg-accent-purple/10 text-accent-purple border border-accent-purple/20 shrink-0">
              {user.role}
            </span>
          </div>
        )}

        {/* Logout Button */}
        <button
          onClick={handleLogout}
          className="w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-lg text-xs font-bold text-slate-400 hover:text-white bg-white/[0.02] hover:bg-accent-red/10 border border-white/5 hover:border-accent-red/20 transition-all duration-300"
        >
          <LogOut className="w-3.5 h-3.5" />
          Sign Out
        </button>

        {/* Footer Status */}
        <div className="mt-3 flex justify-between items-center text-[10px] text-slate-600 font-mono px-1">
          <span>MODE: DEV_STANDBY</span>
          <div className="flex items-center gap-1">
            <span className="w-1.5 h-1.5 rounded-full bg-accent-purple animate-ping" />
            <span>LIVE</span>
          </div>
        </div>
      </div>
    </aside>
  );
}
