import { Download, BookOpen, Terminal, Github } from "lucide-react";
import type { LucideIcon } from "lucide-react";

interface CTAItem {
  icon: LucideIcon;
  label: string;
  href: string;
  external?: boolean;
  variant: "primary" | "secondary";
}

const ctaItems: CTAItem[] = [
  {
    icon: Download,
    label: "Download",
    href: "/download",
    variant: "primary",
  },
  {
    icon: BookOpen,
    label: "Documentation",
    href: "/docs",
    variant: "secondary",
  },
  {
    icon: Terminal,
    label: "Rescue Guide",
    href: "/rescue",
    variant: "secondary",
  },
  {
    icon: Github,
    label: "GitHub",
    href: "https://github.com/SonicBotMan/clawicu",
    external: true,
    variant: "secondary",
  },
];

export function CTAGrid() {
  return (
    <section className="mx-auto w-full max-w-[860px] px-6 py-24">
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {ctaItems.map((item, i) => {
          const Icon = item.icon;
          const isPrimary = item.variant === "primary";
          return (
            <a
              key={item.label}
              href={item.href}
              target={item.external ? "_blank" : undefined}
              rel={item.external ? "noopener noreferrer" : undefined}
              className={`reveal group flex flex-col items-center gap-3 rounded-2xl border p-6 text-center transition-all duration-300 hover:-translate-y-1 ${
                isPrimary
                  ? "border-primary/30 bg-primary/10 text-primary hover:border-primary/50 hover:shadow-[0_0_30px_rgba(255,77,77,0.15)]"
                  : "border-border bg-card backdrop-blur-[12px] text-foreground hover:border-primary/30 hover:shadow-[0_0_30px_rgba(255,77,77,0.15)]"
              }`}
              style={{ transitionDelay: `${i * 80}ms` }}
            >
              <Icon className="h-6 w-6" />
              <span className="text-sm font-semibold">{item.label}</span>
            </a>
          );
        })}
      </div>
    </section>
  );
}
