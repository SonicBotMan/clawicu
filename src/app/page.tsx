import type { Metadata } from "next";
import { Header } from "@/components/layout/Header";
import { Footer } from "@/components/layout/Footer";
import { Hero } from "@/components/Hero";
import { PatientSymptoms } from "@/components/PatientSymptoms";
import { TrustSection } from "@/components/TrustSection";
import { ExaminationProcess } from "@/components/ExaminationProcess";
import { TreatmentPlan } from "@/components/TreatmentPlan";
import { QuickStartGuides } from "@/components/QuickStartGuides";
import { ContactCTA } from "@/components/ContactCTA";
import { CTASection } from "@/components/CTASection";

export const metadata: Metadata = {
  title: "ClawICU — OpenClaw Emergency Rescue System",
  description:
    "Fix broken OpenClaw in seconds. ClawICU runs 20 diagnostic checks and auto-repairs plugin crashes, gateway failures, version mismatches, config corruption, and more. Free & open-source.",
  alternates: {
    canonical: "https://xagent.icu/",
  },
  openGraph: {
    title: "ClawICU — OpenClaw Emergency Rescue System",
    description:
      "Fix broken OpenClaw in seconds. 20 checks, 6-phase rescue protocol, interactive auto-repair. One command: curl -fsSL https://xagent.icu/r | sh",
    url: "https://xagent.icu/",
    type: "website",
  },
};

export default function Home() {
  return (
    <>
      <Header />
      <main>
        <Hero />
        <PatientSymptoms />
        <TrustSection />
        <ExaminationProcess />
        <TreatmentPlan />
        <QuickStartGuides />
        <ContactCTA />
        <CTASection />
      </main>
      <Footer />
    </>
  );
}
