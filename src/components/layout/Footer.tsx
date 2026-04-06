import { Heart, Github, ExternalLink, Zap, Shield, MessageCircle, HeartPulse } from "lucide-react";

const footerLinks = {
  Product: [
    { label: "Rescue Script", href: "/rescue" },
    { label: "Documentation", href: "/docs" },
    { label: "Download", href: "/download" },
    { label: "GitHub Repo", href: "https://github.com/SonicBotMan/clawicu" },
  ],
  Features: [
    { label: "20 Diagnostic Checks", href: "/rescue" },
    { label: "12 Repair Modules", href: "/rescue" },
    { label: "Auto Backup", href: "/docs" },
    { label: "Multi-Platform", href: "/download" },
  ],
  Community: [
    { label: "GitHub Issues", href: "https://github.com/SonicBotMan/clawicu/issues" },
    { label: "Discussions", href: "https://github.com/SonicBotMan/clawicu/discussions" },
    { label: "Contributing", href: "https://github.com/SonicBotMan/clawicu/blob/main/CONTRIBUTING.md" },
  ],
  Support: [
    { label: "Documentation", href: "/docs" },
    { label: "FAQ", href: "/docs" },
    { label: "Report Issue", href: "https://github.com/SonicBotMan/clawicu/issues" },
    { label: "Talk to Us", href: "https://github.com/SonicBotMan/clawicu/issues" },
  ],
};

export function Footer() {
  return (
    <footer className="border-t border-border/30 bg-[#050810]/80">
      <div className="mx-auto max-w-6xl px-6 py-16">
        <div className="grid gap-8 sm:grid-cols-2 lg:grid-cols-5">
          <div className="lg:col-span-1">
            <a href="/" className="flex items-center gap-2.5">
              <div className="relative flex h-8 w-8 items-center justify-center rounded-lg bg-primary/10 ring-1 ring-primary/30">
                <svg viewBox="0 0 24 24" className="h-4 w-4 text-primary" fill="currentColor">
                  <rect x="9"  y="2"  width="6" height="20" rx="1.5" />
                  <rect x="2"  y="9"  width="20" height="6"  rx="1.5" />
                </svg>
              </div>
              <span className="font-heading text-lg font-bold tracking-tight text-foreground">ClawICU</span>
            </a>
            <p className="mt-4 text-sm leading-relaxed text-muted-foreground">
              Emergency rescue system for OpenClaw. Diagnose, treat, and revive critical systems.
            </p>
            <div className="mt-4 flex items-center gap-3">
              <a
                href="https://github.com/SonicBotMan/clawicu"
                className="flex items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground"
                target="_blank"
                rel="noopener noreferrer"
              >
                <Github className="h-4 w-4" />
                <span>1.2k Stars</span>
              </a>
            </div>
            <a
              href="https://github.com/SonicBotMan/clawicu/issues"
              target="_blank"
              rel="noopener noreferrer"
              className="mt-4 flex items-center gap-2 rounded-lg bg-card/40 px-3 py-2 text-sm text-muted-foreground backdrop-blur-sm transition-all hover:bg-card/60 hover:text-foreground border border-border/30"
            >
              <MessageCircle className="h-4 w-4 text-accent" />
              <span>Talk to Us</span>
            </a>
          </div>

          {Object.entries(footerLinks).map(([category, links]) => (
            <div key={category}>
              <h4 className="mb-4 text-sm font-semibold text-foreground">{category}</h4>
              <ul className="space-y-2.5">
                {links.map((link) => (
                  <li key={link.label}>
                    <a
                      href={link.href}
                      className="flex items-center gap-1.5 text-sm text-muted-foreground transition-colors hover:text-foreground"
                      target={link.href.startsWith("http") ? "_blank" : undefined}
                      rel={link.href.startsWith("http") ? "noopener noreferrer" : undefined}
                    >
                      {link.label}
                      {link.href.startsWith("http") && (
                        <ExternalLink className="h-3 w-3 opacity-50" />
                      )}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        {/* Footer ECG divider */}
        <div className="mt-12 mb-0 relative">
          <svg viewBox="0 0 800 30" className="w-full opacity-[0.08]" fill="none" preserveAspectRatio="none">
            <path d="M0,15 L120,15 L140,4 L155,26 L168,2 L182,28 L192,15 L340,15 L360,4 L375,26 L388,2 L402,28 L412,15 L560,15 L580,4 L595,26 L608,2 L622,28 L632,15 L800,15"
              stroke="#00e87a" strokeWidth="1.5"
              style={{ strokeDasharray: 1000, strokeDashoffset: 1000, animation: "ecg-run 6s linear infinite" }}
            />
          </svg>
        </div>

        <div className="flex flex-col items-center justify-between gap-4 border-t border-border/20 pt-8 sm:flex-row">
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <HeartPulse className="h-3.5 w-3.5 text-primary animate-heartbeat" />
            <span>{new Date().getFullYear()} ClawICU. Open Source under MIT License.</span>
          </div>
          <div className="flex items-center gap-6">
            <a
              href="https://github.com/SonicBotMan/clawicu"
              className="text-muted-foreground transition-colors hover:text-foreground"
              target="_blank"
              rel="noopener noreferrer"
            >
              <Github className="h-4 w-4" />
            </a>
            <span className="flex items-center gap-1.5 text-xs text-muted-foreground">
              <Zap className="h-3 w-3 text-accent" />
              <span>Open Source</span>
            </span>
            <span className="flex items-center gap-1.5 text-xs text-muted-foreground">
              <Shield className="h-3 w-3 text-accent" />
              <span>Zero Tracking</span>
            </span>
          </div>
        </div>
      </div>
    </footer>
  );
}
