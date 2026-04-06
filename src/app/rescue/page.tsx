import type { Metadata } from "next";
import { Header } from "@/components/layout/Header";
import { Footer } from "@/components/layout/Footer";
import { RescueSteps } from "@/components/RescueSteps";
import { TerminalBlock } from "@/components/ui/TerminalBlock";
import { SectionHeader } from "@/components/ui/SectionHeader";
import { GridBackground } from "@/components/effects";

export const metadata: Metadata = {
  title: "Rescue Protocol — How ClawICU Fixes OpenClaw",
  description:
    "ClawICU's 6-phase rescue protocol: crash-safe doctor check (30s timeout), 20 diagnostic checks, triage by severity, interactive treatment menu, targeted repairs with auto-backup, and verification.",
  alternates: {
    canonical: "/rescue/",
  },
  openGraph: {
    title: "Rescue Protocol — How ClawICU Fixes OpenClaw",
    description:
      "6 phases from detection to verified repair. Run: curl -fsSL https://xagent.icu/r | sh",
    type: "article",
  },
};

export default function RescuePage() {
  return (
    <>
      <Header />
      <GridBackground />
      <main className="min-h-screen pt-24 pb-16 relative z-10">
        <div className="mx-auto max-w-4xl px-6">
          <SectionHeader
            badge="6-Phase Rescue Process"
            title="How ClawICU Rescues"
            description="From one command to full diagnosis, ClawICU follows a battle-tested 6-phase process to identify and fix your OpenClaw installation."
          />

          <RescueSteps />

          <div className="mt-16 text-center">
            <p className="text-muted-foreground mb-6">Ready to run the rescue?</p>
            <div className="inline-flex items-center justify-center">
              <TerminalBlock command="curl -fsSL https://xagent.icu/r | sh" />
            </div>
          </div>
        </div>
      </main>
      <Footer />
    </>
  );
}
