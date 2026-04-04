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
    "Rescue system for OpenClaw. Diagnose pairing failures, channel auth errors, cron not running, and other common issues. One command: curl -fsSL https://xagent.icu/rescue.sh | sh",
  keywords: [
    "OpenClaw",
    "ClawICU",
    "emergency rescue",
    "diagnostics",
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
        url: "/og-image.png",
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
      "One command to diagnose and fix your OpenClaw instance.",
    creator: "@clawicu",
    images: ["/og-image.png"],
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
      },
      sameAs: ["https://github.com/SonicBotMan/clawicu"],
    },
    {
      "@type": "WebSite",
      "@id": "https://xagent.icu/#website",
      url: "https://xagent.icu",
      name: "ClawICU",
      publisher: { "@id": "https://xagent.icu/#organization" },
      description: "Rescue system for OpenClaw",
      inLanguage: "en-US",
      potentialAction: {
        "@type": "SearchAction",
        target: {
          "@type": "EntryPoint",
          urlTemplate: "https://xagent.icu/docs?q={search_term_string}",
        },
        "query-input": "required name=search_term_string",
      },
    },
    {
      "@type": "WebPage",
      "@id": "https://xagent.icu/#webpage",
      url: "https://xagent.icu",
      name: "ClawICU — OpenClaw Emergency Rescue",
      about: { "@id": "https://xagent.icu/#organization" },
      isPartOf: { "@id": "https://xagent.icu/#website" },
      description:
        "Rescue system for OpenClaw. Diagnose and fix common issues with one command.",
      inLanguage: "en-US",
      datePublished: "2026-04-04",
      dateModified: "2026-04-04",
    },
    {
      "@type": "SoftwareApplication",
      "@id": "https://xagent.icu/#software",
      name: "ClawICU",
      url: "https://xagent.icu",
      description: "Emergency rescue system for OpenClaw",
      applicationCategory: "DeveloperApplication",
      operatingSystem: "Linux, macOS",
      offers: {
        "@type": "Offer",
        price: "0",
        priceCurrency: "USD",
      },
      publisher: { "@id": "https://xagent.icu/#organization" },
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