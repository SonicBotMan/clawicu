"use client";
import { MessageCircle, ChevronDown, Shield, Heart, Zap } from "lucide-react";
import { TerminalBlock } from "@/components/ui/TerminalBlock";
import { useEffect, useState } from "react";

export function Hero() {
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);

  return (
    <section className="relative flex min-h-screen flex-col items-center justify-center overflow-hidden px-6 pb-12 pt-28">
      <div 
        className="pointer-events-none absolute inset-0 opacity-[0.03]"
        style={{
          backgroundImage: `linear-gradient(rgba(240,244,255,0.1) 1px, transparent 1px), linear-gradient(90deg, rgba(240,244,255,0.1) 1px, transparent 1px)`,
          backgroundSize: '60px 60px'
        }}
      />
      
      <div className="pointer-events-none absolute bottom-0 left-0 right-0 h-32 bg-gradient-to-t from-background to-transparent" />
      
      <div className="relative z-10 flex max-w-5xl flex-col items-center text-center">
        <div
          className="animate-fade-up mb-8 inline-flex items-center gap-3 rounded-full border border-border/50 bg-card/60 px-5 py-2 backdrop-blur-sm"
          style={{ animationDelay: "0.05s" }}
        >
          <Heart className="h-4 w-4 text-primary" />
          <span className="font-mono text-xs text-muted-foreground">
            Emergency Rescue System
          </span>
          <span className="mx-2 h-3 w-px bg-border/50" />
          <span className="font-mono text-xs text-accent">MIT License</span>
        </div>

        <h1
          className="animate-fade-up text-center font-heading text-5xl font-extrabold tracking-tight sm:text-6xl md:text-7xl lg:text-8xl"
          style={{ animationDelay: "0.1s" }}
        >
          <span className="text-foreground">Claw</span>
          <span 
            className="bg-clip-text text-transparent"
            style={{
              backgroundImage: "linear-gradient(90deg, #ff4d4d, #00e5cc)",
              backgroundSize: "200% 200%",
              animation: "gradient-shift 8s ease-in-out infinite",
            }}
          >
            ICU
          </span>
        </h1>

        <p
          className="animate-fade-up mt-4 max-w-xl font-heading text-xl font-medium tracking-wide text-accent sm:text-2xl"
          style={{ animationDelay: "0.2s" }}
        >
          OpenClaw Emergency Rescue
        </p>

        <p
          className="animate-fade-up mt-6 max-w-2xl text-base text-muted-foreground leading-relaxed sm:text-lg"
          style={{ animationDelay: "0.25s" }}
        >
          Diagnose failures, stabilize processes, and revive your OpenClaw instance — all from one command.
        </p>

        <div 
          className="animate-fade-up mt-8 w-full max-w-xl" 
          style={{ animationDelay: "0.3s" }}
        >
          <TerminalBlock command="curl -fsSL https://xagent.icu/r | sh" />
        </div>

        <div 
          className="animate-fade-up mt-10 flex flex-wrap items-center justify-center gap-4" 
          style={{ animationDelay: "0.4s" }}
        >
          <a
            href="#examination"
            className="group flex items-center gap-2.5 rounded-xl bg-primary px-7 py-3.5 text-sm font-semibold text-primary-foreground shadow-lg shadow-primary/20 transition-all hover:bg-primary/90 hover:shadow-xl hover:shadow-primary/30 hover:-translate-y-0.5"
          >
            <Zap className="h-4 w-4" />
            Start Rescue
          </a>
          <a
            href="#treatment"
            className="group flex items-center gap-2.5 rounded-xl border border-border/50 bg-card/60 px-7 py-3.5 text-sm font-semibold text-foreground backdrop-blur-sm transition-all hover:border-accent/30 hover:bg-card/80"
          >
            <MessageCircle className="h-4 w-4 text-accent" />
            View Protocol
          </a>
        </div>

        <div
          className="animate-fade-up mt-16 inline-flex items-center gap-8 text-center"
          style={{ animationDelay: "0.5s" }}
        >
          <div className="flex flex-col items-center px-4">
            <span className="font-heading text-3xl font-bold text-foreground sm:text-4xl">24</span>
            <span className="mt-1 text-xs text-muted-foreground sm:text-sm">Issue Guides</span>
          </div>
          <div className="h-10 w-px bg-border/50" />
          <div className="flex flex-col items-center px-4">
            <span className="font-heading text-3xl font-bold text-foreground sm:text-4xl">6</span>
            <span className="mt-1 text-xs text-muted-foreground sm:text-sm">Rescue Phases</span>
          </div>
          <div className="h-10 w-px bg-border/50" />
          <div className="flex flex-col items-center px-4">
            <span className="font-heading text-3xl font-bold text-foreground sm:text-4xl">1</span>
            <span className="mt-1 text-xs text-muted-foreground sm:text-sm">Command Rescue</span>
          </div>
        </div>

        <div 
          className="animate-fade-up mt-12 flex items-center gap-6" 
          style={{ animationDelay: "0.6s" }}
        >
          {[
            { icon: Heart, label: "Open Source" },
            { icon: Shield, label: "Zero Tracking" },
            { icon: Zap, label: "Instant Fix" },
          ].map((item) => (
            <div key={item.label} className="flex items-center gap-2 text-xs text-muted-foreground">
              <item.icon className="h-3.5 w-3.5 text-accent" />
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
