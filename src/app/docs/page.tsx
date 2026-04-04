import type { Metadata } from "next";
import { Header } from "@/components/layout/Header";
import { Footer } from "@/components/layout/Footer";
import { SectionHeader } from "@/components/ui/SectionHeader";
import { GridBackground } from "@/components/effects";
import { ISSUES } from "@/content/issues";
import Link from "next/link";
import {
  FileWarning,
  Puzzle,
  WifiOff,
  ShieldAlert,
  KeyRound,
  Network,
  Cpu,
  HardDrive,
  Lock,
  Database,
  Gauge,
  RefreshCcw,
  Power,
  UserCheck,
  MessageSquare,
  ShieldOff,
  LayoutDashboard,
  HeartOff,
  Globe,
  Terminal,
} from "lucide-react";
import type { LucideIcon } from "lucide-react";

const iconMap: Record<string, LucideIcon> = {
  FileWarning,
  Puzzle,
  WifiOff,
  ShieldAlert,
  KeyRound,
  Network,
  Cpu,
  HardDrive,
  Lock,
  Database,
  Gauge,
  RefreshCcw,
  Power,
  UserCheck,
  MessageSquare,
  ShieldOff,
  LayoutDashboard,
  HeartOff,
  Globe,
  Terminal,
};

export const metadata: Metadata = {
  title: "Issue Encyclopedia",
  description:
    "24 OpenClaw issue guides covering pairing, channel auth, cron, heartbeat, and more. Diagnose and fix with step-by-step solutions.",
  alternates: {
    canonical: "/docs/",
  },
};

export default function DocsPage() {
  return (
    <>
      <Header />
      <GridBackground />
      <main className="min-h-screen pt-24 pb-16 relative z-10">
        <div className="mx-auto max-w-4xl px-6">
          <SectionHeader
            badge="Issue Encyclopedia"
            title="Diagnose & Fix"
            description="Comprehensive guides to diagnose and fix common OpenClaw problems"
          />

          <div className="grid gap-4 sm:grid-cols-2">
            {ISSUES.map((issue) => {
              const Icon = iconMap[issue.icon] || FileWarning;
              return (
                <Link
                  key={issue.slug}
                  href={`/docs/${issue.slug}`}
                  className="group relative overflow-hidden rounded-2xl border border-border bg-card backdrop-blur-[12px] p-6 transition-all duration-300 hover:border-primary/30 hover:shadow-[0_0_30px_rgba(255,77,77,0.15)] hover:-translate-y-0.5"
                >
                  <div className="absolute inset-0 bg-gradient-to-br from-primary/5 via-transparent to-accent/5 opacity-0 transition-opacity duration-500 group-hover:opacity-100" />

                  <div className="relative">
                    <div className="mb-4 flex h-10 w-10 items-center justify-center rounded-xl bg-primary/10 text-primary ring-1 ring-primary/20 transition-all duration-200 group-hover:bg-primary/15 group-hover:ring-primary/40 group-hover:scale-110">
                      <Icon className="h-5 w-5" />
                    </div>
                    <h3 className="font-heading font-semibold text-[#f0f4ff] group-hover:text-primary transition-colors">
                      {issue.title}
                    </h3>
                    <p className="mt-2 text-sm text-muted-foreground line-clamp-2">
                      {issue.description}
                    </p>
                  </div>
                </Link>
              );
            })}
          </div>
        </div>
      </main>
      <Footer />
    </>
  );
}
