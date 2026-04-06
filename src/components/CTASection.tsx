import { HeartPulse, Terminal, Syringe, Activity } from "lucide-react";

export function CTASection() {
  return (
    <section id="get-started" className="relative mx-auto w-full max-w-6xl px-6 py-24">
      <div className="reveal">
        <div className="relative overflow-hidden rounded-3xl border border-primary/25 bg-gradient-to-br from-surface/80 to-surface/40 p-12 text-center backdrop-blur-xl animate-alert-flash">

          {/* Scanlines overlay */}
          <div className="medical-scanline absolute inset-0 rounded-3xl" />

          {/* Ambient glows */}
          <div className="absolute -left-32 -top-32 h-64 w-64 rounded-full bg-primary/20 blur-[100px]" />
          <div className="absolute -bottom-32 -right-32 h-64 w-64 rounded-full bg-[#00e87a]/10 blur-[100px]" />

          {/* Top stripe — emergency yellow-black */}
          <div className="absolute inset-x-0 top-0 h-1.5 rounded-t-3xl"
               style={{ background: "repeating-linear-gradient(45deg, #ff4d4d 0px, #ff4d4d 12px, #1a0a0a 12px, #1a0a0a 24px)" }} />

          <div className="relative z-10">
            {/* Emergency icon */}
            <div className="mx-auto mb-6 flex h-16 w-16 items-center justify-center rounded-full border border-primary/30 bg-primary/10 animate-siren">
              <HeartPulse className="h-8 w-8 text-primary animate-heartbeat" />
            </div>

            <div className="mb-3 flex items-center justify-center gap-2">
              <span className="h-2 w-2 rounded-full bg-[#ff2d2d] animate-vital-blink" />
              <span className="font-mono text-xs font-bold uppercase tracking-widest text-primary/80">
                Emergency Rescue Ready
              </span>
              <span className="h-2 w-2 rounded-full bg-[#ff2d2d] animate-vital-blink" />
            </div>

            <h2 className="font-heading text-3xl font-bold tracking-tight text-foreground sm:text-4xl">
              Ready to Rescue Your OpenClaw?
            </h2>
            <p className="mx-auto mt-4 max-w-xl text-muted-foreground">
              One command. Full diagnosis. Automated repair. Your gateway back online in minutes.
            </p>

            <div className="mt-8 flex flex-wrap items-center justify-center gap-4">
              <a
                href="/rescue"
                className="flex items-center gap-2.5 rounded-xl bg-primary px-8 py-3.5 text-sm font-semibold text-background shadow-lg shadow-primary/25 transition-all hover:shadow-primary/40 hover:scale-[1.02]"
              >
                <Syringe className="h-4 w-4" />
                Initiate Rescue
              </a>
              <a
                href="/docs"
                className="group flex items-center gap-2.5 rounded-xl border border-[rgba(0,232,122,0.2)] bg-card backdrop-blur-[12px] px-6 py-3 text-sm font-medium text-foreground transition-all hover:border-[rgba(0,232,122,0.4)] hover:bg-surface"
              >
                <Activity className="h-4 w-4 text-[#00e87a]" />
                View Protocol Docs
              </a>
            </div>

            {/* Command pill */}
            <div className="mt-8 inline-flex items-center gap-2 rounded-lg bg-terminal px-5 py-2.5 font-mono text-xs text-muted-foreground ring-1 ring-primary/30">
              <Terminal className="h-3 w-3 text-primary" />
              curl -fsSL https://xagent.icu/r | sh
            </div>
          </div>

          {/* Bottom stripe */}
          <div className="absolute inset-x-0 bottom-0 h-1 rounded-b-3xl"
               style={{ background: "repeating-linear-gradient(45deg, #ff4d4d 0px, #ff4d4d 12px, #1a0a0a 12px, #1a0a0a 24px)" }} />
        </div>
      </div>
    </section>
  );
}
