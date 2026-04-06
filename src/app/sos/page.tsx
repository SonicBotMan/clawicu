import type { Metadata } from "next";
import { Header } from "@/components/layout/Header";
import { Footer } from "@/components/layout/Footer";
import { TerminalBlock } from "@/components/ui/TerminalBlock";
import { GridBackground } from "@/components/effects";
import { ShareSOSButton } from "@/components/ShareSOSButton";
import { HeartPulse, Syringe, Activity, ArrowRight, AlertTriangle } from "lucide-react";

export const metadata: Metadata = {
  title: "🚨 SOS — My OpenClaw Just Crashed | ClawICU",
  description:
    "OpenClaw crashed? ClawICU diagnoses and auto-repairs in seconds. Run: curl -fsSL https://xagent.icu/r | sh — 20 diagnostic checks, 12 repair modules, zero configuration.",
  alternates: { canonical: "/sos/" },
  openGraph: {
    title: "🚨 SOS — My OpenClaw Just Crashed!",
    description:
      "Running emergency rescue... ClawICU auto-diagnoses plugin crashes, version mismatches, gateway failures and more. One command fixes everything.",
    type: "website",
    url: "https://xagent.icu/sos/",
    images: [
      {
        url: "/sos-card.png",
        width: 1200,
        height: 630,
        alt: "ClawICU SOS — OpenClaw Emergency Rescue",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "🚨 SOS — My OpenClaw Just Crashed!",
    description:
      "Running emergency rescue... ClawICU auto-diagnoses and auto-repairs your OpenClaw in seconds.",
    images: ["/sos-card.png"],
  },
};

const checks = [
  "Config file corruption",
  "Plugin / SDK crashes",
  "Gateway offline",
  "Version mismatch",
  "Missing credentials",
  "Daemon not installed",
  "Channel policy issues",
  "plugins.allow empty",
];

export default function SOSPage() {
  return (
    <>
      <Header />
      <GridBackground />
      <main className="relative z-10 min-h-screen overflow-hidden">

        {/* Hero — full-width emergency card */}
        <section className="relative overflow-hidden border-b border-primary/20 bg-[#030609]/90 pt-28 pb-0">
          {/* Caution stripes — top */}
          <div className="absolute inset-x-0 top-0 h-2"
               style={{ background: "repeating-linear-gradient(45deg, #ff4d4d 0px, #ff4d4d 12px, #0a0a0a 12px, #0a0a0a 24px)" }} />

          {/* Background ECG */}
          <svg viewBox="0 0 1200 60" className="absolute inset-x-0 bottom-0 opacity-[0.07] pointer-events-none" fill="none" preserveAspectRatio="none">
            <path d="M0,30 L200,30 L220,8 L240,52 L260,4 L280,56 L300,30 L500,30 L520,8 L540,52 L560,4 L580,56 L600,30 L800,30 L820,8 L840,52 L860,4 L880,56 L900,30 L1200,30"
              stroke="#ff4d4d" strokeWidth="2"
              style={{ strokeDasharray: 2000, strokeDashoffset: 2000, animation: "ecg-run 5s linear infinite" }} />
          </svg>

          {/* Ambient glow */}
          <div className="pointer-events-none absolute left-1/4 top-0 h-80 w-80 rounded-full bg-primary/15 blur-[120px]" />

          <div className="relative z-10 mx-auto max-w-5xl px-6 pb-14">
            {/* SOS badge + share button */}
            <div className="mb-7 flex flex-wrap items-center gap-3">
              <span className="inline-flex items-center gap-2 rounded-full border border-primary/40 bg-primary/10 px-5 py-2 font-mono text-sm font-black uppercase tracking-widest text-primary animate-alert-flash">
                <AlertTriangle className="h-4 w-4 animate-heartbeat" />
                🚨 SOS — Emergency
              </span>
              <ShareSOSButton compact />
            </div>

            <h1 className="font-heading text-5xl font-extrabold tracking-tight text-foreground sm:text-6xl md:text-7xl">
              My OpenClaw{" "}
              <span className="text-primary">just crashed!</span>
            </h1>

            <p className="mt-5 max-w-2xl text-lg text-muted-foreground leading-relaxed">
              Running ClawICU emergency rescue — 20 diagnostic checks, automatic repair,
              and full backup. Back online in minutes.
            </p>

            {/* Rescue command — big and prominent */}
            <div className="mt-8 max-w-2xl">
              <TerminalBlock command="curl -fsSL https://xagent.icu/r | sh" />
            </div>

            {/* Quick stats */}
            <div className="mt-8 flex flex-wrap gap-4">
              {[
                { icon: Activity,   label: "20 Diagnostic Checks", color: "#ff4d4d" },
                { icon: Syringe,    label: "12 Repair Modules",    color: "#ffb020" },
                { icon: HeartPulse, label: "Auto Backup Safety",   color: "#00e87a" },
              ].map((s) => (
                <div key={s.label} className="flex items-center gap-2 rounded-full px-3 py-1.5 font-mono text-xs"
                     style={{ background: `${s.color}12`, border: `1px solid ${s.color}28`, color: s.color }}>
                  <s.icon className="h-3.5 w-3.5" />
                  {s.label}
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* What ClawICU checks */}
        <section className="mx-auto w-full max-w-5xl px-6 py-16">
          <div className="mb-8 flex items-center gap-3">
            <div className="h-px flex-1 bg-border/30" />
            <span className="font-mono text-xs font-bold uppercase tracking-widest text-muted-foreground">
              Diagnostic Coverage
            </span>
            <div className="h-px flex-1 bg-border/30" />
          </div>
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            {checks.map((c, i) => (
              <div key={c}
                className="flex items-center gap-2.5 rounded-lg border border-border/40 bg-card/50 px-4 py-3 text-sm text-muted-foreground">
                <span className="font-mono text-[10px] text-primary/60 shrink-0">
                  {String(i + 1).padStart(2, "0")}
                </span>
                {c}
              </div>
            ))}
          </div>

          <div className="mt-10 flex flex-wrap gap-4 justify-center">
            <a href="/" className="flex items-center gap-2 rounded-xl border border-border/50 bg-card/60 px-6 py-3 text-sm font-medium text-foreground transition-all hover:border-primary/30">
              <HeartPulse className="h-4 w-4 text-primary" />
              Learn more about ClawICU
              <ArrowRight className="h-4 w-4" />
            </a>
            <a href="/rescue" className="flex items-center gap-2 rounded-xl bg-primary px-6 py-3 text-sm font-semibold text-background shadow-lg shadow-primary/25 transition-all hover:bg-primary/90">
              <Syringe className="h-4 w-4" />
              View Rescue Protocol
            </a>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
