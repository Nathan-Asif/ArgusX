"use client";

import { useState, useEffect } from "react";
import Sidebar from "@/components/Sidebar";
import { ARGUSX_WS_PULSE_URL } from "@/lib/argusx_config";
import { 
  MapPin, 
  Activity, 
  Send, 
  Wifi, 
  AlertTriangle, 
  Navigation, 
  Eye, 
  ListFilter,
  CheckCircle,
  TrendingUp,
  Cpu,
  Users,
  ChevronDown
} from "lucide-react";

// Mock fleet riders
interface Rider {
  id: string;
  name: string;
  speed: number;
  lat: number;
  lng: number;
  threatLevel: "NORMAL" | "WARNING" | "CRITICAL";
  battery: number;
  deviceStatus: "CONNECTED" | "DISCONNECTED";
  helmetCam: string; // simulated description
  hudMode: "Sentry_Active" | "Hazard_Alert" | "Standby";
}

const initialRiders: Rider[] = [
  {
    id: "AX-091",
    name: "Rider Neo (Apex Alpha)",
    speed: 78.4,
    lat: 37.7749,
    lng: -122.4194,
    threatLevel: "WARNING",
    battery: 89,
    deviceStatus: "CONNECTED",
    helmetCam: "Opening car door detected 12m ahead on right lane.",
    hudMode: "Hazard_Alert"
  },
  {
    id: "AX-042",
    name: "Rider Trinity (Urban Beta)",
    speed: 42.1,
    lat: 37.7833,
    lng: -122.4167,
    threatLevel: "NORMAL",
    battery: 94,
    deviceStatus: "CONNECTED",
    helmetCam: "No immediate threats. Distant pedestrian moving parallel.",
    hudMode: "Sentry_Active"
  },
  {
    id: "AX-108",
    name: "Rider Morpheus (Highway Gamma)",
    speed: 104.2,
    lat: 37.7651,
    lng: -122.4411,
    threatLevel: "CRITICAL",
    battery: 72,
    deviceStatus: "CONNECTED",
    helmetCam: "CRITICAL: Heavy deceleration ahead. Debris in center lane.",
    hudMode: "Hazard_Alert"
  },
  {
    id: "AX-007",
    name: "Rider Cypher (Local Delta)",
    speed: 0.0,
    lat: 37.7599,
    lng: -122.4348,
    threatLevel: "NORMAL",
    battery: 45,
    deviceStatus: "DISCONNECTED",
    helmetCam: "Device offline. Latency timeout.",
    hudMode: "Standby"
  }
];

export default function FleetTracking() {
  const [riders, setRiders] = useState<Rider[]>(initialRiders);
  const [selectedRiderId, setSelectedRiderId] = useState<string>("AX-091");
  const [hudCommand, setHudCommand] = useState<string>("TRIGGER_HUD_ALERTS");
  const [consoleLogs, setConsoleLogs] = useState<string[]>([]);
  const [simRunning, setSimRunning] = useState<boolean>(true);
  const [socketStatus, setSocketStatus] = useState<"CONNECTING" | "CONNECTED" | "DISCONNECTED">("DISCONNECTED");

  // Selected Rider Helper
  const selectedRider = riders.find(r => r.id === selectedRiderId) || riders[0];

  // Dynamic simulation for movement & safety updates
  useEffect(() => {
    if (!simRunning) return;

    const interval = setInterval(() => {
      setRiders(prevRiders => 
        prevRiders.map(rider => {
          if (rider.deviceStatus === "DISCONNECTED") return rider;

          // Slightly modify speed
          const speedVariance = (Math.random() - 0.5) * 5;
          const nextSpeed = Math.max(0, parseFloat((rider.speed + speedVariance).toFixed(1)));

          // Small coordinate shift simulating movement
          const nextLat = parseFloat((rider.lat + (Math.random() - 0.5) * 0.0006).toFixed(5));
          const nextLng = parseFloat((rider.lng + (Math.random() - 0.5) * 0.0006).toFixed(5));

          // Mock random threat alert (only fallback if socket is not open for selected rider)
          let threat = rider.threatLevel;
          let camInfo = rider.helmetCam;
          let mode = rider.hudMode;

          if (rider.id !== selectedRiderId && Math.random() > 0.85) {
            const threatStates: ("NORMAL" | "WARNING" | "CRITICAL")[] = ["NORMAL", "WARNING", "CRITICAL"];
            threat = threatStates[Math.floor(Math.random() * 3)];
            
            if (threat === "CRITICAL") {
              camInfo = "CRITICAL: Rear vehicle approaching rapidly. Evasive path calculated.";
              mode = "Hazard_Alert";
            } else if (threat === "WARNING") {
              camInfo = "WARNING: Cross-traffic intersection hazard. Yield requested.";
              mode = "Hazard_Alert";
            } else {
              camInfo = "Scan complete. Clear corridor verified.";
              mode = "Sentry_Active";
            }

            // Log update
            setConsoleLogs(prev => [
              `[${new Date().toLocaleTimeString()}] ${rider.id} Node Update: Threat state shifted to ${threat}`,
              `[${new Date().toLocaleTimeString()}] ${rider.id} Core Context: ${camInfo}`,
              ...prev.slice(0, 15)
            ]);
          }

          return {
            ...rider,
            speed: nextSpeed,
            lat: nextLat,
            lng: nextLng,
            threatLevel: threat,
            helmetCam: camInfo,
            hudMode: mode
          };
        })
      );
    }, 3000);

    return () => clearInterval(interval);
  }, [simRunning, selectedRiderId]);

  // Live WebSocket Connection Loop
  useEffect(() => {
    if (selectedRider.deviceStatus === "DISCONNECTED" || !simRunning) {
      setSocketStatus("DISCONNECTED");
      return;
    }

    setSocketStatus("CONNECTING");
    const ws = new WebSocket(ARGUSX_WS_PULSE_URL);

    ws.onopen = () => {
      setSocketStatus("CONNECTED");
      setConsoleLogs(prev => [
        `[${new Date().toLocaleTimeString()}] WebSocket established with backend for ${selectedRider.id}`,
        ...prev.slice(0, 15)
      ]);
    };

    ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        setConsoleLogs(prev => [
          `[${new Date().toLocaleTimeString()}] WS Recv (${selectedRider.id}): Threat=${data.threat_level} | Commands=${JSON.stringify(data.ui_commands)} | Context="${data.enriched_context || "none"}"`,
          ...prev.slice(0, 15)
        ]);

        // Update selected rider safety indices using response from the LangGraph engine
        setRiders(prevRiders =>
          prevRiders.map(r => {
            if (r.id === selectedRider.id) {
              return {
                ...r,
                threatLevel: data.threat_level,
                hudMode: data.threat_level === "CRITICAL" ? "Hazard_Alert" : "Sentry_Active",
                helmetCam: data.enriched_context || "Safety Pulse verified. Corridor secure."
              };
            }
            return r;
          })
        );
      } catch (err) {
        console.error("Failed to parse WS payload", err);
      }
    };

    ws.onerror = () => {
      setSocketStatus("DISCONNECTED");
      setConsoleLogs(prev => [
        `[${new Date().toLocaleTimeString()}] WS Error: Connection failed for ${selectedRider.id}`,
        ...prev.slice(0, 15)
      ]);
    };

    ws.onclose = () => {
      setSocketStatus("DISCONNECTED");
      setConsoleLogs(prev => [
        `[${new Date().toLocaleTimeString()}] WS Closed: Connection terminated for ${selectedRider.id}`,
        ...prev.slice(0, 15)
      ]);
    };

    // Periodically stream state packets over WebSocket
    const sendInterval = setInterval(() => {
      if (ws.readyState === WebSocket.OPEN) {
        const payload = {
          speed: selectedRider.speed,
          coordinates: { lat: selectedRider.lat, lng: selectedRider.lng },
          frame_data: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=" // mock base64
        };
        ws.send(JSON.stringify(payload));
        setConsoleLogs(prev => [
          `[${new Date().toLocaleTimeString()}] WS Send (${selectedRider.id}): Speed=${payload.speed} | Coords=${payload.coordinates.lat}, ${payload.coordinates.lng}`,
          ...prev.slice(0, 15)
        ]);
      }
    }, 4000);

    return () => {
      clearInterval(sendInterval);
      ws.close();
    };
  }, [selectedRiderId, simRunning, selectedRider.speed, selectedRider.lat, selectedRider.lng, selectedRider.deviceStatus]);

  // Handle Command Submission
  const handleSendCommand = (e: React.FormEvent) => {
    e.preventDefault();
    setConsoleLogs(prev => [
      `[${new Date().toLocaleTimeString()}] Command sent to ${selectedRider.id}: [${hudCommand}]`,
      `[${new Date().toLocaleTimeString()}] HUD Response from ${selectedRider.id}: Command Acknowledged & UI State updated.`,
      ...prev.slice(0, 15)
    ]);
  };

  return (
    <div className="flex flex-row min-h-screen">
      <Sidebar />

      {/* Main Dashboard Space */}
      <main className="flex-1 flex flex-col min-w-0 overflow-y-auto p-8 relative z-10">
        
        {/* Top Stats Bar */}
        <header className="flex flex-col md:flex-row md:items-center md:justify-between pb-6 border-b border-white/5 mb-8 gap-4">
          <div>
            <h1 className="font-title text-3xl font-black tracking-wide text-white">
              Fleet Tracking Dashboard
            </h1>
            <p className="text-xs text-slate-400 mt-1">
              Tesla-Style Central Command Station & Spatial Telemetry Monitors
            </p>
          </div>

          <div className="flex items-center gap-3">
            <button
              onClick={() => setSimRunning(!simRunning)}
              className={`px-4 py-2 rounded-none text-xs font-bold transition-all duration-300 ${
                simRunning 
                  ? "bg-accent-purple/20 border border-accent-purple/40 text-accent-purple hover:bg-accent-purple/30" 
                  : "bg-slate-800 border border-slate-700 text-slate-300 hover:bg-slate-700"
              }`}
            >
              SIMULATION: {simRunning ? "ACTIVE" : "PAUSED"}
            </button>
            <div className="glass-panel tech-panel border border-white/5 px-4 py-2 rounded-none text-xs flex items-center gap-2">
              <span className={`w-2 h-2 rounded-none animate-pulse ${
                socketStatus === "CONNECTED" ? "bg-accent-cyan" : socketStatus === "CONNECTING" ? "bg-accent-yellow" : "bg-accent-red"
              }`} />
              <span>WS: {socketStatus}</span>
            </div>
          </div>
        </header>

        {/* Core Layout Split */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 flex-1">
          
          {/* Left: Active Riders Grid (4 Cols) */}
          <div className="lg:col-span-4 flex flex-col gap-6">
            <div className="glass-panel tech-panel rounded-none border border-white/5 p-6 flex flex-col flex-1 max-h-[600px] overflow-hidden">
              <div className="flex items-center justify-between mb-4">
                <h3 className="font-title font-bold text-slate-200 flex items-center gap-2">
                  <Users className="w-4 h-4 text-accent-purple" />
                  Active Operators ({riders.filter(r => r.deviceStatus === "CONNECTED").length})
                </h3>
                <ListFilter className="w-4 h-4 text-slate-500 cursor-pointer hover:text-slate-300" />
              </div>

              {/* Riders List */}
              <div className="space-y-3 flex-1 overflow-y-auto pr-1">
                {riders.map((rider) => {
                  const isSelected = rider.id === selectedRiderId;
                  const isCritical = rider.threatLevel === "CRITICAL";
                  const isWarning = rider.threatLevel === "WARNING";
                  
                  let threatColor = "bg-accent-green text-accent-green";
                  if (isCritical) threatColor = "bg-accent-red text-accent-red";
                  if (isWarning) threatColor = "bg-accent-yellow text-accent-yellow";

                  return (
                    <div
                      key={rider.id}
                      onClick={() => setSelectedRiderId(rider.id)}
                      className={`p-4 rounded-none border transition-all duration-300 cursor-pointer relative ${
                        isSelected 
                          ? "bg-gradient-to-r from-accent-purple/15 to-transparent border-accent-purple/40" 
                          : "bg-white/[0.01] border-white/5 hover:border-white/10 hover:bg-white/[0.03]"
                      }`}
                    >
                      <div className="flex items-start justify-between">
                        <div>
                          <div className="flex items-center gap-2">
                            <span className="font-bold text-sm text-white">{rider.name}</span>
                            <span className="text-[10px] bg-white/5 px-1.5 py-0.5 rounded-none text-slate-400 font-mono">
                              {rider.id}
                            </span>
                          </div>
                          <div className="flex items-center gap-3 mt-2 text-xs text-slate-400">
                            <span className="flex items-center gap-1">
                              <Navigation className="w-3.5 h-3.5 text-slate-500 rotate-45" />
                              {rider.speed} km/h
                            </span>
                            <span className="flex items-center gap-1">
                              <Wifi className="w-3.5 h-3.5 text-slate-500" />
                              {rider.deviceStatus}
                            </span>
                          </div>
                        </div>

                        {/* Status Light */}
                        <div className="flex flex-col items-end gap-1.5">
                          <span className={`text-[9px] font-black tracking-wider uppercase px-2 py-0.5 rounded-none bg-black/40 border border-white/5 ${
                            isCritical ? "text-accent-red" : isWarning ? "text-accent-yellow" : "text-accent-green"
                          }`}>
                            {rider.threatLevel}
                          </span>
                          {rider.deviceStatus === "CONNECTED" && (
                            <span className="w-2 h-2 rounded-none bg-accent-purple animate-ping" />
                          )}
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>

          {/* Right: Map Grid & Controls (8 Cols) */}
          <div className="lg:col-span-8 flex flex-col gap-8">
            
            {/* Map Visualizer Card */}
            <div className="glass-panel tech-panel rounded-none border border-white/5 p-6 flex flex-col h-[350px] relative overflow-hidden">
              <div className="absolute inset-0 bg-zinc-950/20 z-0" />
              
              {/* Tactical Grid Overlay Map (Canvas/SVG representation) */}
              <div className="absolute inset-0 z-0 bg-[linear-gradient(rgba(18,16,24,0.4),rgba(18,16,24,0.8))]">
                <svg className="w-full h-full opacity-60" xmlns="http://www.w3.org/2000/svg">
                  {/* Decorative Map Vector Paths */}
                  <path d="M0,150 Q150,100 300,180 T600,100 T900,200" fill="none" stroke="rgba(139, 92, 246, 0.15)" strokeWidth="2" />
                  <path d="M100,0 L200,400 M500,0 L450,400 M800,0 L900,400" fill="none" stroke="rgba(255,255,255,0.03)" strokeWidth="1" />
                  <circle cx="300" cy="180" r="80" fill="none" stroke="rgba(139, 92, 246, 0.05)" strokeWidth="1" />
                  <circle cx="600" cy="100" r="120" fill="none" stroke="rgba(6, 182, 212, 0.04)" strokeWidth="1" />
                  
                  {/* Active Rider Dots */}
                  {riders.map((r, i) => {
                    if (r.deviceStatus === "DISCONNECTED") return null;
                    const x = 150 + (i * 180) + (r.speed * 0.5);
                    const y = 80 + (i * 60) + (r.lat * 0.1);
                    return (
                      <g key={r.id}>
                        {/* Pulse Ring */}
                        <circle cx={x} cy={y} r="16" fill="none" stroke={r.threatLevel === "CRITICAL" ? "rgba(239, 68, 68, 0.3)" : "rgba(139, 92, 246, 0.3)"} strokeWidth="1" className="animate-ping" style={{ transformOrigin: `${x}px ${y}px` }} />
                        <circle cx={x} cy={y} r="6" fill={r.threatLevel === "CRITICAL" ? "#ef4444" : r.threatLevel === "WARNING" ? "#f59e0b" : "#8b5cf6"} />
                        <text x={x + 10} y={y + 4} fill="rgba(255,255,255,0.6)" fontSize="9" fontFamily="monospace" fontWeight="bold">
                          {r.id} ({r.speed}km/h)
                        </text>
                      </g>
                    );
                  })}
                </svg>
              </div>

              <div className="relative z-10 flex items-center justify-between">
                <h3 className="font-title font-bold text-slate-200 flex items-center gap-2">
                  <MapPin className="w-4 h-4 text-accent-purple" />
                  Spatial Telemetry Map Visualizer
                </h3>
                <span className="text-[10px] text-slate-500 font-mono">GRID SCALE: 1:1000m</span>
              </div>

              {/* Overlay legend */}
              <div className="absolute bottom-6 left-6 z-10 bg-black/60 border border-white/5 px-3 py-2 rounded-none text-[10px] font-mono text-slate-400 space-y-1">
                <div className="flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-none bg-[#8b5cf6]" />
                  <span>NORMAL STATUS</span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-none bg-[#f59e0b]" />
                  <span>WARNING ALERT</span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-none bg-[#ef4444]" />
                  <span>CRITICAL IMPACT THREAT</span>
                </div>
              </div>
            </div>

            {/* Split Details & Control Panels */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
              
              {/* Selected Operator Stats */}
              <div className="glass-panel tech-panel rounded-none border border-white/5 p-6 flex flex-col justify-between">
                <div>
                  <h4 className="text-xs text-slate-500 font-sans tracking-widest uppercase mb-4">
                    Active Telemetry Profile
                  </h4>
                  <div className="flex items-center justify-between mb-4">
                    <div>
                      <h2 className="text-xl font-bold text-white">{selectedRider.name}</h2>
                      <p className="text-xs text-slate-400 mt-0.5">Device ID: <span className="font-mono text-accent-purple">{selectedRider.id}</span></p>
                    </div>
                    <div className="text-right">
                      <div className="text-xs text-slate-500">HUD Action Mode</div>
                      <div className="text-xs font-bold text-white flex items-center gap-1.5 mt-1 justify-end">
                        <Activity className="w-3 h-3 text-accent-purple" />
                        {selectedRider.hudMode}
                      </div>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-4 py-4 border-t border-b border-white/5 my-4">
                    <div>
                      <div className="text-[10px] text-slate-300 font-title uppercase tracking-wider">Coordinates</div>
                      <div className="text-sm font-bold text-slate-200 mt-1 font-mono">
                        {selectedRider.lat}, {selectedRider.lng}
                      </div>
                    </div>
                    <div>
                      <div className="text-[10px] text-slate-300 font-title uppercase tracking-wider">Operator Battery</div>
                      <div className="text-sm font-bold text-slate-200 mt-1">
                        {selectedRider.battery}%
                      </div>
                    </div>
                  </div>

                  <div>
                    <span className="text-[10px] text-slate-300 font-title uppercase tracking-wider">AI Perception Feed Context</span>
                    <p className="text-xs text-slate-300 mt-1 bg-white/[0.02] border border-white/5 p-3 rounded-none leading-relaxed">
                      {selectedRider.helmetCam}
                    </p>
                  </div>
                </div>
              </div>

              {/* Direct HUD Command Overlay Console */}
              <div className="glass-panel tech-panel rounded-none border border-white/5 p-6 flex flex-col justify-between">
                <div>
                  <h4 className="text-xs text-slate-500 font-sans tracking-widest uppercase mb-4 flex items-center gap-1.5">
                    <Cpu className="w-3.5 h-3.5 text-accent-purple" />
                    HUD Interface Command Center
                  </h4>
                  
                  <p className="text-xs text-slate-400 leading-relaxed mb-6">
                    Emit immediate state directives or force hazard mitigation layouts back to the rider's Heads-Up Display via WebSockets.
                  </p>

                  <form onSubmit={handleSendCommand} className="space-y-4">
                    <div>
                      <label className="text-[10px] text-slate-300 font-title uppercase tracking-wider block mb-2">
                        UI Command Selection
                      </label>
                      <div className="relative">
                        <select
                          value={hudCommand}
                          onChange={(e) => setHudCommand(e.target.value)}
                          className="w-full text-xs bg-black/60 border border-white/10 rounded-none p-3 pr-10 text-slate-200 font-mono focus:border-accent-purple focus:outline-none appearance-none cursor-pointer"
                        >
                          <option value="TRIGGER_HUD_ALERTS" className="bg-slate-900 text-slate-200">TRIGGER_HUD_ALERTS</option>
                          <option value="PRUNE_NON_ESSENTIAL_WIDGETS" className="bg-slate-900 text-slate-200">PRUNE_NON_ESSENTIAL_WIDGETS</option>
                          <option value="EXPAND_TELEMETRY_OVERLAY" className="bg-slate-900 text-slate-200">EXPAND_TELEMETRY_OVERLAY</option>
                          <option value="RESET_HUD_CALIBRATION" className="bg-slate-900 text-slate-200">RESET_HUD_CALIBRATION</option>
                        </select>
                        <ChevronDown className="w-4 h-4 text-slate-400 absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none" />
                      </div>
                    </div>

                    <button
                      type="submit"
                      disabled={selectedRider.deviceStatus === "DISCONNECTED"}
                      className={`w-full flex items-center justify-center gap-2 p-3 rounded-none text-xs font-bold transition-all duration-300 ${
                        selectedRider.deviceStatus === "DISCONNECTED" 
                          ? "bg-slate-800 border border-slate-700 text-slate-500 cursor-not-allowed" 
                          : "bg-accent-purple hover:bg-accent-purple/80 text-white shadow-lg shadow-accent-purple/20"
                      }`}
                    >
                      <Send className="w-3.5 h-3.5" />
                      Dispatch Action Command
                    </button>
                  </form>
                </div>

                <div className="text-[10px] text-slate-500 mt-6 flex justify-between font-mono">
                  <span>DISPATCH GATE: WS_SECURE</span>
                  <span>SSL_COMPLIANT</span>
                </div>
              </div>

            </div>

            {/* Bottom Log Streaming Output */}
            <div className="glass-panel tech-panel rounded-none border border-white/5 p-6 flex flex-col h-[200px]">
              <div className="flex items-center justify-between mb-3">
                <h4 className="text-xs text-slate-500 font-sans tracking-widest uppercase flex items-center gap-1.5">
                  <Activity className="w-3.5 h-3.5 text-accent-purple animate-pulse" />
                  Live Safety Pulse Stream
                </h4>
                <div className="flex gap-4 text-[10px] font-mono text-slate-500">
                  <span>WS PULSE: ACTIVE</span>
                  <span>BUFFER: 16/16</span>
                </div>
              </div>

              <div className="flex-1 bg-black/40 border border-white/5 rounded-none p-4 font-mono text-slate-400 text-xs overflow-y-auto space-y-2 max-h-[120px] select-all">
                {consoleLogs.length === 0 ? (
                  <div className="text-slate-600 italic">Listening for inbound device packet payloads...</div>
                ) : (
                  consoleLogs.map((log, index) => (
                    <div key={index} className="leading-5">
                      <span className="text-slate-600">&gt;</span> {log}
                    </div>
                  ))
                )}
              </div>
            </div>

          </div>

        </div>

      </main>
    </div>
  );
}
