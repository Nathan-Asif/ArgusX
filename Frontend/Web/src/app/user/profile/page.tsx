"use client";

import { useState } from "react";
import Sidebar from "@/components/Sidebar";
import { useAuth } from "@/lib/AuthContext";
import {
  User,
  Mail,
  Shield,
  Calendar,
  Lock,
  Save,
  CheckCircle,
  ChevronDown,
} from "lucide-react";

export default function UserProfile() {
  const { user, updateUser } = useAuth();

  const [name, setName] = useState(user?.name ?? "Rider Neo");
  const [email] = useState(user?.email ?? "rider@argusx.io");
  const [helmet, setHelmet] = useState("AGV SportModular Carbon");
  const [saved, setSaved] = useState(false);

  // Mock password change
  const [currentPw, setCurrentPw] = useState("");
  const [newPw, setNewPw] = useState("");
  const [confirmPw, setConfirmPw] = useState("");
  const [pwError, setPwError] = useState<string | null>(null);
  const [pwSaved, setPwSaved] = useState(false);

  const handleProfileSave = async () => {
    await updateUser({ name });
    setSaved(true);
    setTimeout(() => setSaved(false), 2500);
  };

  const handlePasswordChange = () => {
    setPwError(null);
    setPwSaved(false);
    if (!currentPw || !newPw || !confirmPw) {
      setPwError("All password fields are required.");
      return;
    }
    if (newPw !== confirmPw) {
      setPwError("New passwords do not match.");
      return;
    }
    if (newPw.length < 6) {
      setPwError("Password must be at least 6 characters.");
      return;
    }
    setPwSaved(true);
    setCurrentPw("");
    setNewPw("");
    setConfirmPw("");
    setTimeout(() => setPwSaved(false), 2500);
  };

  return (
    <div className="flex flex-row min-h-screen">
      <Sidebar />

      <main className="flex-1 flex flex-col min-w-0 overflow-y-auto p-8 relative z-10">
        {/* Header */}
        <header className="flex flex-col md:flex-row md:items-center md:justify-between pb-6 border-b border-white/5 mb-8 gap-4">
          <div>
            <h1 className="font-title text-3xl font-black tracking-wide text-white">
              Profile &amp; Account
            </h1>
            <p className="text-xs text-slate-400 mt-1">
              Manage personal information, system preferences &amp; security
              credentials
            </p>
          </div>
        </header>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
          {/* Left: Avatar & Info Summary */}
          <div className="lg:col-span-4 flex flex-col gap-6">
            <div className="glass-panel tech-panel p-8 rounded-none border border-white/5 flex flex-col items-center text-center">
              {/* Avatar */}
              <div className="w-24 h-24 rounded-none bg-gradient-to-br from-accent-purple to-accent-pink p-[3px] mb-4">
                <div className="w-full h-full bg-black rounded-none flex items-center justify-center text-3xl font-black text-white font-title">
                  {name
                    .split(" ")
                    .map((n) => n[0])
                    .join("")
                    .slice(0, 2)}
                </div>
              </div>

              <h3 className="font-bold text-white text-lg">{name}</h3>
              <p className="text-xs text-slate-500 font-mono mt-1">{email}</p>

              {/* Role Badge */}
              <div className="mt-4 px-3 py-1 rounded-none bg-accent-purple/10 border border-accent-purple/20 text-[10px] font-bold text-accent-purple uppercase tracking-wider">
                {user?.role === "admin" ? "Administrator" : "Operator"}
              </div>

              {/* Account Details */}
              <div className="w-full mt-6 space-y-3 text-left">
                <div className="flex items-center gap-3 text-xs text-slate-400 bg-white/[0.01] border border-white/5 p-3 rounded-none">
                  <Calendar className="w-4 h-4 text-slate-500 shrink-0" />
                  <div>
                    <div className="text-[10px] text-slate-300 font-title uppercase tracking-wider">
                      Joined
                    </div>
                    <div className="text-slate-300 font-bold">
                      January 15, 2026
                    </div>
                  </div>
                </div>
                <div className="flex items-center gap-3 text-xs text-slate-400 bg-white/[0.01] border border-white/5 p-3 rounded-none">
                  <Shield className="w-4 h-4 text-slate-500 shrink-0" />
                  <div>
                    <div className="text-[10px] text-slate-300 font-title uppercase tracking-wider">
                      Account Status
                    </div>
                    <div className="text-accent-green font-bold flex items-center gap-1.5">
                      <span className="w-1.5 h-1.5 rounded-none bg-accent-green" />
                      Active &amp; Verified
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Right: Edit Forms */}
          <div className="lg:col-span-8 flex flex-col gap-6">
            {/* Profile Info */}
            <div className="glass-panel tech-panel p-6 rounded-none border border-white/5">
              <h3 className="font-title font-bold text-slate-200 mb-6 flex items-center gap-2">
                <User className="w-4.5 h-4.5 text-accent-purple" />
                Personal Information
              </h3>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                <div className="space-y-1.5">
                  <label className="text-[10px] text-slate-300 font-title uppercase tracking-wider tracking-wider block">
                    Display Name
                  </label>
                  <input
                    type="text"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    className="glass-input"
                  />
                </div>
                <div className="space-y-1.5">
                  <label className="text-[10px] text-slate-300 font-title uppercase tracking-wider tracking-wider block">
                    Email Address
                  </label>
                  <div className="relative">
                    <Mail className="w-4 h-4 text-slate-500 absolute left-3.5 top-1/2 -translate-y-1/2" />
                    <input
                      type="email"
                      value={email}
                      disabled
                      className="glass-input pl-10"
                    />
                  </div>
                </div>
                <div className="space-y-1.5 md:col-span-2">
                  <label className="text-[10px] text-slate-300 font-title uppercase tracking-wider tracking-wider block">
                    Calibrated Helmet Model
                  </label>
                  <div className="relative">
                    <select
                      value={helmet}
                      onChange={(e) => setHelmet(e.target.value)}
                      className="glass-input appearance-none cursor-pointer pr-10"
                    >
                      <option
                        value="AGV SportModular Carbon"
                        className="bg-slate-900 text-slate-200"
                      >
                        AGV SportModular Carbon
                      </option>
                      <option
                        value="Shoei RF-1400 SmartSentry"
                        className="bg-slate-900 text-slate-200"
                      >
                        Shoei RF-1400 SmartSentry
                      </option>
                      <option
                        value="Arai Regent-X Edge"
                        className="bg-slate-900 text-slate-200"
                      >
                        Arai Regent-X Edge
                      </option>
                    </select>
                    <ChevronDown className="w-4 h-4 text-slate-400 absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none" />
                  </div>
                </div>
              </div>

              <div className="flex items-center justify-between mt-6 pt-4 border-t border-white/5">
                {saved && (
                  <span className="flex items-center gap-1.5 text-accent-green text-xs font-bold">
                    <CheckCircle className="w-3.5 h-3.5" />
                    Profile updated
                  </span>
                )}
                {!saved && <span />}
                <button
                  onClick={handleProfileSave}
                  className="btn-primary"
                >
                  <Save className="w-3.5 h-3.5" />
                  Save Changes
                </button>
              </div>
            </div>

            {/* Change Password */}
            <div className="glass-panel tech-panel p-6 rounded-none border border-white/5">
              <h3 className="font-title font-bold text-slate-200 mb-6 flex items-center gap-2">
                <Lock className="w-4.5 h-4.5 text-accent-purple" />
                Security — Change Password
              </h3>

              <div className="space-y-4">
                <div className="space-y-1.5">
                  <label className="text-[10px] text-slate-300 font-title uppercase tracking-wider tracking-wider block">
                    Current Password
                  </label>
                  <input
                    type="password"
                    value={currentPw}
                    onChange={(e) => setCurrentPw(e.target.value)}
                    placeholder="••••••••"
                    className="glass-input max-w-md"
                  />
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-1.5">
                    <label className="text-[10px] text-slate-300 font-title uppercase tracking-wider tracking-wider block">
                      New Password
                    </label>
                    <input
                      type="password"
                      value={newPw}
                      onChange={(e) => setNewPw(e.target.value)}
                      placeholder="••••••••"
                      className="glass-input"
                    />
                  </div>
                  <div className="space-y-1.5">
                    <label className="text-[10px] text-slate-300 font-title uppercase tracking-wider tracking-wider block">
                      Confirm New Password
                    </label>
                    <input
                      type="password"
                      value={confirmPw}
                      onChange={(e) => setConfirmPw(e.target.value)}
                      placeholder="••••••••"
                      className="glass-input"
                    />
                  </div>
                </div>

                {pwError && (
                  <div className="flex items-center gap-2 bg-accent-red/10 border border-accent-red/20 text-accent-red text-xs p-3 rounded-none max-w-md">
                    {pwError}
                  </div>
                )}

                {pwSaved && (
                  <div className="flex items-center gap-2 text-accent-green text-xs font-bold">
                    <CheckCircle className="w-3.5 h-3.5" />
                    Password changed successfully
                  </div>
                )}

                <button
                  onClick={handlePasswordChange}
                  className="btn-primary mt-2"
                >
                  <Lock className="w-3.5 h-3.5" />
                  Update Password
                </button>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
