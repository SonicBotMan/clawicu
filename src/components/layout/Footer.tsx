import { Heart, Github } from "lucide-react";

const footerLinks = {
  Product: [
    { label: "Rescue Guide", href: "/rescue" },
    { label: "Documentation", href: "/docs" },
    { label: "Download", href: "/download" },
  ],
  Community: [
    { label: "GitHub", href: "https://github.com/SonicBotMan/clawicu" },
    {
      label: "Issues",
      href: "https://github.com/SonicBotMan/clawicu/issues",
    },
  ],
};

export function Footer() {
  return (
    <footer className="border-t border-border/30 bg-[#050810]/80">
      <div className="mx-auto max-w-6xl px-6 py-16">
        <div className="grid gap-12 sm:grid-cols-2 lg:grid-cols-4">
          <div className="lg:col-span-1">
            <a href="/" className="flex items-center gap-2.5">
              <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary/10 ring-1 ring-primary/30">
                <span className="font-heading text-sm font-bold text-primary">
                  C
                </span>
              </div>
              <span className="font-heading text-lg font-bold tracking-tight text-foreground">
                ClawICU
              </span>
            </a>
            <p className="mt-4 text-sm leading-relaxed text-[#8892b0]">
              Emergency rescue system for OpenClaw. Diagnose, treat, and revive
              critical systems in real-time.
            </p>
          </div>

          {Object.entries(footerLinks).map(([category, links]) => (
            <div key={category}>
              <h4 className="mb-4 text-sm font-semibold text-[#f0f4ff]">
                {category}
              </h4>
              <ul className="space-y-3">
                {links.map((link) => (
                  <li key={link.label}>
                    <a
                      href={link.href}
                      className="text-sm text-[#8892b0] transition-colors hover:text-[#f0f4ff]"
                      target={
                        link.href.startsWith("http") ? "_blank" : undefined
                      }
                      rel={
                        link.href.startsWith("http")
                          ? "noopener noreferrer"
                          : undefined
                      }
                    >
                      {link.label}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        <div className="mt-12 flex flex-col items-center justify-between gap-4 border-t border-border/20 pt-8 sm:flex-row">
          <div className="flex items-center gap-2 text-sm text-[#5a6480]">
            <Heart className="h-3.5 w-3.5 text-primary" />
            <span>
              {new Date().getFullYear()} ClawICU. Emergency rescue for OpenClaw.
            </span>
          </div>
          <div className="flex items-center gap-4">
            <a
              href="https://github.com/SonicBotMan/clawicu"
              className="text-[#8892b0] transition-colors hover:text-[#f0f4ff]"
              target="_blank"
              rel="noopener noreferrer"
            >
              <Github className="h-4 w-4" />
            </a>
          </div>
        </div>
      </div>
    </footer>
  );
}
