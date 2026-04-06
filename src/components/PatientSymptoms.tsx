"use client";
import {
  FileWarning, Puzzle, Wifi, Cpu, KeyRound,
  RefreshCcw, ShieldAlert, GitCompare,
} from "lucide-react";
import type { LucideIcon } from "lucide-react";

interface Symptom {
  icon: LucideIcon;
  title: string;
  severity: "critical" | "warning" | "info";
  code: string;
  description: string;
}

const symptoms: Symptom[] = [
  {
    icon: FileWarning,
    title: "Config Corruption",
    severity: "critical",
    code: "ERR-001",
    description: "Configuration file has invalid JSON5 syntax or is corrupted, preventing OpenClaw from starting",
  },
  {
    icon: Puzzle,
    title: "Plugin / SDK Failure",
    severity: "critical",
    code: "ERR-002",
    description: "Plugin crashes at activation, uses deprecated API (api.config.get), or plugin-sdk module is missing",
  },
  {
    icon: Wifi,
    title: "Gateway Offline",
    severity: "critical",
    code: "ERR-003",
    description: "OpenClaw gateway not running on port 18789, all agent channels unreachable",
  },
  {
    icon: Cpu,
    title: "Daemon Not Installed",
    severity: "warning",
    code: "WRN-004",
    description: "launchd (macOS) or systemd (Linux) service not registered — won't auto-start on boot",
  },
  {
    icon: KeyRound,
    title: "Missing Credentials",
    severity: "critical",
    code: "ERR-005",
    description: "Provider API keys (OpenAI, Anthropic, Google…) missing or empty in the credentials store",
  },
  {
    icon: GitCompare,
    title: "Version Mismatch",
    severity: "warning",
    code: "WRN-006",
    description: "CLI and Gateway running different versions after an upgrade — gateway restart resolves it",
  },
  {
    icon: ShieldAlert,
    title: "Channel Policy Issue",
    severity: "warning",
    code: "WRN-007",
    description: "Discord groupPolicy set to allowlist with requireMention=true causes DMs to be silently ignored",
  },
  {
    icon: RefreshCcw,
    title: "plugins.allow Empty",
    severity: "warning",
    code: "WRN-008",
    description: "All discovered plugins auto-load without an explicit allow list, creating a security risk",
  },
];

const severityConfig = {
  critical: {
    badge: "CRITICAL",
    badgeClass: "badge-critical",
    borderClass: "border-[rgba(255,45,45,0.25)] hover:border-[rgba(255,45,45,0.5)]",
    glowClass: "hover:shadow-[0_0_24px_rgba(255,45,45,0.15)]",
    iconBg: "bg-[rgba(255,45,45,0.12)] ring-[rgba(255,45,45,0.25)]",
    iconColor: "text-[#ff6060]",
    dotColor: "bg-[#ff2d2d]",
    dot: "animate-vital-blink",
  },
  warning: {
    badge: "WARNING",
    badgeClass: "badge-warning",
    borderClass: "border-[rgba(255,176,32,0.2)] hover:border-[rgba(255,176,32,0.4)]",
    glowClass: "hover:shadow-[0_0_24px_rgba(255,176,32,0.12)]",
    iconBg: "bg-[rgba(255,176,32,0.1)] ring-[rgba(255,176,32,0.2)]",
    iconColor: "text-[#ffb020]",
    dotColor: "bg-[#ffb020]",
    dot: "",
  },
  info: {
    badge: "INFO",
    badgeClass: "badge-stable",
    borderClass: "border-[rgba(0,232,122,0.15)] hover:border-[rgba(0,232,122,0.3)]",
    glowClass: "hover:shadow-[0_0_24px_rgba(0,232,122,0.1)]",
    iconBg: "bg-[rgba(0,232,122,0.1)] ring-[rgba(0,232,122,0.2)]",
    iconColor: "text-[#00e87a]",
    dotColor: "bg-[#00e87a]",
    dot: "",
  },
};

export function PatientSymptoms() {
  return (
    <section className="mx-auto w-full max-w-6xl px-6 py-24">

      {/* Section header — styled as hospital department sign */}
      <div className="mb-14 text-center">
        <div className="inline-flex items-center gap-3 mb-5">
          <div className="h-px w-16 bg-gradient-to-r from-transparent to-primary/50" />
          <span className="rounded-md border border-primary/30 bg-primary/10 px-4 py-1.5 font-mono text-xs font-bold uppercase tracking-widest text-primary">
            🏥 Patient Intake
          </span>
          <div className="h-px w-16 bg-gradient-to-l from-transparent to-primary/50" />
        </div>
        <h2 className="font-heading text-3xl font-bold tracking-tight text-foreground sm:text-4xl">
          Common Diagnoses
        </h2>
        <p className="mx-auto mt-4 max-w-2xl text-base text-muted-foreground">
          When OpenClaw exhibits these symptoms, ClawICU provides the diagnosis and treatment plan.
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {symptoms.map((symptom, i) => {
          const cfg = severityConfig[symptom.severity];
          const Icon = symptom.icon;
          return (
            <div
              key={symptom.title}
              className={`reveal group relative overflow-hidden rounded-xl border bg-card/50 backdrop-blur-[12px] p-5 transition-all duration-300 cursor-default ${cfg.borderClass} ${cfg.glowClass}`}
              style={{ transitionDelay: `${i * 60}ms` }}
            >
              {/* Top: severity badge + code */}
              <div className="flex items-center justify-between mb-4">
                <span className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 font-mono text-[10px] font-bold uppercase tracking-wider ${cfg.badgeClass}`}>
                  <span className={`h-1.5 w-1.5 rounded-full ${cfg.dotColor} ${cfg.dot}`} />
                  {cfg.badge}
                </span>
                <span className="font-mono text-[10px] text-muted-foreground/60">{symptom.code}</span>
              </div>

              {/* Icon */}
              <div className={`mb-3 flex h-10 w-10 items-center justify-center rounded-lg ring-1 ${cfg.iconBg}`}>
                <Icon className={`h-5 w-5 ${cfg.iconColor}`} />
              </div>

              {/* Title */}
              <h3 className={`mb-1.5 font-heading text-sm font-semibold text-foreground transition-colors group-hover:${cfg.iconColor}`}>
                {symptom.title}
              </h3>

              {/* Description */}
              <p className="text-xs text-muted-foreground leading-relaxed">
                {symptom.description}
              </p>

              {/* Bottom decorative line */}
              <div className={`absolute bottom-0 left-0 right-0 h-px bg-gradient-to-r from-transparent ${symptom.severity === "critical" ? "via-[rgba(255,45,45,0.3)]" : symptom.severity === "warning" ? "via-[rgba(255,176,32,0.25)]" : "via-[rgba(0,232,122,0.2)]"} to-transparent`} />
            </div>
          );
        })}
      </div>
    </section>
  );
}
