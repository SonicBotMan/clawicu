"use client";
import {
  ChevronDown, Shield, Syringe, Stethoscope, HeartPulse,
  Activity, BriefcaseMedical, AlertTriangle,
} from "lucide-react";
import { TerminalBlock } from "@/components/ui/TerminalBlock";
import { useEffect, useState } from "react";

/* Floating medical equipment decorations */
const medicalItems = [
  { Icon: Syringe,         top: "12%",  left: "6%",   size: 28, rotate: "-30deg", delay: "0s",    opacity: 0.12 },
  { Icon: Stethoscope,     top: "18%",  right: "8%",  size: 32, rotate: "15deg",  delay: "0.4s",  opacity: 0.10 },
  { Icon: BriefcaseMedical,top: "70%",  left: "4%",   size: 30, rotate: "-10deg", delay: "0.8s",  opacity: 0.11 },
  { Icon: HeartPulse,      top: "75%",  right: "6%",  size: 26, rotate: "20deg",  delay: "1.2s",  opacity: 0.13 },
  { Icon: Activity,        top: "40%",  left: "2%",   size: 22, rotate: "0deg",   delay: "0.6s",  opacity: 0.09 },
  { Icon: Syringe,         top: "55%",  right: "3%",  size: 20, rotate: "45deg",  delay: "1s",    opacity: 0.09 },
];

/* Inline SVG: surgical clamp / hemostat */
function HemostatIcon({ className, style }: { className?: string; style?: React.CSSProperties }) {
  return (
    <svg viewBox="0 0 24 24" className={className} style={style} fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M4 20 L11 13" />
      <path d="M11 13 L13 11" />
      <path d="M13 11 C14 9 16 8 18 9 C20 10 21 12 20 14 C19 16 17 17 15 16 L13 11Z" />
      <path d="M6 22 L4 20 L2 22" />
      <circle cx="18.5" cy="11.5" r="1" fill="currentColor" strokeWidth="0" />
    </svg>
  );
}

/* Inline SVG: large medical cross for background */
function MedicalCross({ className, style }: { className?: string; style?: React.CSSProperties }) {
  return (
    <svg viewBox="0 0 100 100" className={className} style={style} fill="currentColor">
      <rect x="35" y="5"  width="30" height="90" rx="6" />
      <rect x="5"  y="35" width="90" height="30" rx="6" />
    </svg>
  );
}

/* ECG / heartbeat SVG line */
function ECGLine() {
  return (
    <svg
      viewBox="0 0 600 80"
      className="absolute inset-x-0 bottom-[15%] opacity-[0.07] pointer-events-none"
      fill="none"
      preserveAspectRatio="none"
    >
      <path
        d="M0,40 L80,40 L100,10 L120,70 L140,5 L160,75 L175,40 L260,40 L280,10 L300,70 L320,5 L340,75 L355,40 L440,40 L460,10 L480,70 L500,5 L520,75 L535,40 L600,40"
        stroke="#00e87a"
        strokeWidth="2"
        style={{
          strokeDasharray: 800,
          strokeDashoffset: 800,
          animation: "ecg-run 4s linear infinite",
        }}
      />
    </svg>
  );
}

export function Hero() {
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);

  return (
    <section className="relative flex min-h-screen flex-col items-center justify-center overflow-hidden px-6 pb-12 pt-28">

      {/* Grid background */}
      <div
        className="pointer-events-none absolute inset-0 opacity-[0.025]"
        style={{
          backgroundImage: `linear-gradient(rgba(0,232,122,0.15) 1px, transparent 1px), linear-gradient(90deg, rgba(0,232,122,0.15) 1px, transparent 1px)`,
          backgroundSize: "50px 50px",
        }}
      />

      {/* Large ghost medical crosses */}
      <MedicalCross className="pointer-events-none absolute -left-24 top-10 w-80 text-primary/[0.04] animate-cross-spin" />
      <MedicalCross className="pointer-events-none absolute -right-20 bottom-20 w-64 text-accent/[0.04]" style={{ animationDuration: "30s", animationDirection: "reverse" }} />

      {/* Floating medical equipment icons */}
      {mounted && medicalItems.map((item, i) => (
        <div
          key={i}
          className="pointer-events-none absolute text-primary"
          style={{
            top: item.top,
            left: "left" in item ? item.left : undefined,
            right: "right" in item ? item.right : undefined,
            opacity: item.opacity,
            transform: `rotate(${item.rotate})`,
            animation: `float 6s ease-in-out ${item.delay} infinite`,
          }}
        >
          <item.Icon size={item.size} strokeWidth={1.2} />
        </div>
      ))}

      {/* Floating hemostat clamps */}
      <HemostatIcon className="pointer-events-none absolute right-[12%] top-[30%] w-8 text-accent opacity-[0.11]" style={{ transform: "rotate(-15deg)", animation: "float 7s ease-in-out 0.3s infinite" }} />
      <HemostatIcon className="pointer-events-none absolute left-[14%] bottom-[25%] w-7 text-accent opacity-[0.09]" style={{ transform: "rotate(30deg)", animation: "float 8s ease-in-out 1.1s infinite" }} />

      {/* ECG heart line */}
      <ECGLine />

      {/* Ambient glows */}
      <div className="pointer-events-none absolute left-1/4 top-1/3 h-80 w-80 rounded-full bg-primary/10 blur-[120px]" />
      <div className="pointer-events-none absolute right-1/4 bottom-1/3 h-64 w-64 rounded-full bg-accent/8 blur-[100px]" />
      <div className="pointer-events-none absolute bottom-0 left-0 right-0 h-32 bg-gradient-to-t from-background to-transparent" />

      {/* Content */}
      <div className="relative z-10 flex max-w-5xl flex-col items-center text-center">

        {/* Emergency alert badge */}
        <div
          className="animate-fade-up mb-6 inline-flex items-center gap-3 rounded-full border px-5 py-2 backdrop-blur-sm badge-critical"
          style={{ animationDelay: "0.05s" }}
        >
          <AlertTriangle className="h-3.5 w-3.5 animate-heartbeat text-[#ff6060]" />
          <span className="font-mono text-xs font-medium tracking-widest uppercase text-[#ff9090]">
            Emergency Rescue System
          </span>
          <span className="mx-1 h-3 w-px bg-[#ff4d4d]/40" />
          <span className="h-2 w-2 rounded-full bg-[#ff4d4d] animate-vital-blink" />
          <span className="font-mono text-xs text-[#ff7070]">ACTIVE</span>
        </div>

        {/* Title */}
        <h1
          className="animate-fade-up text-center font-heading text-5xl font-extrabold tracking-tight sm:text-6xl md:text-7xl lg:text-8xl"
          style={{ animationDelay: "0.1s" }}
        >
          <span className="text-foreground">Claw</span>
          <span
            className="bg-clip-text text-transparent"
            style={{
              backgroundImage: "linear-gradient(90deg, #ff4d4d, #ff2d2d, #ff6060, #ff4d4d)",
              backgroundSize: "200% 200%",
              animation: "gradient-shift 4s ease-in-out infinite",
            }}
          >
            ICU
          </span>
        </h1>

        {/* Subtitle with monitor-style */}
        <div
          className="animate-fade-up mt-5 flex items-center gap-3"
          style={{ animationDelay: "0.18s" }}
        >
          <div className="h-px w-12 bg-gradient-to-r from-transparent to-primary/60" />
          <p className="font-mono text-sm font-medium uppercase tracking-[0.2em] text-primary/80">
            OpenClaw Emergency Rescue
          </p>
          <div className="h-px w-12 bg-gradient-to-l from-transparent to-primary/60" />
        </div>

        <p
          className="animate-fade-up mt-6 max-w-2xl text-base text-muted-foreground leading-relaxed sm:text-lg"
          style={{ animationDelay: "0.25s" }}
        >
          Diagnose failures, stabilize processes, and revive your OpenClaw instance —
          all from one command. Like an ICU for your AI gateway.
        </p>

        {/* Terminal command */}
        <div
          className="animate-fade-up mt-8 w-full max-w-xl"
          style={{ animationDelay: "0.3s" }}
        >
          <TerminalBlock command="curl -fsSL https://xagent.icu/r | sh" />
        </div>

        {/* CTA Buttons */}
        <div
          className="animate-fade-up mt-10 flex flex-wrap items-center justify-center gap-4"
          style={{ animationDelay: "0.4s" }}
        >
          <a
            href="#examination"
            className="group flex items-center gap-2.5 rounded-xl bg-primary px-7 py-3.5 text-sm font-semibold text-primary-foreground shadow-lg shadow-primary/25 transition-all hover:bg-primary/90 hover:shadow-xl hover:shadow-primary/40 hover:-translate-y-0.5 animate-siren"
            style={{ animationDuration: "2s" }}
          >
            <HeartPulse className="h-4 w-4" />
            Start Rescue
          </a>
          <a
            href="#treatment"
            className="group flex items-center gap-2.5 rounded-xl border border-[rgba(0,232,122,0.2)] bg-card/60 px-7 py-3.5 text-sm font-semibold text-foreground backdrop-blur-sm transition-all hover:border-[rgba(0,232,122,0.4)] hover:bg-card/80"
          >
            <Activity className="h-4 w-4 text-[#00e87a]" />
            View Protocol
          </a>
        </div>

        {/* Vital signs stats panel */}
        <div
          className="animate-fade-up mt-16 relative overflow-hidden rounded-2xl border border-border/40 bg-card/50 backdrop-blur-sm px-8 py-5 medical-scanline"
          style={{ animationDelay: "0.5s" }}
        >
          <div className="absolute inset-x-0 top-0 h-px bg-gradient-to-r from-transparent via-[#00e87a]/40 to-transparent" />
          <div className="flex items-center gap-8 text-center">
            <div className="flex flex-col items-center px-4">
              <span className="font-heading text-3xl font-bold text-[#00e87a] sm:text-4xl">25</span>
              <span className="mt-1 text-xs text-muted-foreground sm:text-sm">Issue Guides</span>
            </div>
            <div className="h-10 w-px bg-border/50" />
            <div className="flex flex-col items-center px-4">
              <span className="font-heading text-3xl font-bold text-primary sm:text-4xl">20</span>
              <span className="mt-1 text-xs text-muted-foreground sm:text-sm">Diagnostic Checks</span>
            </div>
            <div className="h-10 w-px bg-border/50" />
            <div className="flex flex-col items-center px-4">
              <span className="font-heading text-3xl font-bold text-foreground sm:text-4xl">6</span>
              <span className="mt-1 text-xs text-muted-foreground sm:text-sm">Rescue Phases</span>
            </div>
          </div>
          <div className="absolute inset-x-0 bottom-0 h-px bg-gradient-to-r from-transparent via-primary/30 to-transparent" />
        </div>

        {/* Feature chips */}
        <div
          className="animate-fade-up mt-10 flex items-center gap-5"
          style={{ animationDelay: "0.6s" }}
        >
          {[
            { icon: Shield,          label: "Open Source",   color: "text-[#00e87a]" },
            { icon: Syringe,         label: "Zero Tracking", color: "text-primary" },
            { icon: BriefcaseMedical,label: "Instant Fix",   color: "text-[#3b9eff]" },
          ].map((item) => (
            <div key={item.label} className="flex items-center gap-2 text-xs text-muted-foreground">
              <item.icon className={`h-3.5 w-3.5 ${item.color}`} strokeWidth={1.5} />
              <span>{item.label}</span>
            </div>
          ))}
        </div>
      </div>

      <div className="absolute bottom-8 left-1/2 -translate-x-1/2 animate-bounce">
        <ChevronDown className="h-5 w-5 text-muted-foreground" />
      </div>
    </section>
  );
}
