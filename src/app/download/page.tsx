import type { Metadata } from "next";
import { Header } from "@/components/layout/Header";
import { Footer } from "@/components/layout/Footer";
import { DownloadClient } from "@/components/DownloadClient";

export const metadata: Metadata = {
  title: "Download",
  description:
    "Download the ClawICU rescue script. One command: curl -fsSL https://xagent.icu/rescue.sh | sh",
  alternates: {
    canonical: "/download/",
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
