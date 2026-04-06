import { Github, BriefcaseMedical, BookOpen } from "lucide-react";

export function ContactCTA() {
  return (
    <section className="mx-auto w-full max-w-6xl px-6 py-16">
      <div className="relative overflow-hidden rounded-3xl border border-border/50 bg-gradient-to-br from-card/80 to-card/40 p-8 backdrop-blur-[12px] sm:p-12">

        {/* Corner medical cross watermarks */}
        <svg viewBox="0 0 100 100" className="pointer-events-none absolute -right-6 -top-6 w-32 text-primary/5" fill="currentColor">
          <rect x="35" y="5"  width="30" height="90" rx="6" />
          <rect x="5"  y="35" width="90" height="30" rx="6" />
        </svg>
        <svg viewBox="0 0 100 100" className="pointer-events-none absolute -bottom-6 -left-6 w-24 text-accent/5" fill="currentColor">
          <rect x="35" y="5"  width="30" height="90" rx="6" />
          <rect x="5"  y="35" width="90" height="30" rx="6" />
        </svg>

        <div className="relative z-10 flex flex-col items-center text-center">
          {/* Icon */}
          <div className="mb-5 flex h-14 w-14 items-center justify-center rounded-full border border-[rgba(0,232,122,0.25)] bg-[rgba(0,232,122,0.08)]">
            <BriefcaseMedical className="h-7 w-7 text-[#00e87a]" />
          </div>

          <h2 className="font-heading text-3xl font-bold text-foreground sm:text-4xl">
            Need Help?
          </h2>
          <p className="mx-auto mt-4 max-w-xl text-base text-muted-foreground">
            ClawICU is open source. Check the documentation, or open a GitHub issue — the community is ready.
          </p>

          <div className="mt-8 flex flex-wrap items-center justify-center gap-4">
            <a
              href="https://github.com/SonicBotMan/clawicu/issues"
              className="flex items-center gap-2.5 rounded-xl bg-primary px-7 py-3.5 text-sm font-semibold text-primary-foreground shadow-lg shadow-primary/20 transition-all hover:bg-primary/90 hover:shadow-xl hover:shadow-primary/30"
              target="_blank"
              rel="noopener noreferrer"
            >
              <Github className="h-4 w-4" />
              Open an Issue
            </a>
            <a
              href="/docs"
              className="flex items-center gap-2.5 rounded-xl border border-[rgba(0,232,122,0.2)] bg-card/60 px-7 py-3.5 text-sm font-semibold text-foreground backdrop-blur-sm transition-all hover:border-[rgba(0,232,122,0.4)] hover:bg-card/80"
            >
              <BookOpen className="h-4 w-4 text-[#00e87a]" />
              Read Docs
            </a>
          </div>
        </div>

        <div className="pointer-events-none absolute -right-20 -top-20 h-64 w-64 rounded-full bg-primary/5 blur-3xl" />
        <div className="pointer-events-none absolute -bottom-20 -left-20 h-64 w-64 rounded-full bg-accent/5 blur-3xl" />
      </div>
    </section>
  );
}
