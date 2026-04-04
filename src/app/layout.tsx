import type { Metadata, Viewport } from "next";
import { Syne, Outfit, JetBrains_Mono } from "next/font/google";
import { ScrollRevealInit } from "@/components/effects/ScrollRevealInit";
import "./globals.css";

const syne = Syne({
  subsets: ["latin"],
  variable: "--font-clash-display",
  weight: ["400", "500", "600", "700", "800"],
});

const outfit = Outfit({
  subsets: ["latin"],
  variable: "--font-satoshi",
  weight: ["300", "400", "500", "600", "700"],
});

const jetbrainsMono = JetBrains_Mono({
  subsets: ["latin"],
  variable: "--font-mono",
  weight: ["400", "500", "600"],
});

export const viewport: Viewport = {
  themeColor: "#050810",
  width: "device-width",
  initialScale: 1,
};

export const metadata: Metadata = {
  title: {
    default: "ClawICU — OpenClaw Emergency Rescue",
    template: "%s | ClawICU",
  },
  description:
    "Open-source ICU monitoring and emergency rescue system for OpenClaw. Diagnose, treat, and revive critical systems in real-time with one command.",
  keywords: [
    "OpenClaw",
    "ClawICU",
    "emergency rescue",
    "system recovery",
    "diagnostics",
    "DevOps",
    "OpenClaw gateway",
    "configuration repair",
    "daemon management",
  ],
  authors: [{ name: "ClawICU Team", url: "https://github.com/SonicBotMan/clawicu" }],
  creator: "ClawICU Team",
  openGraph: {
    type: "website",
    locale: "en_US",
    url: "https://xagent.icu",
    siteName: "ClawICU",
    title: "ClawICU — OpenClaw Emergency Rescue",
    description:
      "Diagnose, treat, and revive your OpenClaw instance with one command. Supports npm, Docker, Podman, and source installations.",
  },
  twitter: {
    card: "summary_large_image",
    title: "ClawICU — OpenClaw Emergency Rescue",
    description:
      "One command to diagnose, repair, and revive your OpenClaw instance.",
    creator: "@clawicu",
  },
  icons: {
    icon: "/favicon.svg",
    shortcut: "/favicon.svg",
    apple: "/favicon.svg",
  },
  metadataBase: new URL("https://xagent.icu"),
  alternates: {
    canonical: "/",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <body
        className={`${syne.variable} ${outfit.variable} ${jetbrainsMono.variable} antialiased`}
      >
        <ScrollRevealInit />
        {children}
      </body>
    </html>
  );
}
