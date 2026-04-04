"use client";

import { useState } from "react";
import {
  Download,
  Copy,
  Check,
  Terminal,
  Package,
  Apple,
  Monitor,
  Container,
  Box,
  FileCode2,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { useOSDetector, type OS } from "@/components/OSDetector";

const VERSION = "v0.2.0";
const RELEASE_DATE = "2026-04-04";

const downloadData: Record<OS, {
  id: string;
  label: string;
  icon: typeof Apple;
  file: string;
  url: string;
  checksum: string;
  size: string;
}> = {
  macos: {
    id: "download-macos",
    label: "macOS",
    icon: Apple,
    file: "rescue.sh",
    url: "https://xagent.icu/rescue.sh",
    checksum:
      "sha256:$(curl -sL https://xagent.icu/rescue.sh | shasum -a 256 | cut -d' ' -f1)",
    size: "Source (~15KB)",
  },
  linux: {
    id: "download-linux",
    label: "Linux",
    icon: Monitor,
    file: "rescue.sh",
    url: "https://xagent.icu/rescue.sh",
    checksum:
      "sha256:$(curl -sL https://xagent.icu/rescue.sh | sha256sum | cut -d' ' -f1)",
    size: "Source (~15KB)",
  },
};

const installCommand = "curl -fsSL https://xagent.icu/r | sh";

const installMethods = [
  {
    icon: Package,
    name: "npm",
    command: "npm install -g clawicu-rescue",
    description: "Global npm package",
  },
  {
    icon: Container,
    name: "Docker",
    command: "docker run --rm clawicu/rescue diagnose",
    description: "Containerized rescue",
  },
  {
    icon: Box,
    name: "Podman",
    command: "podman run --rm clawicu/rescue diagnose",
    description: "Rootless containers",
  },
  {
    icon: FileCode2,
    name: "Source",
    command: "git clone https://github.com/SonicBotMan/clawicu.git",
    description: "Build from source",
  },
];

function CopyButton({ text }: { text: string }) {
  const [copied, setCopied] = useState(false);

  const handleCopy = async () => {
    await navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <button
      onClick={handleCopy}
      className={cn(
        "flex h-8 w-8 shrink-0 items-center justify-center rounded-lg transition-all",
        copied
          ? "bg-success/20 text-success"
          : "bg-foreground/5 text-muted-foreground hover:bg-foreground/10 hover:text-foreground"
      )}
      aria-label="Copy to clipboard"
    >
      {copied ? <Check className="h-4 w-4" /> : <Copy className="h-4 w-4" />}
    </button>
  );
}

function TerminalBlock({ command }: { command: string }) {
  return (
    <div className="group relative">
      <div className="absolute -inset-px rounded-xl bg-gradient-to-b from-primary/30 via-primary/10 to-transparent opacity-50 transition-opacity group-hover:opacity-80" />
      <div className="relative flex items-center gap-4 rounded-xl bg-terminal px-5 py-4 font-mono text-sm ring-1 ring-[rgba(255,77,77,0.3)] sm:px-6 sm:py-5 sm:text-base">
        <span className="select-none text-accent/60">$</span>
        <span className="flex-1 overflow-x-auto text-foreground/90">
          <span className="text-primary">curl</span>{" "}
          <span className="text-[#8892b0]">-fsSL</span>{" "}
          <span className="text-accent">https://xagent.icu/r</span>{" "}
          <span className="text-[#8892b0]">|</span>{" "}
          <span className="text-primary">sh</span>
        </span>
        <CopyButton text={command} />
      </div>
    </div>
  );
}

export function DownloadClient() {
  const detectedOs = useOSDetector();
  const [selectedOs, setSelectedOs] = useState<OS>(detectedOs);

  const activeOs = selectedOs;
  const data = downloadData[activeOs];

  return (
    <>
      <section
        id="download"
        className="relative flex flex-col items-center px-6 pb-8 pt-32"
      >
        <div className="pointer-events-none absolute inset-0">
          <div className="absolute left-1/2 top-0 h-[500px] w-[800px] -translate-x-1/2 -translate-y-1/3 rounded-full bg-primary/[0.07] blur-[140px]" />
          <div className="absolute right-0 top-1/4 h-[300px] w-[400px] rounded-full bg-accent/[0.05] blur-[100px]" />
        </div>

        <div className="relative z-10 flex max-w-4xl flex-col items-center text-center">
          <span className="animate-fade-up mb-4 inline-flex items-center gap-2 rounded-full bg-primary/10 px-4 py-1.5 font-mono text-xs font-medium uppercase tracking-widest text-primary ring-1 ring-primary/20 backdrop-blur-sm">
            <Download className="h-3 w-3" />
            Download
          </span>

          <h1 className="animate-fade-up font-heading text-5xl font-extrabold tracking-tighter text-foreground sm:text-6xl md:text-7xl">
            Download{" "}
            <span className="bg-gradient-to-r from-primary via-accent to-primary bg-clip-text text-transparent">
              ClawICU
            </span>
          </h1>

          <p className="animate-fade-up mt-4 max-w-xl text-base leading-relaxed text-muted-foreground sm:text-lg">
            Get the rescue toolkit for your platform. One download, one command,
            full emergency coverage.
          </p>

          <span className="animate-fade-up mt-3 font-mono text-xs text-muted-foreground/60">
            {VERSION} — Released {RELEASE_DATE}
          </span>
        </div>
      </section>

      <section className="mx-auto w-full max-w-5xl px-6 pb-8">
        <div className="animate-fade-up mb-8 flex items-center gap-1 rounded-2xl border border-border bg-card backdrop-blur-[12px] p-1.5">
          {(Object.keys(downloadData) as OS[]).map((os) => {
            const OsIcon = downloadData[os].icon;
            const isActive = os === activeOs;
            return (
              <button
                key={os}
                onClick={() => setSelectedOs(os)}
                id={downloadData[os].id}
                className={cn(
                  "flex flex-1 items-center justify-center gap-2 rounded-xl px-6 py-3 text-sm font-semibold transition-all duration-200",
                  isActive
                    ? "bg-primary/15 text-foreground ring-1 ring-primary/30 shadow-[0_0_24px_oklch(0.70_0.20_200/0.1)]"
                    : "text-muted-foreground hover:text-foreground hover:bg-foreground/5"
                )}
              >
                <OsIcon className="h-4 w-4" />
                {downloadData[os].label}
                {os === detectedOs && (
                  <span className="ml-1 rounded-full bg-primary/10 px-2 py-0.5 font-mono text-[10px] uppercase tracking-wider text-primary">
                    detected
                  </span>
                )}
              </button>
            );
          })}
        </div>

        <div className="animate-fade-up grid gap-6 lg:grid-cols-2">
            <div className="group relative overflow-hidden rounded-2xl border border-border bg-card backdrop-blur-[12px] p-6 transition-all duration-300 hover:border-primary/30 hover:shadow-[0_0_30px_rgba(255,77,77,0.15)] hover:-translate-y-1">
            <div className="absolute inset-0 bg-gradient-to-br from-primary/5 via-transparent to-accent/5 opacity-0 transition-opacity duration-500 group-hover:opacity-100" />

            <div className="relative">
                <div className="mb-4 flex items-center gap-3">
                  <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary/10 text-primary ring-1 ring-primary/20 transition-all group-hover:bg-primary/15 group-hover:ring-primary/40">
                  <Download className="h-5 w-5" />
                </div>
                <div>
                  <h3 className="font-heading text-base font-semibold text-foreground">
                    Direct Download
                  </h3>
                  <span className="text-xs text-muted-foreground">
                    {data.size} · {data.label} ({VERSION})
                  </span>
                </div>
              </div>

              <a
                href={`https://xagent.icu/rescue.sh`}
                className="flex w-full items-center justify-center gap-2.5 rounded-xl bg-primary px-6 py-3.5 text-sm font-semibold text-primary-foreground transition-all duration-200 hover:bg-primary/90 hover:shadow-[0_0_24px_rgba(255,77,77,0.3)] hover:-translate-y-0.5"
              >
                <Download className="h-4 w-4" />
                Download {data.file}
              </a>

              <div className="mt-5 space-y-2">
                <span className="text-xs font-medium uppercase tracking-wider text-muted-foreground">
                  SHA256 Checksum
                </span>
                <div className="flex items-start gap-2 rounded-lg bg-terminal px-3 py-2.5 ring-1 ring-[rgba(255,77,77,0.3)]">
                  <code className="flex-1 break-all font-mono text-xs text-foreground/60">
                    {data.checksum}
                  </code>
                  <CopyButton text={data.checksum} />
                </div>
              </div>
            </div>
          </div>

          <div className="flex flex-col gap-5">
          <div className="group relative overflow-hidden rounded-2xl border border-border bg-card backdrop-blur-[12px] p-6 transition-all duration-300 hover:border-primary/30 hover:shadow-[0_0_30px_rgba(255,77,77,0.15)] hover:-translate-y-1">
              <div className="absolute inset-0 bg-gradient-to-br from-primary/5 via-transparent to-accent/5 opacity-0 transition-opacity duration-500 group-hover:opacity-100" />

              <div className="relative">
                <div className="mb-4 flex items-center gap-3">
                  <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-accent/10 text-accent ring-1 ring-accent/20 transition-all group-hover:bg-accent/15 group-hover:ring-accent/40">
                    <Terminal className="h-5 w-5" />
                  </div>
                  <div>
                    <h3 className="font-heading text-base font-semibold text-foreground">
                      Quick Install
                    </h3>
                    <span className="text-xs text-muted-foreground">
                      One-line install via curl
                    </span>
                  </div>
                </div>

                <TerminalBlock command={installCommand} />
              </div>
            </div>

            <div className="rounded-2xl border border-border/30 bg-surface/40 backdrop-blur-sm p-4">
              <p className="text-sm leading-relaxed text-muted-foreground">
                <span className="font-semibold text-foreground">Verify:</span>{" "}
                After downloading, compare the SHA256 checksum to ensure file
                integrity. Run{" "}
                <code className="rounded bg-terminal px-1.5 py-0.5 font-mono text-xs text-primary ring-1 ring-[rgba(255,77,77,0.3)]">
                  shasum -a 256 {data.file}
                </code>{" "}
                on {data.label}.
              </p>
            </div>
          </div>
        </div>
      </section>

      <section className="mx-auto w-full max-w-5xl px-6 py-16">
        <div className="mb-10 text-center">
          <span className="mb-4 inline-flex items-center gap-2 rounded-full bg-accent/10 px-4 py-1.5 font-mono text-xs font-medium uppercase tracking-widest text-accent ring-1 ring-accent/20">
            Installation Methods
          </span>
          <h2 className="mt-4 font-heading text-3xl font-bold tracking-tight text-foreground sm:text-4xl">
            Choose Your Path
          </h2>
          <p className="mx-auto mt-4 max-w-2xl text-base text-muted-foreground">
            Four ways to get ClawICU running — pick whichever fits your workflow.
          </p>
        </div>

        <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {installMethods.map((method, i) => {
            const Icon = method.icon;
            return (
              <div
                key={method.name}
                className="animate-fade-up group relative overflow-hidden rounded-2xl border border-border bg-card backdrop-blur-[12px] p-5 transition-all duration-300 hover:-translate-y-1 hover:border-accent/30 hover:shadow-[0_0_30px_rgba(255,77,77,0.15)]"
                style={{ animationDelay: `${0.3 + i * 0.08}s` }}
              >
                <div className="absolute inset-0 bg-gradient-to-br from-accent/5 via-transparent to-primary/5 opacity-0 transition-opacity duration-500 group-hover:opacity-100" />

                <div className="relative">
                  <div className="mb-3 flex h-10 w-10 items-center justify-center rounded-xl bg-accent/10 text-accent ring-1 ring-accent/20 transition-all duration-200 group-hover:bg-accent/15 group-hover:ring-accent/40 group-hover:scale-110">
                    <Icon className="h-5 w-5" />
                  </div>

                  <h3 className="mb-1 font-heading text-base font-semibold text-foreground">
                    {method.name}
                  </h3>

                  <p className="mb-3 text-xs text-muted-foreground">
                    {method.description}
                  </p>

                  <div className="flex items-center gap-2 rounded-xl bg-terminal px-2.5 py-2 ring-1 ring-[rgba(255,77,77,0.3)] transition-all duration-200 group-hover:ring-[rgba(255,77,77,0.3)]/80">
                    <span className="select-none text-accent/60 font-mono text-xs">
                      $
                    </span>
                    <code className="flex-1 overflow-x-auto font-mono text-xs text-foreground/70">
                      {method.command}
                    </code>
                    <CopyButton text={method.command} />
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </section>
    </>
  );
}
