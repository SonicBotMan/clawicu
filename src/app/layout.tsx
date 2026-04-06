import type { Metadata, Viewport } from "next";
import { Syne, Outfit, JetBrains_Mono } from "next/font/google";
import { ScrollRevealInit } from "@/components/effects/ScrollRevealInit";
import "./globals.css";

const syne = Syne({
  subsets: ["latin"],
  variable: "--font-clash-display",
  weight: ["400", "500", "600", "700", "800"],
  display: "swap",
});

const outfit = Outfit({
  subsets: ["latin"],
  variable: "--font-satoshi",
  weight: ["300", "400", "500", "600", "700"],
  display: "swap",
});

const jetbrainsMono = JetBrains_Mono({
  subsets: ["latin"],
  variable: "--font-mono",
  weight: ["400", "500", "600"],
  display: "swap",
});

export const viewport: Viewport = {
  themeColor: "#050810",
  width: "device-width",
  initialScale: 1,
};

const BASE_URL = "https://xagent.icu";

export const metadata: Metadata = {
  metadataBase: new URL(BASE_URL),
  title: {
    default: "ClawICU — OpenClaw Emergency Rescue",
    template: "%s | ClawICU",
  },
  description:
    "OpenClaw Emergency Rescue System v0.2.0. Run 20 diagnostic checks, auto-repair plugin crashes, version mismatches, channel policy issues, and more. One command: curl -fsSL https://xagent.icu/r | sh",
  keywords: [
    "OpenClaw",
    "ClawICU",
    "emergency rescue",
    "diagnostics",
    "plugin SDK",
    "version mismatch",
    "channel policy",
    "pairing",
    "channel auth",
    "cron",
    "heartbeat",
    "DevOps",
    "AI gateway",
  ],
  authors: [{ name: "ClawICU Team", url: "https://github.com/SonicBotMan/clawicu" }],
  creator: "ClawICU Team",
  publisher: "ClawICU Team",
  openGraph: {
    type: "website",
    locale: "en_US",
    url: BASE_URL,
    siteName: "ClawICU",
    title: "ClawICU — OpenClaw Emergency Rescue",
    description:
      "Rescue system for OpenClaw. Diagnose and fix common issues with one command.",
      images: [
        {
          url: "/og-image.svg",
          width: 1200,
          height: 630,
          alt: "ClawICU — OpenClaw Emergency Rescue",
        },
      ],
  },
  twitter: {
    card: "summary_large_image",
    title: "ClawICU — OpenClaw Emergency Rescue",
    description:
      "Fix broken OpenClaw in seconds. 20 checks, auto-repair plugins, gateway, version mismatches. One command.",
    images: ["/og-image.svg"],
  },
  icons: {
    icon: "/favicon.svg",
    shortcut: "/favicon.svg",
    apple: "/favicon.svg",
  },
  alternates: {
    canonical: BASE_URL,
    languages: {
      en: BASE_URL,
    },
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-video-preview": -1,
      "max-image-preview": "large",
      "max-snippet": -1,
    },
  },
};

const jsonLd = {
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "Organization",
      "@id": "https://xagent.icu/#organization",
      name: "ClawICU",
      url: "https://xagent.icu",
      logo: {
        "@type": "ImageObject",
        url: "https://xagent.icu/favicon.svg",
        width: 512,
        height: 512,
      },
      sameAs: [
        "https://github.com/SonicBotMan/clawicu",
      ],
    },
    {
      "@type": "WebSite",
      "@id": "https://xagent.icu/#website",
      url: "https://xagent.icu",
      name: "ClawICU",
      publisher: { "@id": "https://xagent.icu/#organization" },
      description:
        "OpenClaw Emergency Rescue System — 20 diagnostic checks and auto-repair for plugin crashes, gateway failures, version mismatches, config corruption, and more.",
      inLanguage: "en-US",
      potentialAction: {
        "@type": "SearchAction",
        target: {
          "@type": "EntryPoint",
          urlTemplate: "https://xagent.icu/docs/?q={search_term_string}",
        },
        "query-input": "required name=search_term_string",
      },
    },
    {
      "@type": "WebPage",
      "@id": "https://xagent.icu/#webpage",
      url: "https://xagent.icu",
      name: "ClawICU — OpenClaw Emergency Rescue System",
      about: { "@id": "https://xagent.icu/#organization" },
      isPartOf: { "@id": "https://xagent.icu/#website" },
      description:
        "Fix broken OpenClaw in seconds. ClawICU runs 20 diagnostic checks and auto-repairs plugin crashes, gateway failures, version mismatches, config corruption, and more.",
      inLanguage: "en-US",
      datePublished: "2026-04-04",
      dateModified: "2026-04-06",
    },
    {
      "@type": "SoftwareApplication",
      "@id": "https://xagent.icu/#software",
      name: "ClawICU",
      alternateName: "Claw ICU",
      url: "https://xagent.icu",
      description:
        "Emergency rescue shell script for OpenClaw. Diagnoses 20 categories of failures and auto-repairs plugin crashes, gateway issues, version mismatches, config corruption, and daemon problems.",
      applicationCategory: "DeveloperApplication",
      operatingSystem: "Linux, macOS",
      softwareVersion: "0.2.0",
      programmingLanguage: "Shell",
      license: "https://opensource.org/licenses/MIT",
      downloadUrl: "https://xagent.icu/r",
      installUrl: "https://xagent.icu/download/",
      releaseNotes: "https://github.com/SonicBotMan/clawicu",
      offers: {
        "@type": "Offer",
        price: "0",
        priceCurrency: "USD",
        availability: "https://schema.org/InStock",
      },
      publisher: { "@id": "https://xagent.icu/#organization" },
      featureList: [
        "20 diagnostic checks covering plugins, gateway, config, credentials, daemon, disk, version, channel policy",
        "Interactive 6-phase rescue protocol",
        "Auto-repair for plugin SDK incompatibility",
        "Auto-repair for CLI/Gateway version mismatch",
        "Automatic backup before any changes",
        "Works via curl | sh pipeline",
        "macOS and Linux support",
      ],
    },
    {
      "@type": "HowTo",
      "@id": "https://xagent.icu/#howto",
      name: "How to rescue a broken OpenClaw installation",
      description:
        "Run ClawICU to automatically diagnose and repair your broken OpenClaw instance in 6 phases.",
      supply: [{ "@type": "HowToSupply", name: "curl" }],
      tool: [{ "@type": "HowToTool", name: "ClawICU rescue script" }],
      step: [
        {
          "@type": "HowToStep",
          name: "Run the rescue command",
          text: "Execute: curl -fsSL https://xagent.icu/r | sh",
          url: "https://xagent.icu/#examination",
        },
        {
          "@type": "HowToStep",
          name: "Phase 1: Doctor check",
          text: "ClawICU runs openclaw doctor with a 30-second crash-safe timeout to capture runtime errors.",
          url: "https://xagent.icu/rescue/",
        },
        {
          "@type": "HowToStep",
          name: "Phase 2: 20 diagnostic checks",
          text: "Runs 20 independent checks across binary, config, gateway, plugins, credentials, daemon, port, disk, version, and more.",
          url: "https://xagent.icu/rescue/",
        },
        {
          "@type": "HowToStep",
          name: "Phase 3: Triage",
          text: "Classifies all findings by severity (FATAL / WARNING / INFO) and displays a vital signs monitor.",
          url: "https://xagent.icu/rescue/",
        },
        {
          "@type": "HowToStep",
          name: "Phase 4: Select treatment plan",
          text: "Interactive menu lets you choose Auto, Quick Fix, Full Treatment, or Nuclear Option.",
          url: "https://xagent.icu/rescue/",
        },
        {
          "@type": "HowToStep",
          name: "Phase 5: Execute repairs",
          text: "Targeted repair modules run with automatic backup, then verify each fix with openclaw doctor.",
          url: "https://xagent.icu/rescue/",
        },
      ],
    },
    {
      "@type": "FAQPage",
      "@id": "https://xagent.icu/#faq",
      mainEntity: [
        {
          "@type": "Question",
          name: "How do I use ClawICU?",
          acceptedAnswer: {
            "@type": "Answer",
            text: "Run one command: curl -fsSL https://xagent.icu/r | sh — ClawICU will automatically detect your system, run 20 diagnostic checks, and guide you through repairs.",
          },
        },
        {
          "@type": "Question",
          name: "What issues can ClawICU fix?",
          acceptedAnswer: {
            "@type": "Answer",
            text: "ClawICU can auto-repair: plugin SDK incompatibility (api.config.get is not a function), CLI/Gateway version mismatch, config file corruption, missing API credentials, gateway not running, daemon service not installed, port conflicts, disk space issues, and more.",
          },
        },
        {
          "@type": "Question",
          name: "Is ClawICU free?",
          acceptedAnswer: {
            "@type": "Answer",
            text: "Yes. ClawICU is completely free and open-source under the MIT license. No registration, no tracking, no paid upgrades.",
          },
        },
        {
          "@type": "Question",
          name: "Does ClawICU work via curl | sh?",
          acceptedAnswer: {
            "@type": "Answer",
            text: "Yes. ClawICU is fully interactive even when piped through curl | sh. It redirects stdin from /dev/tty so all menus and prompts receive keyboard input from your terminal.",
          },
        },
        {
          "@type": "Question",
          name: "What does ClawICU do before making changes?",
          acceptedAnswer: {
            "@type": "Answer",
            text: "ClawICU creates an automatic backup of your ~/.openclaw/ state directory before executing any repair. All repairs are non-destructive where possible (e.g. plugins are renamed to .clawicu-disabled, not deleted).",
          },
        },
      ],
    },
  ],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link
          rel="preconnect"
          href="https://fonts.gstatic.com"
          crossOrigin="anonymous"
        />
        <link rel="preconnect" href="https://xagent.icu" />
        <link rel="dns-prefetch" href="https://xagent.icu" />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
      </head>
      <body
        className={`${syne.variable} ${outfit.variable} ${jetbrainsMono.variable} antialiased`}
      >
        <ScrollRevealInit />
        {children}
      </body>
    </html>
  );
}