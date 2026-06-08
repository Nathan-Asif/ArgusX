"use client";

import AuthGuard from "@/components/AuthGuard";

export default function UserLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  // Both "user" and "admin" can access the rider portal
  return <AuthGuard>{children}</AuthGuard>;
}
