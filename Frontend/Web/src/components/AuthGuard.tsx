"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useAuth, type UserRole } from "@/lib/AuthContext";
import { ShieldAlert, Loader2 } from "lucide-react";

interface AuthGuardProps {
  children: React.ReactNode;
  /** If set, the user must have this role (admin always passes). */
  requiredRole?: UserRole;
}

/**
 * Wraps page content and redirects unauthenticated (or under-privileged)
 * users to /login.  Shows a branded loading state while session hydrates.
 */
export default function AuthGuard({ children, requiredRole }: AuthGuardProps) {
  const { user, isLoading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (isLoading) return;
    if (!user) {
      router.replace("/login");
      return;
    }
    // Admin can access everything; users can only access "user" pages
    if (requiredRole === "admin" && user.role !== "admin") {
      router.replace("/login");
    }
  }, [user, isLoading, requiredRole, router]);

  if (isLoading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen gap-4">
        <div className="w-16 h-16 rounded-full bg-gradient-to-tr from-accent-purple via-black to-accent-pink p-0.5 animate-iris-breathe flex items-center justify-center">
          <div className="w-full h-full bg-black rounded-full flex items-center justify-center">
            <ShieldAlert className="w-7 h-7 text-accent-purple animate-pulse" />
          </div>
        </div>
        <div className="flex items-center gap-2 text-xs text-slate-500 font-mono">
          <Loader2 className="w-3.5 h-3.5 animate-spin" />
          VERIFYING SESSION
        </div>
      </div>
    );
  }

  if (!user) return null;
  if (requiredRole === "admin" && user.role !== "admin") return null;

  return <>{children}</>;
}
