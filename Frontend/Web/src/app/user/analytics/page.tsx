"use client";

import { useState } from "react";
import Sidebar from "@/components/Sidebar";
import { 
  User, 
  Settings, 
  ShieldCheck, 
  Volume2, 
  Eye, 
  Sliders,
  Calendar,
  Zap,
  Activity,
  Award,
  ChevronDown
} from "lucide-react";

export default function UserAnalytics() {
  // Mock Rider profile settings
  const [hudSensitivity, setHudSensitivity] = useState(75);
  const [audioAlerts, setAudioAlerts] = useState(true);
  const [sentryVision, setSentryVision] = useState(true);
  const [uiThemeColor, setUiThemeColor] = useState("VIOLET");
  const [profileName, setProfileName] = useState("Rider Neo");
  const [selectedHelmet, setSelectedHelmet] = useState("AGV SportModular Carbon");

  return (
    <div className="flex flex-row min-h-screen">
      <Sidebar />

      {/* Main Content Space */}
      <main className="flex-1 flex flex-col min-w-0 overflow-y-auto p-8 relative z-10">
        
        {/* Header */}
        <header className="flex flex-col md:flex-row md:items-center md:justify-between pb-6 border-b border-white/5 mb-8 gap-4">
          <div>
            <h1 className="font-title text-3xl font-black tracking-wide text-white">
              Operator Portal
            </h1>
            <p className="text-xs text-slate-400 mt-1">
              Configure HUD preferences, calibrate spatial RAG triggers, and view individual safety summaries
            </p>
          </div>

          <div className="flex items-center gap-3">
            <div className="glass-panel border border-white/5 px-4 py-2 rounded-lg text-xs flex items-center gap-2 text-slate-300">
              <User className="w-4 h-4 text-accent-purple" />
              <span>Session: <span className="font-bold font-mono">NEO_SECURE</span></span>
            </div>
          </div>
        </header>

        {/* Layout Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 flex-1">
          
          {/* Left Grid: Personal Telemetry & Onboarding Profiles (5 Cols) */}
          <div className="lg:col-span-5 flex flex-col gap-6">
            
            {/* Personal Score Summary */}
            <div className="glass-panel p-6 rounded-2xl border border-white/5 relative overflow-hidden">
              <div className="absolute top-0 right-0 w-24 h-24 bg-accent-purple/10 rounded-full blur-2xl pointer-events-none" />
              
              <h3 className="font-title font-bold text-slate-200 mb-4 flex items-center gap-2">
                <Award className="w-4.5 h-4.5 text-accent-purple" />
                Rider Safety Index
              </h3>

              <div className="flex items-center gap-6 py-4">
                <div className="w-24 h-24 rounded-full border-4 border-accent-purple/20 flex items-center justify-center relative">
                  <div className="absolute inset-1 rounded-full border-2 border-accent-purple flex items-center justify-center font-title text-2xl font-black text-white">
                    96
                  </div>
                </div>
                <div>
                  <h4 className="font-bold text-white text-base">Tier 1: Master Operator</h4>
                  <p className="text-xs text-slate-400 mt-1 leading-relaxed">
                    Safety score remains in the top 5% of global riders. Low hazard response latency (avg. 165ms).
                  </p>
                </div>
              </div>

              <div className="grid grid-cols-3 gap-3 border-t border-white/5 pt-4 mt-2 text-center text-xs font-mono text-slate-400">
                <div>
                  <div className="text-[10px] text-slate-500 uppercase">Miles Logged</div>
                  <div className="text-sm font-bold text-slate-200 mt-1">1,248m</div>
                </div>
                <div>
                  <div className="text-[10px] text-slate-500 uppercase">Interventions</div>
                  <div className="text-sm font-bold text-slate-200 mt-1">18</div>
                </div>
                <div>
                  <div className="text-[10px] text-slate-500 uppercase">Avg Speed</div>
                  <div className="text-sm font-bold text-slate-200 mt-1">64.2 km/h</div>
                </div>
              </div>
            </div>

            {/* Profile Config Card */}
            <div className="glass-panel p-6 rounded-2xl border border-white/5">
              <h3 className="font-title font-bold text-slate-200 mb-6 flex items-center gap-2">
                <User className="w-4.5 h-4.5 text-accent-purple" />
                Operator Identification Profile
              </h3>

              <div className="space-y-4">
                <div>
                  <label className="text-[10px] text-slate-500 font-mono uppercase block mb-1.5">Rider Display Name</label>
                  <input
                    type="text"
                    value={profileName}
                    onChange={(e) => setProfileName(e.target.value)}
                    className="w-full text-xs bg-black/60 border border-white/10 rounded-lg p-3 text-slate-200 focus:border-accent-purple focus:outline-none"
                  />
                </div>

                <div>
                  <label className="text-[10px] text-slate-500 font-mono uppercase block mb-1.5">Calibrated Hardware Helmet</label>
                  <div className="relative">
                    <select
                      value={selectedHelmet}
                      onChange={(e) => setSelectedHelmet(e.target.value)}
                      className="w-full text-xs bg-black/60 border border-white/10 rounded-lg p-3 pr-10 text-slate-200 focus:border-accent-purple focus:outline-none appearance-none cursor-pointer"
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
            <div className="glass-panel p-6 rounded-2xl border border-white/5 flex-1 flex flex-col justify-between">
              
              <div>
                <h3 className="font-title font-bold text-slate-200 mb-6 flex items-center gap-2">
                  <Settings className="w-4.5 h-4.5 text-accent-purple" />
                  HUD Device Calibration
                </h3>

                <div className="space-y-6">
                  {/* Slider: Sensitivity */}
                  <div className="space-y-2">
                    <div className="flex justify-between text-xs font-mono uppercase">
                      <span className="text-slate-400 flex items-center gap-1.5">
                        <Sliders className="w-3.5 h-3.5 text-accent-purple" />
                        Hazard Trigger Sensitivity
                      </span>
                      <span className="text-accent-purple font-bold">{hudSensitivity}%</span>
                    </div>
                    <input
                      type="range"
                      min="10"
                      max="100"
                      value={hudSensitivity}
                      onChange={(e) => setHudSensitivity(parseInt(e.target.value))}
                      className="w-full h-1 bg-white/5 rounded-lg appearance-none cursor-pointer accent-accent-purple"
                    />
                    <p className="text-[10px] text-slate-500 leading-normal">
                      Adjust threshold for AI Perception Node triggers. Higher values increase prompt triggers for minor street anomalies.
                    </p>
                  </div>

                  {/* Toggle switch: Audio Alerts */}
                  <div className="flex items-start justify-between py-4 border-t border-white/5">
                    <div className="max-w-md pr-4">
                      <div className="text-xs font-bold text-slate-200 flex items-center gap-1.5">
                        <Volume2 className="w-3.5 h-3.5 text-accent-purple" />
                        Auxiliary Auditory Warnings
                      </div>
                      <p className="text-[10px] text-slate-500 leading-normal mt-1">
                        Transmit auxiliary spatial warning chirps directly into helmet intercom channel on hazard alerts.
                      </p>
                    </div>
                    <button
                      onClick={() => setAudioAlerts(!audioAlerts)}
                      className={`w-12 h-6 rounded-full p-1 transition-colors duration-300 focus:outline-none ${
                        audioAlerts ? "bg-accent-purple" : "bg-white/5 border border-white/10"
                      }`}
                    >
                      <div className={`w-4 h-4 rounded-full bg-white transition-transform duration-300 ${
                        audioAlerts ? "translate-x-6" : "translate-x-0"
                      }`} />
                    </button>
                  </div>

                  {/* Toggle switch: Passive Sentry */}
                  <div className="flex items-start justify-between py-4 border-t border-white/5">
                    <div className="max-w-md pr-4">
                      <div className="text-xs font-bold text-slate-200 flex items-center gap-1.5">
                        <Eye className="w-3.5 h-3.5 text-accent-purple" />
                        Passive Sentry HUD Rendering
                      </div>
                      <p className="text-[10px] text-slate-500 leading-normal mt-1">
                        Keep HUD graphics in obsidian-sentry overlay active. If disabled, screen goes to standby at cruise speed.
                      </p>
                    </div>
                    <button
                      onClick={() => setSentryVision(!sentryVision)}
                      className={`w-12 h-6 rounded-full p-1 transition-colors duration-300 focus:outline-none ${
                        sentryVision ? "bg-accent-purple" : "bg-white/5 border border-white/10"
                      }`}
                    >
                      <div className={`w-4 h-4 rounded-full bg-white transition-transform duration-300 ${
                        sentryVision ? "translate-x-6" : "translate-x-0"
                      }`} />
                    </button>
                  </div>

                  {/* Custom selection: Ring Accent Gradients */}
                  <div className="py-4 border-t border-white/5 space-y-3">
                    <label className="text-[10px] text-slate-500 font-mono uppercase block">
                      Argus Ring Neon Contrast Style
                    </label>
                    <div className="flex items-center gap-4">
                      {["VIOLET", "CYAN", "MONO"].map((theme) => (
                        <button
                          key={theme}
                          onClick={() => setUiThemeColor(theme)}
                          className={`px-4 py-2 rounded-lg text-xs font-bold font-mono transition-all duration-300 border ${
                            uiThemeColor === theme 
                              ? "bg-accent-purple/20 border-accent-purple text-white" 
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
                <div className="text-[10px] text-slate-500 font-mono">
                  HUD REFRESH IN 1.2s
                </div>
                <button className="bg-accent-purple hover:bg-accent-purple/80 text-white text-xs font-bold py-2.5 px-6 rounded-lg shadow-lg shadow-accent-purple/20 transition-all duration-300">
                  Save & Synergize HUD
                </button>
              </div>

            </div>
          </div>

        </div>

      </main>
    </div>
  );
}
