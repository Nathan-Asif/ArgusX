"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useAuth } from "@/lib/AuthContext";
import { motion } from "framer-motion";
import {
  Map,
  LineChart,
  Users,
  Activity,
  Radio,
  LayoutDashboard,
  User,
  LogOut,
  Cpu,
  Database,
} from "lucide-react";

/* ── Design tokens (inline for guaranteed rendering) */
const C = {
  bg:       "#0e0e0f",
  surface:  "#131314",
  border:   "rgba(221,183,255,0.07)",
  purple:   "#ddb7ff",
  violet:   "#8e2de2",
  cyan:     "#00e5ff",
  green:    "#00e676",
  yellow:   "#ffb74d",
  muted:    "#998ca0",
  subtle:   "#4d4354",
  text:     "#e5e2e3",
  textDim:  "#cfc2d7",
};

interface NavLink { label: string; href: string; icon: React.ElementType; accent?: string; }

export default function Sidebar() {
  const pathname = usePathname();
  const router   = useRouter();
  const { user, logout } = useAuth();
  const isAdmin  = user?.role === "admin";

  const adminLinks: NavLink[] = [
    { label: "Dashboard",        href: "/admin",               icon: LayoutDashboard, accent: C.purple },
    { label: "Fleet Tracker",    href: "/admin/fleet-tracking", icon: Map,             accent: C.cyan   },
    { label: "System Analytics", href: "/admin/analytics",     icon: LineChart,        accent: C.cyan   },
    { label: "User Management",  href: "/admin/users",         icon: Users,            accent: "#ec4899"},
  ];

  const userLinks: NavLink[] = [
    { label: "Dashboard",       href: "/user",           icon: LayoutDashboard, accent: C.purple },
    { label: "Ride Analytics",  href: "/user/analytics", icon: Activity,        accent: C.cyan   },
    { label: "Profile",         href: "/user/profile",   icon: User,            accent: C.muted  },
  ];

  const handleLogout = async () => { await logout(); router.replace("/login"); };

  const NavItem = ({ link }: { link: NavLink }) => {
    const isActive = pathname === link.href;
    const Icon = link.icon;
    const accent = link.accent ?? C.purple;
    return (
      <Link
        href={link.href}
        style={{
          display: "flex",
          alignItems: "center",
          gap: "12px",
          padding: "10px 14px",
          color: isActive ? C.text : C.muted,
          fontFamily: "'Zen Dots', sans-serif",
          fontSize: "11px",
          textTransform: "uppercase",
          letterSpacing: "0.1em",
          textDecoration: "none",
          transition: "color 0.2s",
          position: "relative",
        }}
        onMouseEnter={(e) => { if (!isActive) e.currentTarget.style.color = C.textDim; }}
        onMouseLeave={(e) => { if (!isActive) e.currentTarget.style.color = C.muted; }}
      >
        {/* Dynamic active state container driven by Framer Motion */}
        {isActive && (
          <motion.div
            layoutId="activeNavIndicator"
            style={{
              position: "absolute",
              left: 0,
              top: 0,
              bottom: 0,
              width: "100%",
              background: `linear-gradient(90deg, ${accent}14 0%, transparent 100%)`,
              borderLeft: `2px solid ${accent}`,
              zIndex: 0,
            }}
            transition={{ type: "spring", stiffness: 350, damping: 28 }}
          />
        )}

        <div style={{ display: "flex", alignItems: "center", gap: "12px", position: "relative", zIndex: 1, width: "100%" }}>
          <Icon size={15} style={{ color: isActive ? accent : C.subtle, flexShrink: 0 }} />
          <span style={{ flexGrow: 1 }}>{link.label}</span>
          {isActive && (
            <span
              style={{
                width: "4px",
                height: "4px",
                background: accent,
                flexShrink: 0,
              }}
            />
          )}
        </div>
      </Link>
    );
  };

  return (
    <aside
      style={{
        width: "260px",
        minWidth: "260px",
        background: C.bg,
        borderRight: `1px solid ${C.border}`,
        backdropFilter: "blur(20px)",
        WebkitBackdropFilter: "blur(20px)",
        display: "flex",
        flexDirection: "column",
        height: "100vh",
        position: "sticky",
        top: 0,
        zIndex: 30,
        overflow: "hidden",
      }}
    >
      {/* ── Brand Header ── */}
      <div
        style={{
          padding: "20px",
          borderBottom: `1px solid ${C.border}`,
          display: "flex",
          alignItems: "center",
          gap: "12px",
          flexShrink: 0,
        }}
      >
        <div
          style={{
            width: "36px",
            height: "36px",
            background: "rgba(142,45,226,0.1)",
            border: `1px solid rgba(221,183,255,0.2)`,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            flexShrink: 0,
            position: "relative",
            overflow: "hidden",
          }}
          className="animate-iris-breathe"
        >
          <img src="/logo.png" alt="ArgusX" style={{ width: "22px", height: "22px", objectFit: "contain" }} />
        </div>
        <div>
          <p
            style={{
              fontFamily: "'Zen Dots', sans-serif",
              fontSize: "15px",
              letterSpacing: "0.2em",
              textTransform: "uppercase",
              color: C.text,
              lineHeight: 1,
            }}
          >
            ARGUS<span style={{ color: C.purple }}>X</span>
          </p>
          <p
            style={{
              fontFamily: "'Zen Dots', sans-serif",
              fontSize: "8px",
              letterSpacing: "0.18em",
              textTransform: "uppercase",
              color: C.subtle,
              marginTop: "3px",
            }}
          >
            Guardentic OS v1.0
          </p>
        </div>
      </div>

      {/* ── Nav ── */}
      <motion.nav
        initial={{ opacity: 0, x: -6 }}
        animate={{ opacity: 1, x: 0 }}
        transition={{ duration: 0.4, ease: "easeOut" }}
        style={{ flex: 1, padding: "20px 0", overflowY: "auto", display: "flex", flexDirection: "column", gap: "24px" }}
      >

        {/* Admin section */}
        {isAdmin && (
          <div>
            <div
              style={{
                display: "flex",
                alignItems: "center",
                gap: "8px",
                padding: "0 16px",
                marginBottom: "8px",
              }}
            >
              <Radio size={10} style={{ color: C.violet }} className="animate-data-blink" />
              <span
                style={{
                  fontFamily: "'Zen Dots', sans-serif",
                  fontSize: "9px",
                  fontWeight: 700,
                  letterSpacing: "0.2em",
                  textTransform: "uppercase",
                  color: C.subtle,
                }}
              >
                Admin Station
              </span>
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: "2px" }}>
              {adminLinks.map((l) => <NavItem key={l.href} link={l} />)}
            </div>
          </div>
        )}

        {/* Operator section */}
        <div>
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: "8px",
              padding: "0 16px",
              marginBottom: "8px",
            }}
          >
            <Activity size={10} style={{ color: C.subtle }} />
            <span
              style={{
                fontFamily: "'Zen Dots', sans-serif",
                fontSize: "9px",
                fontWeight: 700,
                letterSpacing: "0.2em",
                textTransform: "uppercase",
                color: C.subtle,
              }}
            >
              Operator Portal
            </span>
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: "2px" }}>
            {userLinks.map((l) => <NavItem key={l.href} link={l} />)}
          </div>
        </div>

        {/* System health */}
        <div style={{ padding: "0 16px", marginTop: "auto" }}>
          <div
            style={{
              borderTop: `1px solid ${C.border}`,
              paddingTop: "16px",
              marginTop: "8px",
            }}
          >
            <span
              style={{
                display: "block",
                fontFamily: "'Zen Dots', sans-serif",
                fontSize: "9px",
                fontWeight: 700,
                letterSpacing: "0.2em",
                textTransform: "uppercase",
                color: C.subtle,
                marginBottom: "10px",
              }}
            >
              System Integration
            </span>
            <div style={{ display: "flex", flexDirection: "column", gap: "8px" }}>
              {[
                { name: "FastAPI", icon: Cpu,      status: "ONLINE",   color: C.green  },
                { name: "FAISS",   icon: Database, status: "768-DIM",  color: C.cyan   },
                { name: "Supabase",icon: Database, status: "NO_AUTH",  color: C.yellow },
              ].map(({ name, icon: Icon, status, color }) => (
                <div
                  key={name}
                  style={{
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "space-between",
                    padding: "8px 10px",
                    background: "rgba(255,255,255,0.015)",
                    border: `1px solid ${C.border}`,
                  }}
                >
                  <div style={{ display: "flex", alignItems: "center", gap: "7px" }}>
                    <Icon size={11} style={{ color: C.subtle }} />
                    <span style={{ fontFamily: "'Zen Dots', sans-serif", fontSize: "9px", letterSpacing: "0.1em", textTransform: "uppercase", color: C.muted }}>{name}</span>
                  </div>
                  <div style={{ display: "flex", alignItems: "center", gap: "5px" }}>
                    <span
                      style={{
                        width: "5px",
                        height: "5px",
                        background: color,
                        display: "inline-block",
                        animation: "pulse 2s ease-in-out infinite",
                      }}
                    />
                    <span style={{ fontFamily: "'Zen Dots', sans-serif", fontSize: "9px", fontWeight: 400, color, letterSpacing: "0.08em" }}>
                      {status}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </motion.nav>

      {/* ── User Footer ── */}
      <div
        style={{
          padding: "16px",
          borderTop: `1px solid ${C.border}`,
          flexShrink: 0,
        }}
      >
        {user && (
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: "10px",
              padding: "10px",
              background: "rgba(255,255,255,0.02)",
              border: `1px solid ${C.border}`,
              marginBottom: "10px",
              position: "relative",
            }}
          >
            {/* Avatar */}
            <div
              style={{
                width: "32px",
                height: "32px",
                background: "linear-gradient(135deg, rgba(142,45,226,0.5) 0%, rgba(236,72,153,0.3) 100%)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                fontFamily: "'Zen Dots', sans-serif",
                fontSize: "12px",
                color: C.text,
                flexShrink: 0,
              }}
            >
              {user.name.charAt(0).toUpperCase()}
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <p style={{ fontFamily: "'Zen Dots', sans-serif", fontSize: "11px", fontWeight: 400, color: C.text, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                {user.name}
              </p>
              <p style={{ fontFamily: "'Share Tech Mono', monospace", fontSize: "10px", color: C.subtle, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", letterSpacing: "0.04em" }}>
                {user.email}
              </p>
            </div>
            <span
              style={{
                padding: "2px 6px",
                fontFamily: "'Zen Dots', sans-serif",
                fontSize: "7px",
                fontWeight: 400,
                textTransform: "uppercase",
                letterSpacing: "0.1em",
                color: C.purple,
                background: "rgba(221,183,255,0.08)",
                border: `1px solid rgba(221,183,255,0.2)`,
                flexShrink: 0,
              }}
            >
              {user.role}
            </span>
          </div>
        )}

        <button
          onClick={handleLogout}
          style={{
            width: "100%",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: "8px",
            padding: "9px 16px",
            fontFamily: "'Zen Dots', sans-serif",
            fontSize: "10px",
            fontWeight: 400,
            textTransform: "uppercase",
            letterSpacing: "0.12em",
            color: C.muted,
            background: "rgba(255,255,255,0.02)",
            border: `1px solid ${C.border}`,
            cursor: "pointer",
            transition: "all 0.2s",
          }}
          onMouseEnter={(e) => {
            e.currentTarget.style.color = "#ff5252";
            e.currentTarget.style.borderColor = "rgba(255,82,82,0.3)";
            e.currentTarget.style.background = "rgba(255,82,82,0.05)";
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.color = C.muted;
            e.currentTarget.style.borderColor = C.border;
            e.currentTarget.style.background = "rgba(255,255,255,0.02)";
          }}
        >
          <LogOut size={13} />
          Sign Out
        </button>

        <div
          style={{
            marginTop: "10px",
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
          }}
        >
          <span style={{ fontFamily: "'Zen Dots', sans-serif", fontSize: "8px", color: C.subtle, letterSpacing: "0.1em" }}>MODE: DEV_STANDBY</span>
          <div style={{ display: "flex", alignItems: "center", gap: "4px" }}>
            <span
              style={{ width: "5px", height: "5px", background: C.violet, display: "inline-block" }}
              className="animate-data-blink"
            />
            <span style={{ fontFamily: "'Zen Dots', sans-serif", fontSize: "8px", color: C.subtle, letterSpacing: "0.1em" }}>LIVE</span>
          </div>
        </div>
      </div>
    </aside>
  );
}
