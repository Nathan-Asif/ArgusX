"use client";

import {
  createContext,
  useContext,
  useEffect,
  useState,
  useCallback,
  type ReactNode,
} from "react";
import { supabase, isSupabaseConfigured } from "@/lib/supabase";

/* ──────────────────────────────────────────────────────────
   Types
   ────────────────────────────────────────────────────────── */
export type UserRole = "admin" | "user";

export interface ArgusUser {
  id: string;
  email: string;
  name: string;
  role: UserRole;
}

interface AuthContextValue {
  user: ArgusUser | null;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<{ error?: string }>;
  logout: () => Promise<void>;
  updateUser: (fields: Partial<ArgusUser>) => Promise<{ error?: string }>;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

/* ──────────────────────────────────────────────────────────
   Mock credentials (used when Supabase is not configured)
   ────────────────────────────────────────────────────────── */
const MOCK_USERS: Record<string, { password: string; user: ArgusUser }> = {
  "nathanasif@gmail.com": {
    password: "admin123",
    user: {
      id: "mock-admin-001",
      email: "nathanasif@gmail.com",
      name: "Nathan Asif",
      role: "admin",
    },
  },
  "admin@argusx.io": {
    password: "argusx2026",
    user: {
      id: "mock-admin-dev",
      email: "admin@argusx.io",
      name: "System Admin",
      role: "admin",
    },
  },
  "rider@argusx.io": {
    password: "rider2026",
    user: {
      id: "mock-user-001",
      email: "rider@argusx.io",
      name: "Rider Neo",
      role: "user",
    },
  },
};

const STORAGE_KEY = "argusx_session";

/* ──────────────────────────────────────────────────────────
   Provider
   ────────────────────────────────────────────────────────── */
export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<ArgusUser | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  /* ---------- restore session on mount ---------- */
  useEffect(() => {
    const restore = async () => {
      if (isSupabaseConfigured && supabase) {
        // Real Supabase session restore
        const { data } = await supabase.auth.getSession();
        if (data.session?.user) {
          const meta = data.session.user.user_metadata ?? {};
          setUser({
            id: data.session.user.id,
            email: data.session.user.email ?? "",
            name: meta.full_name ?? meta.name ?? data.session.user.email ?? "",
            role: (meta.role as UserRole) ?? "user",
          });
        }
        // Listen for auth state changes
        const { data: listener } = supabase.auth.onAuthStateChange(
          (_event, session) => {
            if (session?.user) {
              const meta = session.user.user_metadata ?? {};
              setUser({
                id: session.user.id,
                email: session.user.email ?? "",
                name:
                  meta.full_name ?? meta.name ?? session.user.email ?? "",
                role: (meta.role as UserRole) ?? "user",
              });
            } else {
              setUser(null);
            }
          }
        );
        setIsLoading(false);
        return () => listener.subscription.unsubscribe();
      } else {
        // Mock mode — restore from localStorage
        try {
          const stored = localStorage.getItem(STORAGE_KEY);
          if (stored) setUser(JSON.parse(stored) as ArgusUser);
        } catch { /* corrupt storage */ }
        setIsLoading(false);
      }
    };
    restore();
  }, []);

  /* ---------- login ---------- */
  const login = useCallback(
    async (email: string, password: string): Promise<{ error?: string }> => {
      if (isSupabaseConfigured && supabase) {
        const { data, error } = await supabase.auth.signInWithPassword({
          email,
          password,
        });
        if (error) return { error: error.message };
        if (data.user) {
          const meta = data.user.user_metadata ?? {};
          const u: ArgusUser = {
            id: data.user.id,
            email: data.user.email ?? "",
            name: meta.full_name ?? meta.name ?? data.user.email ?? "",
            role: (meta.role as UserRole) ?? "user",
          };
          setUser(u);
        }
        return {};
      }

      // Mock mode
      const entry = MOCK_USERS[email.toLowerCase()];
      if (!entry || entry.password !== password) {
        return { error: "Invalid credentials. Check email and password." };
      }
      setUser(entry.user);
      localStorage.setItem(STORAGE_KEY, JSON.stringify(entry.user));
      return {};
    },
    []
  );

  /* ---------- logout ---------- */
  const logout = useCallback(async () => {
    if (isSupabaseConfigured && supabase) {
      await supabase.auth.signOut();
    }
    setUser(null);
    localStorage.removeItem(STORAGE_KEY);
  }, []);

  /* ---------- update user ---------- */
  const updateUser = useCallback(
    async (fields: Partial<ArgusUser>): Promise<{ error?: string }> => {
      if (isSupabaseConfigured && supabase) {
        const { error } = await supabase.auth.updateUser({
          data: {
            full_name: fields.name,
            name: fields.name,
          },
        });
        if (error) return { error: error.message };
        
        setUser((prev) => {
          if (!prev) return null;
          return { ...prev, ...fields };
        });
        return {};
      }

      // Mock mode
      setUser((prev) => {
        if (!prev) return null;
        const updated = { ...prev, ...fields };
        localStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
        return updated;
      });
      return {};
    },
    []
  );

  return (
    <AuthContext.Provider value={{ user, isLoading, login, logout, updateUser }}>
      {children}
    </AuthContext.Provider>
  );
}

/* ──────────────────────────────────────────────────────────
   Hook
   ────────────────────────────────────────────────────────── */
export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within <AuthProvider>");
  return ctx;
}
