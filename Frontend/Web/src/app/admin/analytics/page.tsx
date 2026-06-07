"use client";

import { useState } from "react";
import Sidebar from "@/components/Sidebar";
import { 
  TrendingUp, 
  ShieldAlert, 
  Database, 
  Download, 
  Search, 
  Filter,
  LineChart,
  Calendar,
  AlertTriangle,
  Clock,
  ChevronDown
} from "lucide-react";

// Mock Database Records for Rider Analytics
interface RideRecord {
  id: string;
  riderName: string;
  date: string;
  duration: string;
  avgSpeed: number;
  threatsLogged: number;
  safetyScore: number;
  status: "COMPLETED" | "FLAGGED";
}

const mockRecords: RideRecord[] = [
  { id: "R-8092", riderName: "Rider Neo", date: "2026-06-06", duration: "48 mins", avgSpeed: 64.2, threatsLogged: 2, safetyScore: 94, status: "COMPLETED" },
  { id: "R-8091", riderName: "Rider Trinity", date: "2026-06-06", duration: "25 mins", avgSpeed: 38.5, threatsLogged: 0, safetyScore: 100, status: "COMPLETED" },
  { id: "R-8090", riderName: "Rider Morpheus", date: "2026-06-05", duration: "1 hr 12 mins", avgSpeed: 89.1, threatsLogged: 7, safetyScore: 78, status: "FLAGGED" },
  { id: "R-8089", riderName: "Rider Neo", date: "2026-06-05", duration: "34 mins", avgSpeed: 58.7, threatsLogged: 1, safetyScore: 97, status: "COMPLETED" },
  { id: "R-8088", riderName: "Rider Cypher", date: "2026-06-04", duration: "15 mins", avgSpeed: 30.1, threatsLogged: 4, safetyScore: 82, status: "FLAGGED" },
  { id: "R-8087", riderName: "Rider Trinity", date: "2026-06-04", duration: "52 mins", avgSpeed: 42.0, threatsLogged: 0, safetyScore: 100, status: "COMPLETED" },
  { id: "R-8086", riderName: "Rider Morpheus", date: "2026-06-03", duration: "2 hrs 5 mins", avgSpeed: 94.6, threatsLogged: 12, safetyScore: 65, status: "FLAGGED" }
];

export default function Analytics() {
  const [records, setRecords] = useState<RideRecord[]>(mockRecords);
  const [searchTerm, setSearchTerm] = useState("");
  const [filterType, setFilterType] = useState<"ALL" | "COMPLETED" | "FLAGGED">("ALL");

  const filteredRecords = records.filter(record => {
    const matchesSearch = record.riderName.toLowerCase().includes(searchTerm.toLowerCase()) || record.id.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesFilter = filterType === "ALL" ? true : record.status === filterType;
    return matchesSearch && matchesFilter;
  });

  return (
    <div className="flex flex-row min-h-screen">
      <Sidebar />

      {/* Main Container */}
      <main className="flex-1 flex flex-col min-w-0 overflow-y-auto p-8 relative z-10">
        
        {/* Top Header */}
        <header className="flex flex-col md:flex-row md:items-center md:justify-between pb-6 border-b border-white/5 mb-8 gap-4">
          <div>
            <h1 className="font-title text-3xl font-black tracking-wide text-white">
              System Analytics
            </h1>
            <p className="text-xs text-slate-400 mt-1">
              Relational Safety Databases & Long-Term Performance Statistics
            </p>
          </div>

          <button className="flex items-center gap-2 bg-white/[0.03] hover:bg-white/[0.07] border border-white/5 px-4 py-2 rounded-lg text-xs text-slate-300 font-bold transition-all duration-300">
            <Download className="w-3.5 h-3.5" />
            Export Database CSV
          </button>
        </header>

        {/* Top High-level Stats Cards */}
        <section className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <div className="glass-panel p-6 rounded-2xl border border-white/5">
            <div className="flex justify-between items-start text-slate-400">
              <span className="text-xs font-mono uppercase tracking-wider">Average Fleet Safety Score</span>
              <TrendingUp className="w-4 h-4 text-accent-purple" />
            </div>
            <div className="text-3xl font-black text-white mt-3 font-title">91.4%</div>
            <div className="text-[10px] text-accent-green mt-1.5 font-bold flex items-center gap-1">
              <span>+1.2% VS LAST WEEK</span>
            </div>
          </div>

          <div className="glass-panel p-6 rounded-2xl border border-white/5">
            <div className="flex justify-between items-start text-slate-400">
              <span className="text-xs font-mono uppercase tracking-wider">Total Threats Blocked</span>
              <ShieldAlert className="w-4 h-4 text-accent-pink" />
            </div>
            <div className="text-3xl font-black text-white mt-3 font-title">382</div>
            <div className="text-[10px] text-accent-pink mt-1.5 font-bold flex items-center gap-1">
              <span>28 CRITICAL INTERVENTIONS</span>
            </div>
          </div>

          <div className="glass-panel p-6 rounded-2xl border border-white/5">
            <div className="flex justify-between items-start text-slate-400">
              <span className="text-xs font-mono uppercase tracking-wider">Riders Logged</span>
              <Database className="w-4 h-4 text-accent-cyan" />
            </div>
            <div className="text-3xl font-black text-white mt-3 font-title">18 Users</div>
            <div className="text-[10px] text-slate-500 mt-1.5 font-mono">ACTIVE IN DATABASE</div>
          </div>

          <div className="glass-panel p-6 rounded-2xl border border-white/5">
            <div className="flex justify-between items-start text-slate-400">
              <span className="text-xs font-mono uppercase tracking-wider">Avg Response Time</span>
              <Clock className="w-4 h-4 text-yellow-500" />
            </div>
            <div className="text-3xl font-black text-white mt-3 font-title">14ms</div>
            <div className="text-[10px] text-accent-cyan mt-1.5 font-bold">GEMINI INFERENCE DUPLEX</div>
          </div>
        </section>

        {/* Detailed Analytics Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 flex-1">
          
          {/* Left Area: Analytical Bar Charts / Visualizations (5 Cols) */}
          <div className="lg:col-span-5 flex flex-col gap-6">
            <div className="glass-panel p-6 rounded-2xl border border-white/5 flex-1">
              <h3 className="font-title font-bold text-slate-200 mb-6 flex items-center gap-2">
                <LineChart className="w-4 h-4 text-accent-purple" />
                Fleet Threat Distribution By Category
              </h3>

              {/* Mock visual CSS Bar charts */}
              <div className="space-y-5">
                <div>
                  <div className="flex justify-between text-xs text-slate-400 mb-2">
                    <span>Opening Car Doors (Perception Node)</span>
                    <span className="font-bold text-slate-200">42%</span>
                  </div>
                  <div className="w-full h-2 bg-white/[0.02] rounded-full overflow-hidden border border-white/5">
                    <div className="h-full bg-gradient-to-r from-accent-purple to-accent-pink rounded-full" style={{ width: "42%" }} />
                  </div>
                </div>

                <div>
                  <div className="flex justify-between text-xs text-slate-400 mb-2">
                    <span>Distracted Pedestrians</span>
                    <span className="font-bold text-slate-200">28%</span>
                  </div>
                  <div className="w-full h-2 bg-white/[0.02] rounded-full overflow-hidden border border-white/5">
                    <div className="h-full bg-gradient-to-r from-accent-purple to-accent-pink rounded-full" style={{ width: "28%" }} />
                  </div>
                </div>

                <div>
                  <div className="flex justify-between text-xs text-slate-400 mb-2">
                    <span>Road Debris / Potholes</span>
                    <span className="font-bold text-slate-200">18%</span>
                  </div>
                  <div className="w-full h-2 bg-white/[0.02] rounded-full overflow-hidden border border-white/5">
                    <div className="h-full bg-gradient-to-r from-accent-purple to-accent-pink rounded-full" style={{ width: "18%" }} />
                  </div>
                </div>

                <div>
                  <div className="flex justify-between text-xs text-slate-400 mb-2">
                    <span>Sudden Braking / Rear-end hazard</span>
                    <span className="font-bold text-slate-200">12%</span>
                  </div>
                  <div className="w-full h-2 bg-white/[0.02] rounded-full overflow-hidden border border-white/5">
                    <div className="h-full bg-gradient-to-r from-accent-purple to-accent-pink rounded-full" style={{ width: "12%" }} />
                  </div>
                </div>
              </div>

              {/* Summary note */}
              <div className="mt-8 p-4 rounded-xl bg-white/[0.01] border border-white/5 text-xs text-slate-400 leading-relaxed">
                <span className="text-accent-purple font-bold">Insight:</span> Multimodal Perception Nodes detect opening vehicle doors as the most common hazard in dense urban zones, prompting high rates of HUD decluttering and alert triggers.
              </div>
            </div>
          </div>

          {/* Right Area: Interactive Database Query View (7 Cols) */}
          <div className="lg:col-span-7 flex flex-col gap-6">
            <div className="glass-panel p-6 rounded-2xl border border-white/5 flex flex-col flex-1 overflow-hidden">
              
              {/* Controls */}
              <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
                <h3 className="font-title font-bold text-slate-200 flex items-center gap-2">
                  <Database className="w-4 h-4 text-accent-purple" />
                  Rider Relational Logs DB
                </h3>

                <div className="flex flex-wrap items-center gap-3">
                  {/* Search */}
                  <div className="relative">
                    <input
                      type="text"
                      placeholder="Search rider/record ID..."
                      value={searchTerm}
                      onChange={(e) => setSearchTerm(e.target.value)}
                      className="bg-black/60 border border-white/10 rounded-lg py-1.5 pl-8 pr-3 text-xs text-slate-200 focus:border-accent-purple focus:outline-none w-48 font-mono"
                    />
                    <Search className="w-3.5 h-3.5 text-slate-500 absolute left-2.5 top-2.5" />
                  </div>

                  {/* Filter */}
                  <div className="relative">
                    <select
                      value={filterType}
                      onChange={(e) => setFilterType(e.target.value as any)}
                      className="bg-black/60 border border-white/10 rounded-lg py-1.5 pl-3 pr-8 text-xs text-slate-200 focus:border-accent-purple focus:outline-none appearance-none cursor-pointer"
                    >
                      <option value="ALL" className="bg-slate-900 text-slate-200">ALL STATUS</option>
                      <option value="COMPLETED" className="bg-slate-900 text-slate-200">COMPLETED</option>
                      <option value="FLAGGED" className="bg-slate-900 text-slate-200">FLAGGED</option>
                    </select>
                    <ChevronDown className="w-3.5 h-3.5 text-slate-400 absolute right-2.5 top-1/2 -translate-y-1/2 pointer-events-none" />
                  </div>
                </div>
              </div>

              {/* Data Table */}
              <div className="flex-1 overflow-y-auto max-h-[380px] pr-1">
                <table className="w-full text-left text-xs border-collapse">
                  <thead>
                    <tr className="border-b border-white/10 text-slate-500 font-mono">
                      <th className="py-3 px-2">Record ID</th>
                      <th className="py-3 px-2">Rider</th>
                      <th className="py-3 px-2">Date</th>
                      <th className="py-3 px-2">Score</th>
                      <th className="py-3 px-2">Threats</th>
                      <th className="py-3 px-2 text-right">Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredRecords.map((r) => (
                      <tr key={r.id} className="border-b border-white/5 hover:bg-white/[0.02] transition-all">
                        <td className="py-3 px-2 font-mono text-accent-purple font-bold">{r.id}</td>
                        <td className="py-3 px-2 font-bold text-slate-200">{r.riderName}</td>
                        <td className="py-3 px-2 text-slate-400 font-mono">{r.date}</td>
                        <td className="py-3 px-2 font-bold">
                          <span className={r.safetyScore < 80 ? "text-accent-pink" : r.safetyScore < 95 ? "text-accent-yellow" : "text-accent-green"}>
                            {r.safetyScore}/100
                          </span>
                        </td>
                        <td className="py-3 px-2 text-slate-300 font-mono">{r.threatsLogged}</td>
                        <td className="py-3 px-2 text-right">
                          <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                            r.status === "COMPLETED" ? "bg-accent-green/10 text-accent-green" : "bg-accent-red/10 text-accent-red"
                          }`}>
                            {r.status}
                          </span>
                        </td>
                      </tr>
                    ))}
                    {filteredRecords.length === 0 && (
                      <tr>
                        <td colSpan={6} className="text-center py-6 text-slate-600 italic">
                          No matching logs found in records store.
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>

            </div>
          </div>

        </div>

      </main>
    </div>
  );
}
