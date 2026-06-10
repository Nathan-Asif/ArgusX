"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/lib/AuthContext";
import { ShieldAlert, Loader2 } from "lucide-react";

/**
 * Root page — redirects to the appropriate portal based on auth state.
 */
export default function Home() {
  const { user, isLoading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (isLoading) return;
    if (!user) {
      router.replace("/login");
    } else if (user.role === "admin") {
      router.replace("/admin");
    } else {
      router.replace("/user");
    }
  }, [user, isLoading, router]);

  return (
    <div className="flex flex-col items-center justify-center min-h-screen gap-4">
      <div className="w-16 h-16 rounded-none bg-gradient-to-tr from-accent-purple via-black to-accent-pink p-0.5 animate-iris-breathe flex items-center justify-center">
        <div className="w-full h-full bg-black rounded-none flex items-center justify-center">
          <ShieldAlert className="w-7 h-7 text-accent-purple animate-pulse" />
        </div>
      </div>
      <div className="flex items-center gap-2 text-xs text-slate-500 font-mono">
        <Loader2 className="w-3.5 h-3.5 animate-spin" />
        INITIALIZING PORTAL
      </div>
    </div>
  );
}
