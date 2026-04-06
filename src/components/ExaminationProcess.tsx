"use client";
import { Search, Stethoscope, Syringe, CheckCircle, ArrowRight } from "lucide-react";

const phases = [
  {
    icon: Search,
    step: "01",
    title: "Triage",
    description: "Rapid OpenClaw doctor scan. Detect plugin crashes, gateway hangs, and TypeError storms in under 30 s.",
    status: "ENTRY",
    statusColor: "badge-warning",
    accentColor: "#ffb020",
    delay: "0ms",
  },
  {
    icon: Stethoscope,
    step: "02",
    title: "Diagnose",
    description: "Run 20 independent check modules — config, gateway, plugins, SDK, credentials, daemon, ports, and more.",
    status: "SCAN",
    statusColor: "badge-critical",
    accentColor: "#ff4d4d",
    delay: "100ms",
  },
  {
    icon: Syringe,
    step: "03",
    title: "Treat",
    description: "Targeted repairs: disable broken plugins, restart gateway, populate plugins.allow, rebuild daemon services.",
    status: "REPAIR",
    statusColor: "badge-critical",
    accentColor: "#ff4d4d",
    delay: "200ms",
  },
  {
    icon: CheckCircle,
    step: "04",
    title: "Recover",
    description: "Verify all systems, confirm gateway heartbeat, and restore normal operation with a full backup in place.",
    status: "STABLE",
    statusColor: "badge-stable",
    accentColor: "#00e87a",
    delay: "300ms",
  },
];

export function ExaminationProcess() {
  return (
    <section id="examination" className="relative mx-auto w-full max-w-6xl px-6 py-24">

      {/* Section header */}
      <div className="mb-14 text-center">
        <div className="inline-flex items-center gap-3 mb-5">
          <div className="h-px w-16 bg-gradient-to-r from-transparent to-accent/50" />
          <span className="rounded-md border border-accent/30 bg-accent/10 px-4 py-1.5 font-mono text-xs font-bold uppercase tracking-widest text-accent">
            ⚕ Examination Room
          </span>
          <div className="h-px w-16 bg-gradient-to-l from-transparent to-accent/50" />
        </div>
        <h2 className="font-heading text-3xl font-bold tracking-tight text-foreground sm:text-4xl">
          System Rescue Protocol
        </h2>
        <p className="mx-auto mt-4 max-w-2xl text-base text-muted-foreground">
          A proven medical approach — from first symptom to full recovery
        </p>
      </div>

      {/* Phase cards */}
      <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
        {phases.map((phase, i) => {
          const Icon = phase.icon;
          return (
            <div
              key={phase.title}
              className="reveal group relative overflow-hidden rounded-xl border border-border/50 bg-card/60 backdrop-blur-[12px] p-6 transition-all duration-300 hover:-translate-y-1"
              style={{
                transitionDelay: phase.delay,
                boxShadow: `0 0 0 0 ${phase.accentColor}`,
                transition: "all 0.3s ease",
              }}
              onMouseEnter={(e) => {
                (e.currentTarget as HTMLElement).style.boxShadow = `0 0 24px ${phase.accentColor}22`;
                (e.currentTarget as HTMLElement).style.borderColor = `${phase.accentColor}44`;
              }}
              onMouseLeave={(e) => {
                (e.currentTarget as HTMLElement).style.boxShadow = "0 0 0 0 transparent";
                (e.currentTarget as HTMLElement).style.borderColor = "";
              }}
            >
              {/* Step number — hospital room number style */}
              <div className="mb-4 flex items-start justify-between">
                <span
                  className="font-heading text-5xl font-black leading-none"
                  style={{ color: `${phase.accentColor}18` }}
                >
                  {phase.step}
                </span>
                <span className={`rounded-full px-2.5 py-1 font-mono text-[10px] font-bold uppercase tracking-wider ${phase.statusColor}`}>
                  {phase.status}
                </span>
              </div>

              {/* Icon in clipboard-style container */}
              <div
                className="mb-4 flex h-11 w-11 items-center justify-center rounded-lg ring-1"
                style={{
                  background: `${phase.accentColor}14`,
                  border: `1px solid ${phase.accentColor}25`,
                }}
              >
                <Icon className="h-5 w-5" style={{ color: phase.accentColor }} />
              </div>

              <h3 className="mb-2 font-heading text-lg font-semibold text-foreground">
                {phase.title}
              </h3>
              <p className="text-sm text-muted-foreground leading-relaxed">
                {phase.description}
              </p>

              {/* Connector arrow — hidden on last item */}
              {i < phases.length - 1 && (
                <div className="absolute -right-3 top-1/2 z-10 hidden -translate-y-1/2 lg:flex">
                  <div
                    className="flex h-6 w-6 items-center justify-center rounded-full"
                    style={{ background: `${phase.accentColor}15`, border: `1px solid ${phase.accentColor}30` }}
                  >
                    <ArrowRight className="h-3 w-3" style={{ color: phase.accentColor }} />
                  </div>
                </div>
              )}

              {/* Accent bottom line */}
              <div
                className="absolute bottom-0 left-0 right-0 h-0.5 opacity-0 group-hover:opacity-100 transition-opacity"
                style={{ background: `linear-gradient(90deg, transparent, ${phase.accentColor}60, transparent)` }}
              />
            </div>
          );
        })}
      </div>
    </section>
  );
}
