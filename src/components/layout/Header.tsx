"use client";

import { Github, Menu, X } from "lucide-react";
import { cn } from "@/lib/utils";
import { useState, useEffect } from "react";

const navLinks = [
  { label: "Rescue", href: "/rescue" },
  { label: "Docs", href: "/docs" },
  { label: "Download", href: "/download" },
  { label: "GitHub", href: "https://github.com/SonicBotMan/clawicu", external: true },
];

export function Header() {
  const [mobileOpen, setMobileOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const handler = () => setScrolled(window.scrollY > 20);
    window.addEventListener("scroll", handler, { passive: true });
    return () => window.removeEventListener("scroll", handler);
  }, []);

  return (
    <header
      className={cn(
        "fixed top-0 left-0 right-0 z-50 transition-all duration-300",
        scrolled
          ? "border-b border-border/20 bg-[#050810]/60 backdrop-blur-[40px] shadow-lg shadow-black/10"
          : "border-b border-border/10 bg-[#050810]/30 backdrop-blur-[20px]"
      )}
    >
      <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-6">
        <a href="/" className="flex items-center gap-2.5 group">
          <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-gradient-to-br from-primary/20 to-primary/5 ring-1 ring-primary/30 transition-all group-hover:ring-primary/50 group-hover:shadow-[0_0_20px_rgba(255,77,77,0.2)]">
            <span className="font-heading text-sm font-bold text-primary">
              C
            </span>
          </div>
          <span className="font-heading text-lg font-bold tracking-tight text-foreground">
            ClawICU
          </span>
        </a>

        <nav className="hidden items-center gap-1 md:flex">
          {navLinks.map((link) => (
            <a
              key={link.label}
              href={link.href}
              target={link.external ? "_blank" : undefined}
              rel={link.external ? "noopener noreferrer" : undefined}
              className={cn(
                "rounded-md px-3 py-2 text-sm font-medium text-muted-foreground transition-colors",
                "hover:bg-white/[0.05] hover:text-foreground"
              )}
            >
              {link.external ? (
                <span className="flex items-center gap-1.5">
                  <Github className="h-4 w-4" />
                  {link.label}
                </span>
              ) : (
                link.label
              )}
            </a>
          ))}
          <a
            href="#get-started"
            className="ml-2 rounded-lg bg-primary px-5 py-2 text-sm font-semibold text-background shadow-lg shadow-[rgba(255,77,77,0.25)] transition-all hover:shadow-[rgba(255,77,77,0.4)] hover:shadow-xl hover:scale-[1.02]"
          >
            Get Started
          </a>
        </nav>

        <button
          className="flex h-9 w-9 items-center justify-center rounded-md text-muted-foreground transition-colors hover:bg-white/[0.05] hover:text-foreground md:hidden"
          onClick={() => setMobileOpen(!mobileOpen)}
          aria-label="Toggle menu"
        >
          {mobileOpen ? (
            <X className="h-5 w-5" />
          ) : (
            <Menu className="h-5 w-5" />
          )}
        </button>
      </div>

      {mobileOpen && (
        <nav className="border-t border-border/20 bg-[#050810]/95 backdrop-blur-[40px] md:hidden">
          <div className="flex flex-col gap-1 p-4">
            {navLinks.map((link) => (
              <a
                key={link.label}
                href={link.href}
                target={link.external ? "_blank" : undefined}
                rel={link.external ? "noopener noreferrer" : undefined}
                className="rounded-md px-3 py-2.5 text-sm font-medium text-muted-foreground transition-colors hover:bg-white/[0.05] hover:text-foreground"
              >
                {link.label}
              </a>
            ))}
            <a
              href="#get-started"
              className="mt-2 rounded-lg bg-primary px-5 py-2.5 text-center text-sm font-semibold text-background"
            >
              Get Started
            </a>
          </div>
        </nav>
      )}
    </header>
  );
}
