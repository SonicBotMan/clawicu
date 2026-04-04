import type { Metadata } from "next";
import { Header } from "@/components/layout/Header";
import { Footer } from "@/components/layout/Footer";
import { GridBackground } from "@/components/effects";
import { Shield, Terminal, AlertTriangle, CheckCircle, RefreshCw } from "lucide-react";

export const metadata: Metadata = {
  title: "Tool Unlock Panel",
  description:
    "Interactive security configuration editor in ClawICU rescue script. Unlock exec, browser, elevated, and sandbox tools via openclaw config commands.",
  alternates: {
    canonical: "/docs/tool-unlock-panel/",
  },
};

const unlockOptions = [
  {
    key: "2",
    title: "Exec Free Mode",
    icon: Terminal,
    color: "text-red-400",
    bgColor: "bg-red-400/10",
    borderColor: "border-red-400/30",
    config: {
      "tools.exec.security": '"full"',
      "tools.exec.ask": '"off"',
    },
    danger: true,
    description:
      "Removes all exec restrictions and approval prompts. Allows unlimited shell command execution without user confirmation.",
    useCase: "Development environments where you want the agent to run any command freely.",
  },
  {
    key: "3",
    title: "Enable Browser Tool",
    icon: CheckCircle,
    color: "text-emerald-400",
    bgColor: "bg-emerald-400/10",
    borderColor: "border-emerald-400/30",
    config: {
      "tools.allow": '["browser"] (added to list)',
    },
    danger: false,
    description:
      "Adds the browser tool to the allowed tools list. Required for web browsing and web automation capabilities.",
    useCase: "When the agent needs to browse websites or perform web research.",
  },
  {
    key: "4",
    title: "Disable Elevated",
    icon: Shield,
    color: "text-amber-400",
    bgColor: "bg-amber-400/10",
    borderColor: "border-amber-400/30",
    config: {
      "tools.elevated.enabled": "false",
    },
    danger: false,
    description:
      "Disables elevated exec mode. Prevents the agent from running commands with elevated (sudo/admin) privileges.",
    useCase: "Multi-user environments where elevated access should require separate authorization.",
  },
  {
    key: "5",
    title: "Open Sandbox",
    icon: AlertTriangle,
    color: "text-orange-400",
    bgColor: "bg-orange-400/10",
    borderColor: "border-orange-400/30",
    config: {
      "tools.sandbox.tools.allow": '["*"]',
    },
    danger: true,
    description:
      "Allows all sandbox tools to run. Sandbox provides isolation but with full access to sandboxed resources.",
    useCase: "When you need sandbox tools to work without restrictions.",
  },
  {
    key: "6",
    title: "Restore Safe Defaults",
    icon: RefreshCw,
    color: "text-cyan-400",
    bgColor: "bg-cyan-400/10",
    borderColor: "border-cyan-400/30",
    config: {
      "tools.exec.security": '"deny"',
      "tools.exec.ask": '"on-miss"',
      "tools.elevated.enabled": "true",
      "tools.sandbox.tools.allow": "[]",
    },
    danger: false,
    description:
      "Resets all security settings to their safe defaults. Recommended after using dangerous unlock options.",
    useCase: "After testing or temporary workarounds, restore secure settings.",
  },
];

export default function ToolUnlockPanelPage() {
  return (
    <>
      <Header />
      <GridBackground />
      <main className="min-h-screen pt-24 pb-16 relative z-10">
        <div className="mx-auto max-w-3xl px-6">
          <div className="mb-12">
            <div className="mb-6 inline-flex items-center gap-2 rounded-full border border-border bg-card backdrop-blur-[12px] px-4 py-1.5 font-mono text-xs text-[#8892b0]">
              <Shield className="h-3 w-3 text-primary" />
              Feature Guide
            </div>
            <h1 className="font-heading text-4xl font-bold tracking-tight text-foreground">
              Tool Unlock Panel
            </h1>
            <p className="mt-4 text-lg text-muted-foreground">
              Interactive security configuration editor in the ClawICU rescue script.
              Modify OpenClaw tool permissions without editing config files manually.
            </p>
          </div>

          <section className="mb-12 rounded-2xl border border-border bg-card/50 p-6 backdrop-blur-[12px]">
            <h2 className="font-heading text-xl font-semibold text-foreground mb-4">
              How to Access
            </h2>
            <div className="rounded-xl bg-terminal px-4 py-3 font-mono text-sm ring-1 ring-[rgba(255,77,77,0.3)]">
              <span className="text-[#8892b0]">$ </span>
              <span className="text-primary">curl</span>
              <span className="text-[#8892b0]"> -fsSL https://xagent.icu/rescue.sh | </span>
              <span className="text-primary">sh</span>
            </div>
            <p className="mt-4 text-sm text-muted-foreground">
              The Tool Unlock Panel appears in{" "}
              <strong className="text-foreground">Phase 5</strong> of the rescue
              script. You can also re-run specific unlock operations by selecting
              options 1-6 in the interactive menu.
            </p>
          </section>

          <section className="mb-12">
            <h2 className="font-heading text-xl font-semibold text-foreground mb-6">
              Unlock Options
            </h2>
            <div className="space-y-4">
              {unlockOptions.map((option) => (
                <div
                  key={option.key}
                  className={`rounded-xl border ${option.borderColor} ${option.bgColor} p-6`}
                >
                  <div className="flex items-start gap-4">
                    <div
                      className={`mt-1 flex h-10 w-10 shrink-0 items-center justify-center rounded-xl ${option.bgColor} ${option.color}`}
                    >
                      <option.icon className="h-5 w-5" />
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-2">
                        <h3 className="font-heading font-semibold text-foreground">
                          [{option.key}] {option.title}
                        </h3>
                        {option.danger && (
                          <span className="rounded-full bg-red-400/20 px-2 py-0.5 text-xs font-medium text-red-400">
                            DANGEROUS
                          </span>
                        )}
                      </div>
                      <p className="text-sm text-muted-foreground mb-3">
                        {option.description}
                      </p>
                      <div className="rounded-lg bg-terminal/50 p-3 font-mono text-xs">
                        {Object.entries(option.config).map(([key, value]) => (
                          <div key={key} className="flex gap-2">
                            <span className="text-[#8892b0]">{key}</span>
                            <span className="text-muted-foreground">=</span>
                            <span className="text-emerald-400">{value}</span>
                          </div>
                        ))}
                      </div>
                      <p className="mt-3 text-xs text-muted-foreground">
                        <strong className="text-foreground">Use case:</strong>{" "}
                        {option.useCase}
                      </p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </section>

          <section className="mb-12 rounded-2xl border border-amber-400/30 bg-amber-400/5 p-6">
            <h2 className="font-heading text-lg font-semibold text-amber-400 mb-4 flex items-center gap-2">
              <AlertTriangle className="h-5 w-5" />
              Security Notes
            </h2>
            <ul className="space-y-3 text-sm text-muted-foreground">
              <li className="flex gap-3">
                <span className="text-amber-400">1.</span>
                <span>
                  <strong className="text-foreground">Dangerous options (2, 5)</strong>{" "}
                  require typing <code className="rounded bg-terminal px-1.5 py-0.5 font-mono text-xs">yes</code>{" "}
                  to confirm. This prevents accidental activation.
                </span>
              </li>
              <li className="flex gap-3">
                <span className="text-amber-400">2.</span>
                <span>
                  All changes require running{" "}
                  <code className="rounded bg-terminal px-1.5 py-0.5 font-mono text-xs">openclaw gateway restart</code>{" "}
                  to take effect.
                </span>
              </li>
              <li className="flex gap-3">
                <span className="text-amber-400">3.</span>
                <span>
                  Changes are logged in the rescue report at{" "}
                  <code className="rounded bg-terminal px-1.5 py-0.5 font-mono text-xs">~/.openclaw/clawicu-report-*.txt</code>.
                </span>
              </li>
              <li className="flex gap-3">
                <span className="text-amber-400">4.</span>
                <span>
                  After testing, use <strong className="text-foreground">[6] Restore Safe Defaults</strong>{" "}
                  to return to secure settings.
                </span>
              </li>
            </ul>
          </section>

          <section className="rounded-2xl border border-border bg-card/50 p-6 backdrop-blur-[12px]">
            <h2 className="font-heading text-lg font-semibold text-foreground mb-4">
              How It Works
            </h2>
            <p className="text-sm text-muted-foreground mb-4">
              The Tool Unlock Panel uses OpenClaw&apos;s built-in config commands to
              read and modify security settings:
            </p>
            <div className="space-y-3 font-mono text-xs">
              <div className="rounded-lg bg-terminal/50 p-3">
                <div className="text-[#8892b0] mb-1"># Read current config</div>
                <div className="text-foreground">
                  openclaw config get <span className="text-primary">&quot;tools.exec.security&quot;</span>
                </div>
              </div>
              <div className="rounded-lg bg-terminal/50 p-3">
                <div className="text-[#8892b0] mb-1"># Set new value</div>
                <div className="text-foreground">
                  openclaw config set <span className="text-primary">&quot;tools.exec.security&quot;</span>{" "}
                  <span className="text-emerald-400">&quot;full&quot;</span>
                </div>
              </div>
              <div className="rounded-lg bg-terminal/50 p-3">
                <div className="text-[#8892b0] mb-1"># Restart gateway to apply</div>
                <div className="text-foreground">
                  openclaw gateway restart
                </div>
              </div>
            </div>
          </section>
        </div>
      </main>
      <Footer />
    </>
  );
}