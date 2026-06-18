"use client";

import { useEffect, useRef } from "react";
import Link from "next/link";
import Sidebar from "@/components/Sidebar";
import { useAuth } from "@/lib/AuthContext";
import { motion, type Variants } from "framer-motion";
import { gsap } from "gsap";
import {
  Award,
  Activity,
  Navigation,
  ShieldCheck,
  ArrowRight,
  Zap,
  User,
} from "lucide-react";

/* ── Reusable GSAP Count-up component ── */
function Counter({ value, suffix = "" }: { value: number | string; suffix?: string }) {
  const elRef = useRef<HTMLSpanElement>(null);

  useEffect(() => {
    const el = elRef.current;
    if (!el) return;

    // Clean commas for parsing
    const rawValStr = typeof value === "string" ? value.replace(/,/g, "") : value.toString();
    const rawNum = parseFloat(rawValStr);
    const hasDecimal = rawValStr.includes(".") || (typeof value === "number" && value % 1 !== 0);
    const obj = { val: 0 };

    const tween = gsap.to(obj, {
      val: rawNum,
      duration: 1.5,
      ease: "power2.out",
      onUpdate: () => {
        if (el) {
          let formatted = hasDecimal ? obj.val.toFixed(1) : Math.floor(obj.val).toString();
          if (typeof value === "string" && value.includes(",")) {
            formatted = Math.floor(obj.val).toLocaleString("en-US");
          } else if (rawNum >= 1000) {
            formatted = Math.floor(obj.val).toLocaleString("en-US");
          }
          el.innerText = formatted + suffix;
        }
      }
    });

    return () => { tween.kill(); };
  }, [value, suffix]);

  return <span ref={elRef}>0{suffix}</span>;
}

export default function UserDashboard() {
  const { user } = useAuth();
  const displayName = user?.name ?? "Rider";

  const containerVariants: Variants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.08,
        delayChildren: 0.1,
      }
    }
  };

  const itemVariants: Variants = {
    hidden: { opacity: 0, y: 15 },
    visible: {
      opacity: 1,
      y: 0,
      transition: { type: "spring" as const, stiffness: 100, damping: 15 }
    }
  };

  return (
    <div className="flex flex-row min-h-screen">
      <Sidebar />

      <motion.main
        variants={containerVariants}
        initial="hidden"
        animate="visible"
        className="flex-1 flex flex-col min-w-0 overflow-y-auto p-8 relative z-10"
      >
        {/* Hero Welcome */}
        <motion.header
          variants={itemVariants}
          className="pb-8 border-b border-white/5 mb-8 relative overflow-hidden rounded-none glass-panel tech-panel-purple p-8"
        >
          <div className="absolute top-0 right-0 w-64 h-64 bg-accent-purple/10 rounded-none blur-[80px] pointer-events-none" />
          <div className="relative z-10">
            <div className="flex items-center gap-4 mb-4">
              <div className="w-16 h-16 rounded-none bg-gradient-to-br from-accent-purple to-accent-pink p-[2px]">
                <div className="w-full h-full bg-black rounded-none flex items-center justify-center text-xl font-black text-white font-title">
                  {displayName.charAt(0)}
                </div>
              </div>
              <div>
                <h1 className="font-title text-2xl sm:text-3xl font-black tracking-wide text-white">
                  Welcome back, {displayName}
                </h1>
                <p className="text-xs text-slate-400 mt-1 font-mono uppercase tracking-wider">
                  SESSION: ACTIVE — TIER 1 RIDER INTEGRATION
                </p>
              </div>
            </div>

            {/* Quick Stats Row */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mt-6">
              <div className="bg-white/[0.03] border border-white/5 rounded-none p-4">
                <div className="text-[10px] text-slate-300 font-title uppercase tracking-wider">
                  Safety Score
                </div>
                <div className="text-2xl font-black text-accent-green mt-1 font-title">
                  <Counter value={96} />
                </div>
              </div>
              <div className="bg-white/[0.03] border border-white/5 rounded-none p-4">
                <div className="text-[10px] text-slate-300 font-title uppercase tracking-wider">
                  Total Rides
                </div>
                <div className="text-2xl font-black text-white mt-1 font-title">
                  <Counter value={142} />
                </div>
              </div>
              <div className="bg-white/[0.03] border border-white/5 rounded-none p-4">
                <div className="text-[10px] text-slate-300 font-title uppercase tracking-wider">
                  Miles Logged
                </div>
                <div className="text-2xl font-black text-white mt-1 font-title">
                  <Counter value="1,248" />
                </div>
              </div>
              <div className="bg-white/[0.03] border border-white/5 rounded-none p-4">
                <div className="text-[10px] text-slate-300 font-title uppercase tracking-wider">
                  Interventions
                </div>
                <div className="text-2xl font-black text-accent-purple mt-1 font-title">
                  <Counter value={18} />
                </div>
              </div>
            </div>
          </div>
        </motion.header>

        {/* Navigation Cards */}
        <motion.section
          variants={containerVariants}
          className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8"
        >
          {/* Card 1 */}
          <motion.div
            variants={itemVariants}
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            className="flex"
          >
            <Link
              href="/user/analytics"
              className="w-full glass-panel tech-panel p-6 rounded-none border border-white/5 hover:border-accent-cyan/30 transition-all duration-300 group flex flex-col justify-between gap-4"
            >
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-none bg-accent-cyan/10 flex items-center justify-center group-hover:bg-accent-cyan/20 transition-colors">
                  <Activity className="w-5 h-5 text-accent-cyan" />
                </div>
                <div>
                  <h3 className="font-bold text-white text-sm group-hover:text-accent-cyan transition-colors font-title tracking-wide">
                    Ride Analytics
                  </h3>
                  <p className="text-[11px] text-slate-500 mt-0.5 font-sans">
                    HUD settings &amp; performance metrics
                  </p>
                </div>
              </div>
              <div className="flex items-center gap-1 text-[11px] text-accent-cyan font-bold font-mono">
                <span>View Dashboard</span>
                <ArrowRight className="w-3.5 h-3.5 group-hover:translate-x-1 transition-transform" />
              </div>
            </Link>
          </motion.div>

          {/* Card 2 */}
          <motion.div
            variants={itemVariants}
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            className="flex"
          >
            <Link
              href="/user/profile"
              className="w-full glass-panel tech-panel p-6 rounded-none border border-white/5 hover:border-accent-cyan/30 transition-all duration-300 group flex flex-col justify-between gap-4"
            >
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-none bg-accent-cyan/10 flex items-center justify-center group-hover:bg-accent-cyan/20 transition-colors">
                  <User className="w-5 h-5 text-accent-cyan" />
                </div>
                <div>
                  <h3 className="font-bold text-white text-sm group-hover:text-accent-cyan transition-colors font-title tracking-wide">
                    Profile &amp; Account
                  </h3>
                  <p className="text-[11px] text-slate-500 mt-0.5 font-sans">
                    Personal info, email &amp; preferences
                  </p>
                </div>
              </div>
              <div className="flex items-center gap-1 text-[11px] text-accent-cyan font-bold font-mono">
                <span>Edit Profile</span>
                <ArrowRight className="w-3.5 h-3.5 group-hover:translate-x-1 transition-transform" />
              </div>
            </Link>
          </motion.div>

          {/* Card 3 (disabled/coming soon) */}
          <motion.div
            variants={itemVariants}
            className="glass-panel tech-panel p-6 rounded-none border border-white/5 flex flex-col justify-between gap-4 opacity-50 select-none"
          >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-none bg-accent-pink/10 flex items-center justify-center">
                <Navigation className="w-5 h-5 text-accent-pink" />
              </div>
              <div>
                <h3 className="font-bold text-white text-sm font-title tracking-wide">
                  Ride History Map
                </h3>
                <p className="text-[11px] text-slate-500 mt-0.5 font-sans">
                  Spatial routes &amp; safety heatmaps
                </p>
              </div>
            </div>
            <div className="flex items-center gap-1 text-[11px] text-slate-500 font-bold font-mono">
              COMING SOON
            </div>
          </motion.div>
        </motion.section>

        {/* Recent Activity */}
        <motion.section
          variants={itemVariants}
          className="glass-panel tech-panel p-6 rounded-none border border-white/5"
        >
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
                className="flex items-center justify-between py-3 px-4 bg-white/[0.01] border border-white/5 rounded-none hover:bg-white/[0.03] transition-all"
              >
                <div className="flex items-center gap-4">
                  <div className="w-8 h-8 rounded-none bg-accent-purple/10 flex items-center justify-center">
                    <ShieldCheck className="w-4 h-4 text-accent-purple" />
                  </div>
                  <div>
                    <div className="text-sm font-bold text-slate-200 font-sans">
                      {ride.date}
                    </div>
                    <div className="text-[10px] text-slate-500 font-mono">
                      Duration: {ride.duration} • Threats: {ride.threats}
                    </div>
                  </div>
                </div>
                <span
                  className={`font-bold text-sm font-mono ${
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
        </motion.section>
      </motion.main>
    </div>
  );
}
