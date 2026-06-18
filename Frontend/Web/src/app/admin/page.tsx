"use client";

import { useEffect, useRef } from "react";
import Link from "next/link";
import Sidebar from "@/components/Sidebar";
import { motion, Variants } from "framer-motion";
import { gsap } from "gsap";
import {
  Users,
  Map,
  LineChart,
  ShieldCheck,
  Activity,
  Zap,
  AlertTriangle,
  ArrowRight,
} from "lucide-react";

/* ── Reusable GSAP Count-up component ── */
function Counter({ value, suffix = "" }: { value: number | string; suffix?: string }) {
  const elRef = useRef<HTMLSpanElement>(null);

  useEffect(() => {
    const el = elRef.current;
    if (!el) return;

    const rawNum = typeof value === "string" ? parseFloat(value) : value;
    const hasDecimal = typeof value === "string" && value.includes(".") || (typeof value === "number" && value % 1 !== 0);
    const obj = { val: 0 };

    const tween = gsap.to(obj, {
      val: rawNum,
      duration: 1.5,
      ease: "power2.out",
      onUpdate: () => {
        if (el) {
          el.innerText = hasDecimal ? obj.val.toFixed(1) + suffix : Math.floor(obj.val) + suffix;
        }
      }
    });

    return () => { tween.kill(); };
  }, [value, suffix]);

  return <span ref={elRef}>0{suffix}</span>;
}

export default function AdminDashboard() {
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
        {/* Header */}
        <motion.header
          variants={itemVariants}
          className="flex flex-col md:flex-row md:items-center md:justify-between pb-6 border-b border-white/5 mb-8 gap-4"
        >
          <div>
            <h1 className="font-title text-3xl font-black tracking-wide text-white">
              Command Center
            </h1>
            <p className="text-xs text-slate-400 mt-1 font-mono uppercase tracking-wider">
              Administrative Overview — Real-Time Fleet Intelligence &amp; System Monitoring
            </p>
          </div>
          <div className="glass-panel tech-panel border border-white/5 px-4 py-2 rounded-none text-xs flex items-center gap-2 text-slate-300 font-mono">
            <span className="w-2 h-2 rounded-none bg-accent-green animate-pulse" />
            ALL SYSTEMS NOMINAL
          </div>
        </motion.header>

        {/* Top Summary Cards */}
        <motion.section
          variants={containerVariants}
          className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8"
        >
          {/* Card 1 */}
          <motion.div
            variants={itemVariants}
            className="glass-panel tech-panel p-6 rounded-none border border-white/5"
          >
            <div className="flex justify-between items-start text-slate-400">
              <span className="text-xs font-title uppercase tracking-wider">
                Active Operators
              </span>
              <Users className="w-4 h-4 text-accent-purple" />
            </div>
            <div className="text-3xl font-black text-white mt-3 font-title">
              <Counter value={3} />
            </div>
            <div className="text-[10px] text-accent-green mt-1.5 font-bold flex items-center gap-1 font-mono">
              <span className="w-1.5 h-1.5 rounded-none bg-accent-green animate-pulse" />
              LIVE CONNECTIONS
            </div>
          </motion.div>

          {/* Card 2 */}
          <motion.div
            variants={itemVariants}
            className="glass-panel tech-panel p-6 rounded-none border border-white/5"
          >
            <div className="flex justify-between items-start text-slate-400">
              <span className="text-xs font-title uppercase tracking-wider">
                Registered Riders
              </span>
              <ShieldCheck className="w-4 h-4 text-accent-cyan" />
            </div>
            <div className="text-3xl font-black text-white mt-3 font-title">
              <Counter value={18} />
            </div>
            <div className="text-[10px] text-slate-500 mt-1.5 font-mono">
              IN DATABASE
            </div>
          </motion.div>

          {/* Card 3 */}
          <motion.div
            variants={itemVariants}
            className="glass-panel tech-panel p-6 rounded-none border border-white/5"
          >
            <div className="flex justify-between items-start text-slate-400">
              <span className="text-xs font-title uppercase tracking-wider">
                Threats Today
              </span>
              <AlertTriangle className="w-4 h-4 text-accent-yellow" />
            </div>
            <div className="text-3xl font-black text-white mt-3 font-title">
              <Counter value={12} />
            </div>
            <div className="text-[10px] text-accent-yellow mt-1.5 font-bold font-mono">
              2 CRITICAL / 10 WARNING
            </div>
          </motion.div>

          {/* Card 4 */}
          <motion.div
            variants={itemVariants}
            className="glass-panel tech-panel p-6 rounded-none border border-white/5"
          >
            <div className="flex justify-between items-start text-slate-400">
              <span className="text-xs font-title uppercase tracking-wider">
                System Uptime
              </span>
              <Activity className="w-4 h-4 text-accent-green" />
            </div>
            <div className="text-3xl font-black text-white mt-3 font-title">
              <Counter value={99.7} suffix="%" />
            </div>
            <div className="text-[10px] text-accent-cyan mt-1.5 font-bold font-mono">
              14 DAYS CONTINUOUS
            </div>
          </motion.div>
        </motion.section>

        {/* Quick Navigation Grid */}
        <motion.section
          variants={containerVariants}
          className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8"
        >
          {/* Nav Card 1 */}
          <motion.div
            variants={itemVariants}
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            className="flex"
          >
            <Link
              href="/admin/fleet-tracking"
              className="w-full glass-panel tech-panel p-6 rounded-none border border-white/5 hover:border-accent-purple/30 transition-all duration-300 group flex flex-col justify-between gap-4"
            >
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-none bg-accent-purple/10 flex items-center justify-center group-hover:bg-accent-purple/20 transition-colors">
                  <Map className="w-5 h-5 text-accent-purple" />
                </div>
                <div>
                  <h3 className="font-bold text-white text-sm group-hover:text-accent-purple transition-colors font-title tracking-wide">
                    Fleet Tracker
                  </h3>
                  <p className="text-[11px] text-slate-500 mt-0.5 font-sans">
                    Live spatial telemetry &amp; rider positions
                  </p>
                </div>
              </div>
              <div className="flex items-center gap-1 text-[11px] text-accent-purple font-bold font-mono">
                <span>Open Station</span>
                <ArrowRight className="w-3.5 h-3.5 group-hover:translate-x-1 transition-transform" />
              </div>
            </Link>
          </motion.div>

          {/* Nav Card 2 */}
          <motion.div
            variants={itemVariants}
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            className="flex"
          >
            <Link
              href="/admin/analytics"
              className="w-full glass-panel tech-panel p-6 rounded-none border border-white/5 hover:border-accent-cyan/30 transition-all duration-300 group flex flex-col justify-between gap-4"
            >
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-none bg-accent-cyan/10 flex items-center justify-center group-hover:bg-accent-cyan/20 transition-colors">
                  <LineChart className="w-5 h-5 text-accent-cyan" />
                </div>
                <div>
                  <h3 className="font-bold text-white text-sm group-hover:text-accent-cyan transition-colors font-title tracking-wide">
                    System Analytics
                  </h3>
                  <p className="text-[11px] text-slate-500 mt-0.5 font-sans">
                    Safety databases &amp; performance stats
                  </p>
                </div>
              </div>
              <div className="flex items-center gap-1 text-[11px] text-accent-cyan font-bold font-mono">
                <span>View Reports</span>
                <ArrowRight className="w-3.5 h-3.5 group-hover:translate-x-1 transition-transform" />
              </div>
            </Link>
          </motion.div>

          {/* Nav Card 3 */}
          <motion.div
            variants={itemVariants}
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            className="flex"
          >
            <Link
              href="/admin/users"
              className="w-full glass-panel tech-panel p-6 rounded-none border border-white/5 hover:border-accent-pink/30 transition-all duration-300 group flex flex-col justify-between gap-4"
            >
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-none bg-accent-pink/10 flex items-center justify-center group-hover:bg-accent-pink/20 transition-colors">
                  <Users className="w-5 h-5 text-accent-pink" />
                </div>
                <div>
                  <h3 className="font-bold text-white text-sm group-hover:text-accent-pink transition-colors font-title tracking-wide">
                    User Management
                  </h3>
                  <p className="text-[11px] text-slate-500 mt-0.5 font-sans">
                    Operators, bans, profiles &amp; locations
                  </p>
                </div>
              </div>
              <div className="flex items-center gap-1 text-[11px] text-accent-pink font-bold font-mono">
                <span>Manage Users</span>
                <ArrowRight className="w-3.5 h-3.5 group-hover:translate-x-1 transition-transform" />
              </div>
            </Link>
          </motion.div>
        </motion.section>

        {/* Live System Status Panel */}
        <motion.section
          variants={itemVariants}
          className="glass-panel tech-panel p-6 rounded-none border border-white/5"
        >
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
                className="bg-white/[0.01] border border-white/5 rounded-none p-4 flex items-center justify-between"
              >
                <span className="text-xs text-slate-400 font-sans">{svc.name}</span>
                <span
                  className={`flex items-center gap-1.5 text-[10px] font-bold font-mono ${svc.color}`}
                >
                  <span
                    className={`w-1.5 h-1.5 rounded-none ${svc.dotColor} animate-pulse`}
                  />
                  {svc.status}
                </span>
              </div>
            ))}
          </div>
        </motion.section>
      </motion.main>
    </div>
  );
}
