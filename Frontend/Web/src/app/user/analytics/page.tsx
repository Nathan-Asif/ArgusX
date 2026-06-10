"use client";

import { useState, useEffect } from "react";
import Sidebar from "@/components/Sidebar";
import { useAuth } from "@/lib/AuthContext";
import { supabase } from "@/lib/supabase";
import { 
  User, 
  Settings, 
  ShieldCheck, 
  Volume2, 
  Eye, 
  Sliders,
  Zap,
  Activity,
  Award,
  ChevronDown,
  Database,
  Search,
  CheckCircle,
  Save,
  Loader2
} from "lucide-react";

interface RideRecord {
  id: string;
  session_id: string;
  started_at: string;
  duration_s: number | null;
  avg_speed_kmh: number | null;
  threats_count: number;
  safety_score: number | null;
  status: string;
  distance_m: number | null;
}

interface ProfileStats {
  safety_score: number;
  total_rides: number;
}

function formatDuration(seconds: number | null): string {
  if (!seconds) return "—";
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  if (h > 0) return `${h} hr ${m} mins`;
  return `${m} mins`;
}

function formatDistance(meters: number | null): string {
  if (!meters) return "—";
  return `${(meters / 1000).toFixed(1)} km`;
}

export default function UserAnalytics() {
  const { user, updateUser } = useAuth();

  const [rides, setRides] = useState<RideRecord[]>([]);
  const [profileStats, setProfileStats] = useState<ProfileStats | null>(null);
  const [loading, setLoading] = useState(true);

  // HUD settings (local UI state only — not yet persisted to DB)
  const [hudSensitivity, setHudSensitivity] = useState(75);
  const [audioAlerts, setAudioAlerts] = useState(true);
  const [sentryVision, setSentryVision] = useState(true);
  const [uiThemeColor, setUiThemeColor] = useState("VIOLET");
  const [profileName, setProfileName] = useState(user?.name ?? "");
  const [selectedHelmet, setSelectedHelmet] = useState("AGV SportModular Carbon");
  
  const [saved, setSaved] = useState(false);
  const [searchTerm, setSearchTerm] = useState("");
  const [filterType, setFilterType] = useState<"ALL" | "COMPLETED" | "FLAGGED">("ALL");

  // Sync name from auth context
  useEffect(() => {
    if (user?.name) setProfileName(user.name);
  }, [user]);

  // Fetch live data from Supabase
  useEffect(() => {
    const client = supabase;
    if (!user?.id || !client) {
      setLoading(false);
      return;
    }

    const fetchData = async () => {
      setLoading(true);
      const [ridesRes, profileRes] = await Promise.all([
        client
          .from("rides")
          .select("id, session_id, started_at, duration_s, avg_speed_kmh, threats_count, safety_score, status, distance_m")
          .eq("user_id", user.id)
          .order("started_at", { ascending: false })
          .limit(50),
        client
          .from("profiles")
          .select("safety_score, total_rides")
          .eq("id", user.id)
          .single(),
      ]);

      if (ridesRes.data) setRides(ridesRes.data as RideRecord[]);
      if (profileRes.data) setProfileStats(profileRes.data as ProfileStats);
      setLoading(false);
    };

    fetchData();
  }, [user?.id]);

  const handleSave = async () => {
    await updateUser({ name: profileName });
    setSaved(true);
    setTimeout(() => setSaved(false), 2500);
  };

  const rideStatusLabel = (status: string): "COMPLETED" | "FLAGGED" =>
    status === "completed" ? "COMPLETED" : "FLAGGED";

  const filteredRecords = rides.filter((r) => {
    const label = rideStatusLabel(r.status);
    const matchesSearch =
      r.session_id.toLowerCase().includes(searchTerm.toLowerCase()) ||
      r.started_at.includes(searchTerm);
    const matchesFilter = filterType === "ALL" ? true : label === filterType;
    return matchesSearch && matchesFilter;
  });

  const totalThreatInterventions = rides.reduce((sum, r) => sum + (r.threats_count ?? 0), 0);
  const totalDistanceKm = rides.reduce((sum, r) => sum + (r.distance_m ?? 0), 0) / 1000;
  const avgSpeed = rides.length
    ? rides.reduce((sum, r) => sum + (r.avg_speed_kmh ?? 0), 0) / rides.length
    : 0;

  return (
    <div className="flex flex-row min-h-screen">
      <Sidebar />

      {/* Main Content Space */}
      <main className="flex-1 flex flex-col min-w-0 overflow-y-auto p-8 relative z-10">
        
        {/* Header */}
        <header className="flex flex-col md:flex-row md:items-center md:justify-between pb-6 border-b border-white/5 mb-8 gap-4">
          <div>
            <h1 className="font-title text-3xl font-black tracking-wide text-white">
              Ride Analytics & HUD Portal
            </h1>
            <p className="text-xs text-slate-400 mt-1">
              Configure HUD preferences, calibrate spatial RAG triggers, and view your historical ride records
            </p>
          </div>

          <div className="flex items-center gap-3">
            <div className="glass-panel tech-panel border border-white/5 px-4 py-2 rounded-none text-xs flex items-center gap-2 text-slate-300">
              <User className="w-4 h-4 text-accent-cyan" />
              <span>Session: <span className="font-bold font-title uppercase">{user?.name ? `${user.name.replace(/\s+/g, '_')}_SECURE` : 'NEO_SECURE'}</span></span>
            </div>
          </div>
        </header>

        {/* Layout Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 mb-8">
          
          {/* Left Grid: Personal Telemetry & Onboarding Profiles (5 Cols) */}
          <div className="lg:col-span-5 flex flex-col gap-6">
            
            {/* Personal Score Summary */}
            <div className="glass-panel tech-panel p-6 rounded-none border border-white/5 relative overflow-hidden">
              <div className="absolute top-0 right-0 w-24 h-24 bg-accent-cyan/10 rounded-none blur-2xl pointer-events-none" />
              
              <h3 className="font-title font-bold text-slate-200 mb-4 flex items-center gap-2">
                <Award className="w-4.5 h-4.5 text-accent-cyan" />
                Rider Safety Index
              </h3>

              <div className="flex items-center gap-6 py-4">
                <div className="w-24 h-24 rounded-none border-4 border-accent-cyan/20 flex items-center justify-center relative">
                  <div className="absolute inset-1 rounded-none border-2 border-accent-cyan flex items-center justify-center font-title text-2xl font-black text-white">
                    {loading ? <Loader2 className="w-5 h-5 animate-spin text-accent-cyan" /> : Math.round(profileStats?.safety_score ?? 0)}
                  </div>
                </div>
                <div>
                  <h4 className="font-bold text-white text-base">
                    {(profileStats?.safety_score ?? 0) >= 95 ? "Tier 1: Master Operator" : (profileStats?.safety_score ?? 0) >= 80 ? "Tier 2: Operator" : "Tier 3: Trainee"}
                  </h4>
                  <p className="text-xs text-slate-400 mt-1 leading-relaxed">
                    Safety score based on {profileStats?.total_rides ?? 0} recorded rides. Threat detection avg latency via Gemini inference duplex.
                  </p>
                </div>
              </div>

              <div className="grid grid-cols-3 gap-3 border-t border-white/5 pt-4 mt-2 text-center text-xs font-mono text-slate-400">
                <div>
                  <div className="text-[10px] text-slate-500 uppercase">Distance</div>
                  <div className="text-sm font-bold text-slate-200 mt-1">{loading ? "…" : `${totalDistanceKm.toFixed(1)} km`}</div>
                </div>
                <div>
                  <div className="text-[10px] text-slate-500 uppercase">Interventions</div>
                  <div className="text-sm font-bold text-slate-200 mt-1">{loading ? "…" : totalThreatInterventions}</div>
                </div>
                <div>
                  <div className="text-[10px] text-slate-500 uppercase">Avg Speed</div>
                  <div className="text-sm font-bold text-slate-200 mt-1">{loading ? "…" : `${avgSpeed.toFixed(1)} km/h`}</div>
                </div>
              </div>
            </div>

            {/* Profile Config Card */}
            <div className="glass-panel tech-panel p-6 rounded-none border border-white/5">
              <h3 className="font-title font-bold text-slate-200 mb-6 flex items-center gap-2">
                <User className="w-4.5 h-4.5 text-accent-cyan" />
                Operator Identification Profile
              </h3>

              <div className="space-y-4">
                <div>
                  <label className="text-[10px] text-slate-300 font-title uppercase tracking-wider block mb-1.5">Rider Display Name</label>
                  <input
                    type="text"
                    value={profileName}
                    onChange={(e) => setProfileName(e.target.value)}
                    className="w-full text-xs bg-black/60 border border-white/10 rounded-none p-3 text-slate-200 focus:border-accent-cyan focus:outline-none"
                  />
                </div>

                <div>
                  <label className="text-[10px] text-slate-300 font-title uppercase tracking-wider block mb-1.5">Calibrated Hardware Helmet</label>
                  <div className="relative">
                    <select
                      value={selectedHelmet}
                      onChange={(e) => setSelectedHelmet(e.target.value)}
                      className="w-full text-xs bg-black/60 border border-white/10 rounded-none p-3 pr-10 text-slate-200 focus:border-accent-cyan focus:outline-none appearance-none cursor-pointer"
                    >
                      <option value="AGV SportModular Carbon" className="bg-slate-900 text-slate-200">AGV SportModular Carbon</option>
                      <option value="Shoei RF-1400 SmartSentry" className="bg-slate-900 text-slate-200">Shoei RF-1400 SmartSentry</option>
                      <option value="Arai Regent-X Edge" className="bg-slate-900 text-slate-200">Arai Regent-X Edge</option>
                    </select>
                    <ChevronDown className="w-4 h-4 text-slate-400 absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none" />
                  </div>
                </div>
              </div>
            </div>

          </div>

          {/* Right Grid: HUD Hardware Configuration Panels (7 Cols) */}
          <div className="lg:col-span-7 flex flex-col gap-6">
            <div className="glass-panel tech-panel p-6 rounded-none border border-white/5 flex-1 flex flex-col justify-between">
              
              <div>
                <h3 className="font-title font-bold text-slate-200 mb-6 flex items-center gap-2">
                  <Settings className="w-4.5 h-4.5 text-accent-cyan" />
                  HUD Device Calibration
                </h3>

                <div className="space-y-6">
                  {/* Slider: Sensitivity */}
                  <div className="space-y-2">
                    <div className="flex justify-between text-xs font-title uppercase">
                      <span className="text-slate-400 flex items-center gap-1.5">
                        <Sliders className="w-3.5 h-3.5 text-accent-cyan" />
                        Hazard Trigger Sensitivity
                      </span>
                      <span className="text-accent-cyan font-bold">{hudSensitivity}%</span>
                    </div>
                    <input
                      type="range"
                      min="10"
                      max="100"
                      value={hudSensitivity}
                      onChange={(e) => setHudSensitivity(parseInt(e.target.value))}
                      className="w-full h-1 bg-white/5 rounded-none appearance-none cursor-pointer accent-accent-cyan"
                    />
                    <p className="text-[10px] text-slate-500 leading-normal">
                      Adjust threshold for AI Perception Node triggers. Higher values increase prompt triggers for minor street anomalies.
                    </p>
                  </div>

                  {/* Toggle switch: Audio Alerts */}
                  <div className="flex items-start justify-between py-4 border-t border-white/5">
                    <div className="max-w-md pr-4">
                      <div className="text-xs font-bold text-slate-200 flex items-center gap-1.5">
                        <Volume2 className="w-3.5 h-3.5 text-accent-cyan" />
                        Auxiliary Auditory Warnings
                      </div>
                      <p className="text-[10px] text-slate-500 leading-normal mt-1">
                        Transmit auxiliary spatial warning chirps directly into helmet intercom channel on hazard alerts.
                      </p>
                    </div>
                    <button
                      onClick={() => setAudioAlerts(!audioAlerts)}
                      className={`w-12 h-6 rounded-none p-1 transition-colors duration-300 focus:outline-none ${
                        audioAlerts ? "bg-accent-cyan" : "bg-white/5 border border-white/10"
                      }`}
                    >
                      <div className={`w-4 h-4 rounded-none bg-white transition-transform duration-300 ${
                        audioAlerts ? "translate-x-6" : "translate-x-0"
                      }`} />
                    </button>
                  </div>

                  {/* Toggle switch: Passive Sentry */}
                  <div className="flex items-start justify-between py-4 border-t border-white/5">
                    <div className="max-w-md pr-4">
                      <div className="text-xs font-bold text-slate-200 flex items-center gap-1.5">
                        <Eye className="w-3.5 h-3.5 text-accent-cyan" />
                        Passive Sentry HUD Rendering
                      </div>
                      <p className="text-[10px] text-slate-500 leading-normal mt-1">
                        Keep HUD graphics in obsidian-sentry overlay active. If disabled, screen goes to standby at cruise speed.
                      </p>
                    </div>
                    <button
                      onClick={() => setSentryVision(!sentryVision)}
                      className={`w-12 h-6 rounded-none p-1 transition-colors duration-300 focus:outline-none ${
                        sentryVision ? "bg-accent-cyan" : "bg-white/5 border border-white/10"
                      }`}
                    >
                      <div className={`w-4 h-4 rounded-none bg-white transition-transform duration-300 ${
                        sentryVision ? "translate-x-6" : "translate-x-0"
                      }`} />
                    </button>
                  </div>

                  {/* Custom selection: Ring Accent Gradients */}
                  <div className="py-4 border-t border-white/5 space-y-3">
                    <label className="text-[10px] text-slate-300 font-title uppercase tracking-wider block">
                      Argus Ring Neon Contrast Style
                    </label>
                    <div className="flex items-center gap-4">
                      {["VIOLET", "CYAN", "MONO"].map((theme) => (
                        <button
                          key={theme}
                          onClick={() => setUiThemeColor(theme)}
                          className={`px-4 py-2 rounded-none text-xs font-bold font-mono transition-all duration-300 border ${
                            uiThemeColor === theme 
                              ? "bg-accent-cyan/20 border-accent-cyan text-white" 
                              : "bg-white/[0.01] border-white/5 text-slate-400 hover:border-white/15"
                          }`}
                        >
                          {theme}
                        </button>
                      ))}
                    </div>
                  </div>
                </div>

              </div>

              {/* Action Button */}
              <div className="pt-6 border-t border-white/5 flex items-center justify-between">
                <div className="flex items-center gap-2">
                  {saved && (
                    <span className="flex items-center gap-1.5 text-accent-green text-[10px] font-mono font-bold uppercase">
                      <CheckCircle className="w-3.5 h-3.5" />
                      Sync successful
                    </span>
                  )}
                  {!saved && (
                    <div className="text-[10px] text-slate-500 font-mono">
                      HUD REFRESH IN 1.2s
                    </div>
                  )}
                </div>
                <button 
                  onClick={handleSave}
                  className="bg-accent-cyan hover:bg-accent-cyan/80 text-white text-xs font-bold py-2.5 px-6 rounded-none shadow-lg shadow-accent-cyan/20 transition-all duration-300 flex items-center gap-2"
                >
                  <Save className="w-3.5 h-3.5" />
                  Save & Synergize HUD
                </button>
              </div>

            </div>
          </div>

        </div>

        {/* Bottom Area: Ride Logs DB (Filtered for User) */}
        <section className="glass-panel tech-panel p-6 rounded-none border border-white/5 flex flex-col">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
            <div>
              <h3 className="font-title font-bold text-slate-200 text-lg flex items-center gap-2">
                <Database className="w-5 h-5 text-accent-cyan" />
                Personal Ride Logs History
              </h3>
              <p className="text-xs text-slate-500 mt-0.5">
                Archived logs synced with the centralized Supabase relational database
              </p>
            </div>

            <div className="flex flex-wrap items-center gap-3">
              {/* Search */}
              <div className="relative">
                <input
                  type="text"
                  placeholder="Search date/record ID..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="bg-black/60 border border-white/10 rounded-none py-1.5 pl-8 pr-3 text-xs text-slate-200 focus:border-accent-cyan focus:outline-none w-48 font-mono"
                />
                <Search className="w-3.5 h-3.5 text-slate-500 absolute left-2.5 top-2.5" />
              </div>

              {/* Filter */}
              <div className="relative">
                <select
                  value={filterType}
                  onChange={(e) => setFilterType(e.target.value as any)}
                  className="bg-black/60 border border-white/10 rounded-none py-1.5 pl-3 pr-8 text-xs text-slate-200 focus:border-accent-cyan focus:outline-none appearance-none cursor-pointer"
                >
                  <option value="ALL" className="bg-slate-900 text-slate-200">ALL STATUS</option>
                  <option value="COMPLETED" className="bg-slate-900 text-slate-200">COMPLETED</option>
                  <option value="FLAGGED" className="bg-slate-900 text-slate-200">FLAGGED</option>
                </select>
                <ChevronDown className="w-3.5 h-3.5 text-slate-400 absolute right-2.5 top-1/2 -translate-y-1/2 pointer-events-none" />
              </div>
            </div>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs border-collapse">
              <thead>
                <tr className="border-b border-white/10 text-slate-500 font-mono">
                  <th className="py-3 px-2">Record ID</th>
                  <th className="py-3 px-2">Date</th>
                  <th className="py-3 px-2">Duration</th>
                  <th className="py-3 px-2">Avg Speed</th>
                  <th className="py-3 px-2">Threats Logged</th>
                  <th className="py-3 px-2">Safety Score</th>
                  <th className="py-3 px-2 text-right">Status</th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr><td colSpan={7} className="text-center py-10"><Loader2 className="w-5 h-5 animate-spin text-accent-cyan mx-auto" /></td></tr>
                ) : filteredRecords.map((r) => (
                  <tr key={r.id} className="border-b border-white/5 hover:bg-white/[0.02] transition-all">
                    <td className="py-3 px-2 font-mono text-accent-cyan font-bold text-[10px]">{r.session_id.slice(0, 12).toUpperCase()}</td>
                    <td className="py-3 px-2 text-slate-400 font-mono">{r.started_at.split("T")[0]}</td>
                    <td className="py-3 px-2 text-slate-300 font-mono">{formatDuration(r.duration_s)}</td>
                    <td className="py-3 px-2 text-slate-300 font-mono">{r.avg_speed_kmh ? `${r.avg_speed_kmh.toFixed(1)} km/h` : "—"}</td>
                    <td className="py-3 px-2 text-slate-300 font-mono">{r.threats_count}</td>
                    <td className="py-3 px-2 font-bold">
                      <span className={(r.safety_score ?? 0) < 80 ? "text-accent-pink" : (r.safety_score ?? 0) < 95 ? "text-accent-yellow" : "text-accent-green"}>
                        {r.safety_score ? `${r.safety_score}/100` : "—"}
                      </span>
                    </td>
                    <td className="py-3 px-2 text-right">
                      <span className={`px-2 py-0.5 rounded-none text-[10px] font-bold ${
                        rideStatusLabel(r.status) === "COMPLETED" ? "bg-accent-green/10 text-accent-green" : "bg-accent-red/10 text-accent-red"
                      }`}>
                        {rideStatusLabel(r.status)}
                      </span>
                    </td>
                  </tr>
                ))}
                {!loading && filteredRecords.length === 0 && (
                  <tr>
                    <td colSpan={7} className="text-center py-6 text-slate-600 italic">
                      No ride logs found. Complete a ride session in the ArgusX app to see your history here.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </section>

      </main>
    </div>
  );
}
