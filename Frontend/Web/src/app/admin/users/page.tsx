"use client";

import { useState } from "react";
import Sidebar from "@/components/Sidebar";
import {
  Users,
  Search,
  MapPin,
  ShieldCheck,
  ShieldOff,
  Trash2,
  Activity,
  Eye,
  ChevronDown,
  X,
  AlertTriangle,
  CheckCircle,
  UserX,
} from "lucide-react";

/* ─── Types ──────────────────────────────────────────────── */
type UserStatus = "active" | "offline" | "banned";

interface ManagedUser {
  id: string;
  name: string;
  email: string;
  role: "rider" | "admin";
  status: UserStatus;
  location: string;
  coordinates: { lat: number; lng: number };
  lastActive: string;
  safetyScore: number;
  totalRides: number;
  joinDate: string;
  helmet: string;
  deviceId: string;
}

/* ─── Mock Data ──────────────────────────────────────────── */
const initialUsers: ManagedUser[] = [
  {
    id: "USR-001",
    name: "Rider Neo",
    email: "neo@argusx.io",
    role: "rider",
    status: "active",
    location: "San Francisco, CA",
    coordinates: { lat: 37.7749, lng: -122.4194 },
    lastActive: "Now",
    safetyScore: 96,
    totalRides: 142,
    joinDate: "2026-01-15",
    helmet: "AGV SportModular Carbon",
    deviceId: "AX-091",
  },
  {
    id: "USR-002",
    name: "Rider Trinity",
    email: "trinity@argusx.io",
    role: "rider",
    status: "active",
    location: "Los Angeles, CA",
    coordinates: { lat: 34.0522, lng: -118.2437 },
    lastActive: "Now",
    safetyScore: 100,
    totalRides: 89,
    joinDate: "2026-02-08",
    helmet: "Shoei RF-1400 SmartSentry",
    deviceId: "AX-042",
  },
  {
    id: "USR-003",
    name: "Rider Morpheus",
    email: "morpheus@argusx.io",
    role: "rider",
    status: "active",
    location: "Austin, TX",
    coordinates: { lat: 30.2672, lng: -97.7431 },
    lastActive: "Now",
    safetyScore: 78,
    totalRides: 267,
    joinDate: "2025-11-20",
    helmet: "Arai Regent-X Edge",
    deviceId: "AX-108",
  },
  {
    id: "USR-004",
    name: "Rider Cypher",
    email: "cypher@argusx.io",
    role: "rider",
    status: "offline",
    location: "Miami, FL",
    coordinates: { lat: 25.7617, lng: -80.1918 },
    lastActive: "2 hours ago",
    safetyScore: 82,
    totalRides: 34,
    joinDate: "2026-04-01",
    helmet: "AGV SportModular Carbon",
    deviceId: "AX-007",
  },
  {
    id: "USR-005",
    name: "Rider Niobe",
    email: "niobe@argusx.io",
    role: "rider",
    status: "offline",
    location: "Seattle, WA",
    coordinates: { lat: 47.6062, lng: -122.3321 },
    lastActive: "1 day ago",
    safetyScore: 91,
    totalRides: 56,
    joinDate: "2026-03-12",
    helmet: "Shoei RF-1400 SmartSentry",
    deviceId: "AX-055",
  },
  {
    id: "USR-006",
    name: "Rider Tank",
    email: "tank@argusx.io",
    role: "rider",
    status: "banned",
    location: "New York, NY",
    coordinates: { lat: 40.7128, lng: -74.006 },
    lastActive: "5 days ago",
    safetyScore: 45,
    totalRides: 12,
    joinDate: "2026-05-01",
    helmet: "Arai Regent-X Edge",
    deviceId: "AX-099",
  },
  {
    id: "USR-007",
    name: "Rider Switch",
    email: "switch@argusx.io",
    role: "rider",
    status: "active",
    location: "Chicago, IL",
    coordinates: { lat: 41.8781, lng: -87.6298 },
    lastActive: "Now",
    safetyScore: 88,
    totalRides: 73,
    joinDate: "2026-01-28",
    helmet: "AGV SportModular Carbon",
    deviceId: "AX-033",
  },
  {
    id: "USR-008",
    name: "Rider Dozer",
    email: "dozer@argusx.io",
    role: "rider",
    status: "offline",
    location: "Denver, CO",
    coordinates: { lat: 39.7392, lng: -104.9903 },
    lastActive: "3 hours ago",
    safetyScore: 93,
    totalRides: 101,
    joinDate: "2025-12-05",
    helmet: "Shoei RF-1400 SmartSentry",
    deviceId: "AX-071",
  },
];

/* ─── Component ──────────────────────────────────────────── */
export default function UserManagement() {
  const [users, setUsers] = useState<ManagedUser[]>(initialUsers);
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState<"ALL" | UserStatus>("ALL");
  const [expandedUserId, setExpandedUserId] = useState<string | null>(null);

  // Confirmation modal state
  const [modal, setModal] = useState<{
    type: "ban" | "unban" | "delete";
    user: ManagedUser;
  } | null>(null);

  /* ── Filtering ── */
  const filteredUsers = users.filter((u) => {
    const matchesSearch =
      u.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      u.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
      u.id.toLowerCase().includes(searchTerm.toLowerCase()) ||
      u.location.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus =
      statusFilter === "ALL" ? true : u.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const activeCount = users.filter((u) => u.status === "active").length;
  const totalCount = users.length;
  const bannedCount = users.filter((u) => u.status === "banned").length;

  /* ── Actions ── */
  const handleBan = (userId: string) => {
    setUsers((prev) =>
      prev.map((u) =>
        u.id === userId ? { ...u, status: "banned" as UserStatus } : u
      )
    );
    setModal(null);
  };

  const handleUnban = (userId: string) => {
    setUsers((prev) =>
      prev.map((u) =>
        u.id === userId ? { ...u, status: "offline" as UserStatus } : u
      )
    );
    setModal(null);
  };

  const handleDelete = (userId: string) => {
    setUsers((prev) => prev.filter((u) => u.id !== userId));
    setExpandedUserId(null);
    setModal(null);
  };

  /* ── Status helpers ── */
  const getStatusDot = (status: UserStatus) => {
    if (status === "active") return "status-online";
    if (status === "banned") return "status-banned";
    return "status-offline";
  };

  const getStatusLabel = (status: UserStatus) => {
    if (status === "active") return "ONLINE";
    if (status === "banned") return "BANNED";
    return "OFFLINE";
  };

  const getStatusColor = (status: UserStatus) => {
    if (status === "active") return "text-accent-green";
    if (status === "banned") return "text-accent-red";
    return "text-slate-500";
  };

  const getScoreColor = (score: number) => {
    if (score >= 90) return "text-accent-green";
    if (score >= 75) return "text-accent-yellow";
    return "text-accent-red";
  };

  return (
    <div className="flex flex-row min-h-screen">
      <Sidebar />

      <main className="flex-1 flex flex-col min-w-0 overflow-y-auto p-8 relative z-10">
        {/* Header */}
        <header className="flex flex-col md:flex-row md:items-center md:justify-between pb-6 border-b border-white/5 mb-8 gap-4">
          <div>
            <h1 className="font-title text-3xl font-black tracking-wide text-white">
              User Management
            </h1>
            <p className="text-xs text-slate-400 mt-1">
              Registered Operators — Profiles, Locations, Status &amp; Access
              Controls
            </p>
          </div>
          <div className="flex items-center gap-3 text-xs font-mono">
            <div className="glass-panel border border-white/5 px-4 py-2 rounded-lg flex items-center gap-2 text-slate-300">
              <span className="w-2 h-2 rounded-full bg-accent-green animate-pulse" />
              {activeCount} ACTIVE
            </div>
            <div className="glass-panel border border-white/5 px-4 py-2 rounded-lg flex items-center gap-2 text-slate-300">
              <Users className="w-3.5 h-3.5 text-accent-purple" />
              {totalCount} TOTAL
            </div>
          </div>
        </header>

        {/* Top Stats */}
        <section className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <div className="glass-panel p-5 rounded-2xl border border-white/5">
            <div className="flex justify-between items-start text-slate-400">
              <span className="text-[10px] font-mono uppercase tracking-wider">
                Active Now
              </span>
              <Activity className="w-4 h-4 text-accent-green" />
            </div>
            <div className="text-2xl font-black text-white mt-2 font-title">
              {activeCount}
            </div>
          </div>
          <div className="glass-panel p-5 rounded-2xl border border-white/5">
            <div className="flex justify-between items-start text-slate-400">
              <span className="text-[10px] font-mono uppercase tracking-wider">
                Total Registered
              </span>
              <Users className="w-4 h-4 text-accent-purple" />
            </div>
            <div className="text-2xl font-black text-white mt-2 font-title">
              {totalCount}
            </div>
          </div>
          <div className="glass-panel p-5 rounded-2xl border border-white/5">
            <div className="flex justify-between items-start text-slate-400">
              <span className="text-[10px] font-mono uppercase tracking-wider">
                Banned
              </span>
              <UserX className="w-4 h-4 text-accent-red" />
            </div>
            <div className="text-2xl font-black text-white mt-2 font-title">
              {bannedCount}
            </div>
          </div>
          <div className="glass-panel p-5 rounded-2xl border border-white/5">
            <div className="flex justify-between items-start text-slate-400">
              <span className="text-[10px] font-mono uppercase tracking-wider">
                Locations
              </span>
              <MapPin className="w-4 h-4 text-accent-cyan" />
            </div>
            <div className="text-2xl font-black text-white mt-2 font-title">
              {new Set(users.map((u) => u.location.split(",")[1]?.trim())).size}
            </div>
            <div className="text-[10px] text-slate-500 mt-0.5 font-mono">
              UNIQUE REGIONS
            </div>
          </div>
        </section>

        {/* Search & Filter Bar */}
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
          <div className="relative">
            <Search className="w-4 h-4 text-slate-500 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
            <input
              type="text"
              placeholder="Search name, email, ID, or location…"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="glass-input pl-10 w-80"
            />
          </div>
          <div className="flex items-center gap-3">
            <div className="relative">
              <select
                value={statusFilter}
                onChange={(e) =>
                  setStatusFilter(e.target.value as "ALL" | UserStatus)
                }
                className="bg-black/60 border border-white/10 rounded-lg py-2 pl-3 pr-8 text-xs text-slate-200 focus:border-accent-purple focus:outline-none appearance-none cursor-pointer"
              >
                <option value="ALL" className="bg-slate-900 text-slate-200">
                  ALL STATUS
                </option>
                <option
                  value="active"
                  className="bg-slate-900 text-slate-200"
                >
                  ONLINE
                </option>
                <option
                  value="offline"
                  className="bg-slate-900 text-slate-200"
                >
                  OFFLINE
                </option>
                <option
                  value="banned"
                  className="bg-slate-900 text-slate-200"
                >
                  BANNED
                </option>
              </select>
              <ChevronDown className="w-3.5 h-3.5 text-slate-400 absolute right-2.5 top-1/2 -translate-y-1/2 pointer-events-none" />
            </div>
          </div>
        </div>

        {/* Users Table */}
        <div className="glass-panel rounded-2xl border border-white/5 overflow-hidden flex-1">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs border-collapse">
              <thead>
                <tr className="border-b border-white/10 text-slate-500 font-mono text-[10px] uppercase tracking-wider">
                  <th className="py-3.5 px-5">Operator</th>
                  <th className="py-3.5 px-4">Status</th>
                  <th className="py-3.5 px-4">Location</th>
                  <th className="py-3.5 px-4">Safety Score</th>
                  <th className="py-3.5 px-4">Rides</th>
                  <th className="py-3.5 px-4">Last Active</th>
                  <th className="py-3.5 px-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredUsers.map((user) => {
                  const isExpanded = expandedUserId === user.id;
                  return (
                    <tr key={user.id} className="group">
                      <td colSpan={7} className="p-0">
                        {/* Main Row */}
                        <div
                          className={`flex items-center border-b transition-all duration-200 cursor-pointer hover:bg-white/[0.02] ${
                            isExpanded
                              ? "bg-accent-purple/[0.04] border-accent-purple/10"
                              : "border-white/5"
                          }`}
                          onClick={() =>
                            setExpandedUserId(isExpanded ? null : user.id)
                          }
                        >
                          {/* Operator */}
                          <div className="py-3.5 px-5 flex items-center gap-3 min-w-[220px]">
                            <div className="w-9 h-9 rounded-full bg-gradient-to-br from-accent-purple/30 to-accent-pink/20 flex items-center justify-center text-white text-xs font-bold shrink-0">
                              {user.name
                                .split(" ")
                                .map((n) => n[0])
                                .join("")
                                .slice(0, 2)}
                            </div>
                            <div>
                              <div className="font-bold text-slate-200 text-sm">
                                {user.name}
                              </div>
                              <div className="text-[10px] text-slate-500 font-mono">
                                {user.email}
                              </div>
                            </div>
                          </div>

                          {/* Status */}
                          <div className="py-3.5 px-4 min-w-[100px]">
                            <span className="flex items-center gap-1.5">
                              <span
                                className={`w-2 h-2 rounded-full ${getStatusDot(
                                  user.status
                                )}`}
                              />
                              <span
                                className={`text-[10px] font-bold uppercase tracking-wider ${getStatusColor(
                                  user.status
                                )}`}
                              >
                                {getStatusLabel(user.status)}
                              </span>
                            </span>
                          </div>

                          {/* Location */}
                          <div className="py-3.5 px-4 min-w-[160px]">
                            <span className="flex items-center gap-1.5 text-slate-400">
                              <MapPin className="w-3 h-3 text-slate-500 shrink-0" />
                              {user.location}
                            </span>
                          </div>

                          {/* Safety Score */}
                          <div className="py-3.5 px-4 min-w-[100px]">
                            <span
                              className={`font-bold ${getScoreColor(
                                user.safetyScore
                              )}`}
                            >
                              {user.safetyScore}/100
                            </span>
                          </div>

                          {/* Rides */}
                          <div className="py-3.5 px-4 min-w-[80px] text-slate-300 font-mono">
                            {user.totalRides}
                          </div>

                          {/* Last Active */}
                          <div className="py-3.5 px-4 min-w-[110px] text-slate-400 font-mono text-[11px]">
                            {user.lastActive}
                          </div>

                          {/* Actions */}
                          <div className="py-3.5 px-4 min-w-[140px] flex items-center justify-end gap-2">
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                setExpandedUserId(
                                  isExpanded ? null : user.id
                                );
                              }}
                              className="p-1.5 rounded-lg hover:bg-white/5 text-slate-500 hover:text-slate-300 transition-colors"
                              title="View details"
                            >
                              <Eye className="w-3.5 h-3.5" />
                            </button>
                            {user.status === "banned" ? (
                              <button
                                onClick={(e) => {
                                  e.stopPropagation();
                                  setModal({ type: "unban", user });
                                }}
                                className="p-1.5 rounded-lg hover:bg-accent-green/10 text-slate-500 hover:text-accent-green transition-colors"
                                title="Unban user"
                              >
                                <ShieldCheck className="w-3.5 h-3.5" />
                              </button>
                            ) : (
                              <button
                                onClick={(e) => {
                                  e.stopPropagation();
                                  setModal({ type: "ban", user });
                                }}
                                className="p-1.5 rounded-lg hover:bg-accent-yellow/10 text-slate-500 hover:text-accent-yellow transition-colors"
                                title="Ban user"
                              >
                                <ShieldOff className="w-3.5 h-3.5" />
                              </button>
                            )}
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                setModal({ type: "delete", user });
                              }}
                              className="p-1.5 rounded-lg hover:bg-accent-red/10 text-slate-500 hover:text-accent-red transition-colors"
                              title="Delete user"
                            >
                              <Trash2 className="w-3.5 h-3.5" />
                            </button>
                          </div>
                        </div>

                        {/* Expanded Detail */}
                        {isExpanded && (
                          <div className="px-5 py-5 bg-white/[0.01] border-b border-accent-purple/10">
                            <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
                              <div>
                                <div className="text-[10px] text-slate-500 font-mono uppercase mb-1">
                                  Device ID
                                </div>
                                <div className="text-sm font-bold text-accent-purple font-mono">
                                  {user.deviceId}
                                </div>
                              </div>
                              <div>
                                <div className="text-[10px] text-slate-500 font-mono uppercase mb-1">
                                  Helmet Model
                                </div>
                                <div className="text-sm font-bold text-slate-200">
                                  {user.helmet}
                                </div>
                              </div>
                              <div>
                                <div className="text-[10px] text-slate-500 font-mono uppercase mb-1">
                                  Join Date
                                </div>
                                <div className="text-sm font-bold text-slate-200 font-mono">
                                  {user.joinDate}
                                </div>
                              </div>
                              <div>
                                <div className="text-[10px] text-slate-500 font-mono uppercase mb-1">
                                  Coordinates
                                </div>
                                <div className="text-sm font-bold text-slate-200 font-mono">
                                  {user.coordinates.lat},{" "}
                                  {user.coordinates.lng}
                                </div>
                              </div>
                            </div>

                            {/* Safety Score Bar */}
                            <div className="mt-5">
                              <div className="flex justify-between text-[10px] font-mono text-slate-500 mb-2">
                                <span>SAFETY PERFORMANCE INDEX</span>
                                <span
                                  className={`font-bold ${getScoreColor(
                                    user.safetyScore
                                  )}`}
                                >
                                  {user.safetyScore}%
                                </span>
                              </div>
                              <div className="w-full h-2 bg-white/[0.03] rounded-full overflow-hidden border border-white/5">
                                <div
                                  className="h-full bg-gradient-to-r from-accent-purple to-accent-cyan rounded-full transition-all duration-500"
                                  style={{
                                    width: `${user.safetyScore}%`,
                                  }}
                                />
                              </div>
                            </div>
                          </div>
                        )}
                      </td>
                    </tr>
                  );
                })}

                {filteredUsers.length === 0 && (
                  <tr>
                    <td
                      colSpan={7}
                      className="text-center py-12 text-slate-600 italic"
                    >
                      No matching operators found.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* Footer */}
        <div className="mt-4 flex items-center justify-between text-[10px] text-slate-600 font-mono px-1">
          <span>
            SHOWING {filteredUsers.length} OF {totalCount} OPERATORS
          </span>
          <span>DATABASE: SUPABASE_POSTGRES</span>
        </div>
      </main>

      {/* ── Confirmation Modal ────────────────────────────── */}
      {modal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm">
          <div className="glass-panel-purple p-8 rounded-2xl border border-white/10 max-w-md w-full mx-4 animate-fade-in-up">
            {/* Close */}
            <button
              onClick={() => setModal(null)}
              className="absolute top-4 right-4 text-slate-500 hover:text-white transition-colors"
            >
              <X className="w-4 h-4" />
            </button>

            {/* Icon */}
            <div className="flex justify-center mb-4">
              <div
                className={`w-14 h-14 rounded-full flex items-center justify-center ${
                  modal.type === "delete"
                    ? "bg-accent-red/10 border border-accent-red/20"
                    : modal.type === "ban"
                    ? "bg-accent-yellow/10 border border-accent-yellow/20"
                    : "bg-accent-green/10 border border-accent-green/20"
                }`}
              >
                {modal.type === "delete" ? (
                  <Trash2 className="w-6 h-6 text-accent-red" />
                ) : modal.type === "ban" ? (
                  <AlertTriangle className="w-6 h-6 text-accent-yellow" />
                ) : (
                  <CheckCircle className="w-6 h-6 text-accent-green" />
                )}
              </div>
            </div>

            <h3 className="text-center text-lg font-bold text-white mb-2">
              {modal.type === "delete"
                ? "Delete Operator"
                : modal.type === "ban"
                ? "Ban Operator"
                : "Unban Operator"}
            </h3>
            <p className="text-center text-xs text-slate-400 mb-6 leading-relaxed">
              {modal.type === "delete"
                ? `Permanently remove ${modal.user.name} (${modal.user.id}) from the system. This action cannot be undone.`
                : modal.type === "ban"
                ? `Suspend ${modal.user.name} (${modal.user.id}) from the ArgusX platform. They will lose access to the HUD and portal.`
                : `Restore access for ${modal.user.name} (${modal.user.id}). They will regain access to the HUD and portal.`}
            </p>

            <div className="flex items-center gap-3">
              <button
                onClick={() => setModal(null)}
                className="btn-ghost flex-1 py-2.5"
              >
                Cancel
              </button>
              <button
                onClick={() => {
                  if (modal.type === "delete") handleDelete(modal.user.id);
                  else if (modal.type === "ban") handleBan(modal.user.id);
                  else handleUnban(modal.user.id);
                }}
                className={`flex-1 py-2.5 rounded-lg text-xs font-bold transition-all ${
                  modal.type === "delete"
                    ? "btn-danger"
                    : modal.type === "ban"
                    ? "bg-accent-yellow/20 border border-accent-yellow/30 text-accent-yellow hover:bg-accent-yellow/30"
                    : "bg-accent-green/20 border border-accent-green/30 text-accent-green hover:bg-accent-green/30"
                }`}
              >
                {modal.type === "delete"
                  ? "Delete Permanently"
                  : modal.type === "ban"
                  ? "Ban Operator"
                  : "Unban Operator"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
