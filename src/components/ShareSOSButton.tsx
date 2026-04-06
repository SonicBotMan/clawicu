"use client";
import { useState } from "react";
import { Share2, Check, X as XIcon, AlertTriangle, ExternalLink } from "lucide-react";

/* Pre-written rescue distress tweet */
const TWEET_TEXT = `🚨 SOS: My OpenClaw just crashed!

Running emergency rescue now:
curl -fsSL https://xagent.icu/r | sh

🏥 ClawICU auto-diagnoses plugin crashes, version mismatches & more — saves lives 🫀

#OpenClaw #DevOps`;

const SHARE_URL = "https://xagent.icu/sos/";

function buildTwitterIntent() {
  const params = new URLSearchParams({
    text: TWEET_TEXT,
    url: SHARE_URL,
  });
  return `https://twitter.com/intent/tweet?${params.toString()}`;
}

export function ShareSOSButton({ compact = false }: { compact?: boolean }) {
  const [showPreview, setShowPreview] = useState(false);
  const [copied, setCopied] = useState(false);

  const openShare = () => {
    window.open(buildTwitterIntent(), "_blank", "noopener,noreferrer,width=600,height=500");
    setShowPreview(false);
  };

  const copyText = async () => {
    await navigator.clipboard.writeText(TWEET_TEXT + "\n\n" + SHARE_URL);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  if (compact) {
    return (
      <button
        onClick={openShare}
        className="group flex items-center gap-2 rounded-lg border border-border/50 bg-card/60 px-4 py-2 text-sm font-medium text-muted-foreground transition-all hover:border-[rgba(0,0,0,0.6)] hover:bg-black hover:text-white"
        title="Share SOS to X"
      >
        <XIcon className="h-4 w-4" />
        Share SOS
      </button>
    );
  }

  return (
    <div className="relative">
      <button
        onClick={() => setShowPreview(!showPreview)}
        className="group flex items-center gap-2.5 rounded-xl border border-border/50 bg-card/60 px-5 py-3 text-sm font-medium text-foreground backdrop-blur-sm transition-all hover:border-white/20 hover:bg-black/60"
      >
        <Share2 className="h-4 w-4 text-muted-foreground group-hover:text-white transition-colors" />
        Share SOS to X
        <XIcon className="h-3.5 w-3.5 text-muted-foreground/60 group-hover:text-white/60 transition-colors" />
      </button>

      {/* Preview popover */}
      {showPreview && (
        <>
          {/* Backdrop */}
          <div
            className="fixed inset-0 z-40"
            onClick={() => setShowPreview(false)}
          />

          {/* Card preview modal */}
          <div className="absolute bottom-full right-0 z-50 mb-3 w-[340px] overflow-hidden rounded-2xl border border-border/60 bg-[#0a0f1a] shadow-2xl shadow-black/50 sm:w-[380px]">

            {/* Header */}
            <div className="flex items-center justify-between border-b border-border/40 bg-[#050810]/80 px-4 py-3">
              <div className="flex items-center gap-2">
                <XIcon className="h-4 w-4 text-foreground" />
                <span className="text-sm font-semibold text-foreground">Preview Tweet</span>
              </div>
              <button
                onClick={() => setShowPreview(false)}
                className="rounded-md p-1 text-muted-foreground hover:bg-white/5 hover:text-foreground transition-colors"
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            {/* Tweet body */}
            <div className="p-4">
              {/* Fake tweet card */}
              <div className="rounded-xl border border-border/40 bg-[#050810] p-4">
                {/* Avatar + name */}
                <div className="mb-3 flex items-center gap-2.5">
                  <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary/20 ring-1 ring-primary/30">
                    <AlertTriangle className="h-4 w-4 text-primary" />
                  </div>
                  <div>
                    <div className="text-xs font-semibold text-foreground">You</div>
                    <div className="text-[10px] text-muted-foreground">@username</div>
                  </div>
                </div>

                {/* Tweet text */}
                <p className="text-sm text-foreground/90 leading-relaxed whitespace-pre-line">
                  {TWEET_TEXT}
                </p>

                {/* Link card preview */}
                <div className="mt-3 overflow-hidden rounded-xl border border-border/50">
                  <div
                    className="flex h-20 items-center justify-center text-xs text-muted-foreground"
                    style={{
                      background: "repeating-linear-gradient(45deg, rgba(255,77,77,0.08) 0px, rgba(255,77,77,0.08) 4px, transparent 4px, transparent 16px)",
                    }}
                  >
                    <div className="text-center">
                      <div className="font-mono font-bold text-primary text-sm">🚨 SOS</div>
                      <div className="text-[11px] mt-1">xagent.icu/sos</div>
                    </div>
                  </div>
                  <div className="border-t border-border/40 px-3 py-2">
                    <div className="text-xs font-semibold text-foreground">My OpenClaw just crashed!</div>
                    <div className="text-[11px] text-muted-foreground mt-0.5">xagent.icu</div>
                  </div>
                </div>
              </div>

              {/* Actions */}
              <div className="mt-3 flex gap-2">
                <button
                  onClick={openShare}
                  className="flex flex-1 items-center justify-center gap-2 rounded-lg bg-black px-4 py-2.5 text-sm font-semibold text-white transition-all hover:bg-neutral-900 border border-white/10"
                >
                  <XIcon className="h-4 w-4" />
                  Post to X
                  <ExternalLink className="h-3 w-3 opacity-50" />
                </button>
                <button
                  onClick={copyText}
                  className="flex items-center gap-1.5 rounded-lg border border-border/50 bg-card/60 px-3 py-2.5 text-sm text-muted-foreground transition-all hover:border-border hover:text-foreground"
                  title="Copy text"
                >
                  {copied ? <Check className="h-4 w-4 text-[#00e87a]" /> : <Share2 className="h-4 w-4" />}
                </button>
              </div>
            </div>
          </div>
        </>
      )}
    </div>
  );
}

/* Fix missing X close button import */
function X({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
    </svg>
  );
}
