"use client";
import { useState } from "react";
import { ChevronDown, Check, Zap, Shield, Wrench, RefreshCcw, Search, BarChart3 } from "lucide-react";
import { cn } from "@/lib/utils";

const phases = [
  {
    number: 0,
    title: "Bootstrap",
    description: "Detect OS, architecture, and installation method",
    icon: Search,
    details: [
      "Identify macOS vs Linux",
      "Detect npm, Docker, Podman, or source install",
      "Create temporary working directory",
      "Initialize logging",
    ],
    color: "text-primary",
  },
  {
    number: 1,
    title: "Doctor Delegation",
    description: "Run openclaw doctor with crash-safe 30s timeout",
    icon: Shield,
    details: [
      "Run openclaw doctor with 30-second timeout",
      "Auto-kills if a broken plugin causes a hang",
      "Capture full diagnostic output to temp file",
      "Detects TypeError, unhandled rejections, API errors",
    ],
    color: "text-primary",
  },
  {
    number: 2,
    title: "Standalone Checks",
    description: "Run 20 independent diagnostic check modules",
    icon: BarChart3,
    details: [
      "Config file JSON5 syntax validation",
      "Gateway health check on port 18789",
      "Plugin runtime & SDK API compatibility",
      "Credential presence for all AI providers",
      "Daemon service (launchd / systemd) status",
      "CLI vs Gateway version mismatch detection",
      "Port conflict check (skips openclaw itself)",
      "Node.js version, disk space, state directory",
      "Channel policy, env vars, exec-approvals",
    ],
    color: "text-accent",
  },
  {
    number: 3,
    title: "Merge & Triage",
    description: "Classify severity, display vital signs monitor",
    icon: Zap,
    details: [
      "Aggregate all diagnostic findings",
      "Classify by severity: fatal / warn / info",
      "Vital signs monitor: CRITICAL / WARNING / STABLE",
      "Generate prioritized issue list for repair",
    ],
    color: "text-accent",
  },
  {
    number: 4,
    title: "Guided Repair Menu",
    description: "Interactive menu — works even via curl | sh",
    icon: Wrench,
    details: [
      "Interactive menu: Auto / Quick / Full / Nuclear / Export / Quit",
      "Fully interactive even when piped from curl",
      "Auto mode: handles all detected issues automatically",
      "Quick mode: safe, low-risk repairs only",
    ],
    color: "text-primary",
  },
  {
    number: 5,
    title: "Execute & Verify",
    description: "Perform targeted repairs with rollback safety",
    icon: RefreshCcw,
    details: [
      "Automatic backup before any changes",
      "Disable broken / incompatible plugins (non-destructive)",
      "Restart gateway to fix version mismatch",
      "Populate plugins.allow to remove security risk",
      "Post-repair openclaw doctor verification",
    ],
    color: "text-success",
  },
];

export function RescueSteps() {
  const [openPhase, setOpenPhase] = useState<number | null>(null);

  return (
    <div className="space-y-3">
      {phases.map((phase) => {
        const isOpen = openPhase === phase.number;
        const Icon = phase.icon;
        
        return (
          <div
            key={phase.number}
            className={cn(
              "group relative overflow-hidden rounded-2xl border border-border bg-card backdrop-blur-[12px] transition-all duration-300",
              isOpen
                ? "border-primary/30 bg-card-strong"
                : "hover:border-border/50 hover:bg-card"
            )}
          >
            {isOpen && (
              <div className="absolute inset-0 bg-gradient-to-br from-primary/[0.03] to-transparent pointer-events-none" />
            )}
            
            <button
              onClick={() => setOpenPhase(isOpen ? null : phase.number)}
              className="w-full flex items-center justify-between p-5 text-left"
            >
              <div className="flex items-center gap-4">
                <div
                  className={cn(
                    "flex h-10 w-10 items-center justify-center rounded-xl bg-surface/80 ring-1 ring-border/30 transition-all",
                    isOpen && `ring-primary/30 ${phase.color}`
                  )}
                >
                  <Icon className={cn("h-5 w-5", phase.color)} />
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <span className="font-mono text-xs text-muted-foreground">
                      {String(phase.number).padStart(2, "0")}
                    </span>
                    <h3 className="font-heading font-semibold text-foreground">
                      {phase.title}
                    </h3>
                  </div>
                  <p className="mt-0.5 text-sm text-muted-foreground">
                    {phase.description}
                  </p>
                </div>
              </div>
              
              <ChevronDown
                className={cn(
                  "h-5 w-5 text-muted-foreground transition-transform duration-300",
                  isOpen && "rotate-180"
                )}
              />
            </button>
            
            <div
              className={cn(
                "overflow-hidden transition-all duration-300",
                isOpen ? "max-h-96 opacity-100" : "max-h-0 opacity-0"
              )}
            >
              <div className="px-5 pb-5">
                <ul className="space-y-2 pl-4 border-l-2 border-primary/20">
                  {phase.details.map((detail, i) => (
                    <li key={i} className="flex items-start gap-2 text-sm text-muted-foreground">
                      <Check className="mt-0.5 h-3.5 w-3.5 flex-shrink-0 text-success" />
                      {detail}
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
}
