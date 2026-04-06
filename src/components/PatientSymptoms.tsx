"use client";
import { FileWarning, Puzzle, Wifi, Cpu, KeyRound, RefreshCcw, ShieldAlert, GitCompare } from "lucide-react";
import { IssueCard } from "./IssueCard";
import type { LucideIcon } from "lucide-react";

interface Symptom {
  icon: LucideIcon;
  title: string;
  severity: "critical" | "warning" | "info";
  description: string;
}

const symptoms: Symptom[] = [
  {
    icon: FileWarning,
    title: "Config Corruption",
    severity: "critical",
    description: "Configuration file has invalid JSON5 syntax or is corrupted, preventing OpenClaw from starting",
  },
  {
    icon: Puzzle,
    title: "Plugin / SDK Failure",
    severity: "warning",
    description: "Plugin crashes at activation, uses deprecated API (api.config.get), or plugin-sdk module is missing",
  },
  {
    icon: Wifi,
    title: "Gateway Offline",
    severity: "critical",
    description: "OpenClaw gateway not running on port 18789, all agent channels unreachable",
  },
  {
    icon: Cpu,
    title: "Daemon Not Installed",
    severity: "warning",
    description: "launchd (macOS) or systemd (Linux) service not registered — OpenClaw won't auto-start on boot",
  },
  {
    icon: KeyRound,
    title: "Missing Credentials",
    severity: "critical",
    description: "Provider API keys (OpenAI, Anthropic, Google…) missing or empty in the credentials store",
  },
  {
    icon: GitCompare,
    title: "Version Mismatch",
    severity: "warning",
    description: "CLI and Gateway are running different versions after an upgrade — gateway restart resolves it",
  },
  {
    icon: ShieldAlert,
    title: "Channel Policy Issue",
    severity: "warning",
    description: "Discord groupPolicy set to 'allowlist' with requireMention=true causes DMs to be silently ignored",
  },
  {
    icon: RefreshCcw,
    title: "plugins.allow Empty",
    severity: "warning",
    description: "All discovered plugins auto-load without an explicit allow list, creating a security risk",
  },
];

export function PatientSymptoms() {
  return (
    <section className="mx-auto w-full max-w-6xl px-6 py-24">
      <div className="mb-14 text-center">
        <span className="mb-4 inline-block rounded-full bg-primary/10 px-4 py-1.5 font-mono text-xs font-medium uppercase tracking-widest text-primary ring-1 ring-primary/20">
          Patient Symptoms
        </span>
        <h2 className="mt-4 font-heading text-3xl font-bold tracking-tight text-foreground sm:text-4xl">
          Common Diagnoses
        </h2>
        <p className="mx-auto mt-4 max-w-2xl text-base text-muted-foreground">
          When OpenClaw exhibits these symptoms, ClawICU provides the diagnosis and treatment plan.
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {symptoms.map((symptom, i) => (
          <div key={symptom.title} className="reveal" style={{ transitionDelay: `${i * 80}ms` }}>
            <IssueCard
              icon={symptom.icon}
              title={symptom.title}
              description={symptom.description}
              severity={symptom.severity}
              delay={0.6 + i * 0.08}
            />
          </div>
        ))}
      </div>
    </section>
  );
}
