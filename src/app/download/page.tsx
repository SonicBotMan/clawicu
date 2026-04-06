import type { Metadata } from "next";
import { Header } from "@/components/layout/Header";
import { Footer } from "@/components/layout/Footer";
import { DownloadClient } from "@/components/DownloadClient";

export const metadata: Metadata = {
  title: "Download ClawICU — OpenClaw Rescue Script",
  description:
    "Download the ClawICU rescue script v0.2.0 for OpenClaw. One command: curl -fsSL https://xagent.icu/r | sh — supports macOS and Linux, zero dependencies beyond curl.",
  alternates: {
    canonical: "/download/",
  },
  openGraph: {
    title: "Download ClawICU — OpenClaw Rescue Script",
    description:
      "Free, open-source rescue script for OpenClaw. curl -fsSL https://xagent.icu/r | sh",
    type: "website",
  },
};

export default function DownloadPage() {
  return (
    <>
      <Header />
      <main>
        <DownloadClient />
      </main>
      <Footer />
    </>
  );
}
