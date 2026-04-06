"use client";
import { Search, Stethoscope, Wrench, CheckCircle } from "lucide-react";
import { SectionHeader } from "@/components/ui/SectionHeader";

const phases = [
  {
    icon: Search,
    title: "Triage",
    description: "Identify symptoms and assess system vitals",
    color: "text-primary",
  },
  {
    icon: Stethoscope,
    title: "Diagnose",
    description: "Run 20 diagnostic checks to pinpoint root cause",
    color: "text-accent",
  },
  {
    icon: Wrench,
    title: "Treat",
    description: "Apply targeted repairs with automatic backup",
    color: "text-primary",
  },
  {
    icon: CheckCircle,
    title: "Verify",
    description: "Confirm successful rescue and system recovery",
    color: "text-success",
  },
];

export function ExaminationProcess() {
  return (
    <section id="examination" className="relative mx-auto w-full max-w-6xl px-6 py-24">
      <SectionHeader
        badge="Examination Process"
        title="System Rescue Protocol"
        description="A battle-tested medical approach to diagnosing and rescuing your OpenClaw instance"
      />
      
      <div className="grid gap-8 sm:grid-cols-2 lg:grid-cols-4">
        {phases.map((phase, i) => (
          <div
            key={phase.title}
            className="reveal group relative rounded-2xl border border-border bg-card backdrop-blur-[12px] p-6 transition-all duration-300 hover:border-primary/30"
            style={{ transitionDelay: `${i * 100}ms` }}
          >
            <div className="absolute -top-3 left-6 rounded-full bg-background px-2 font-mono text-xs text-[#8892b0]">
              Phase {i + 1}
            </div>
            
            <phase.icon className={`h-8 w-8 ${phase.color} mb-4`} />
            <h3 className="mb-2 font-heading text-lg font-semibold text-foreground">
              {phase.title}
            </h3>
            <p className="text-sm text-muted-foreground leading-relaxed">
              {phase.description}
            </p>
          </div>
        ))}
      </div>
    </section>
  );
}
