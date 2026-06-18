"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/lib/AuthContext";
import LandingPage from "./landing/page";

/**
 * Root page — shows the landing page for unauthenticated visitors.
 * Authenticated users are silently redirected to their portal.
 */
export default function Home() {
  const { user, isLoading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (isLoading || !user) return;
    if (user.role === "admin") {
      router.replace("/admin");
    } else {
      router.replace("/user");
    }
  }, [user, isLoading, router]);

  // Always render the landing page while auth resolves or for guests
  return <LandingPage />;
}
